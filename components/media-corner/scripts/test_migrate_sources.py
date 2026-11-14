import json
from pathlib import Path
import tempfile
import unittest
from migrate_sources import migrate


class MigrationTest(unittest.TestCase):
    def test_preserves_and_is_idempotent(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "media-corner.json"
            raw = b'{"windowed":true,"sources":"[{\\"type\\":\\"web\\",\\"name\\":\\"A\\"}]"}'
            path.write_bytes(raw)
            self.assertEqual(migrate(path), {"status": "migrated", "count": 1})
            data = json.loads(path.read_text())
            self.assertTrue(data["windowed"])
            self.assertEqual(json.loads(data["sources"])["sources"][0]["name"], "A")
            backup = list(path.parent.glob("media-corner.json.pre-sources-*"))
            self.assertEqual(len(backup), 1)
            self.assertEqual(backup[0].read_bytes(), raw)
            self.assertEqual(backup[0].stat().st_mode & 0o777, 0o600)
            self.assertEqual(migrate(path)["status"], "current")
            self.assertEqual(len(list(path.parent.glob("media-corner.json.pre-sources-*"))), 1)

    def test_missing_sources_is_created(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "media-corner.json"
            path.write_text('{"windowed":true}')
            self.assertEqual(migrate(path), {"status": "migrated", "count": 0})
            data = json.loads(path.read_text())
            self.assertTrue(data["windowed"])
            self.assertEqual(json.loads(data["sources"])["sources"], [])

    def test_absent_file(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "inir" / "plugins" / "media-corner.json"
            self.assertEqual(migrate(path), {"status": "migrated", "count": 0})
            self.assertEqual(path.stat().st_mode & 0o777, 0o600)
            self.assertEqual(migrate(path)["status"], "current")

    def test_unknown_keeps_original(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "media-corner.json"
            raw = b'{"sources":"{\\"schemaVersion\\":9}"}'
            path.write_bytes(raw)
            with self.assertRaises(ValueError):
                migrate(path)
            self.assertEqual(path.read_bytes(), raw)
            self.assertEqual(list(path.parent.glob("media-corner.json.pre-sources-*")), [])


if __name__ == "__main__":
    unittest.main()

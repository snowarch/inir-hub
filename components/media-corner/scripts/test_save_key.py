import json
from pathlib import Path
import tempfile
import unittest
from save_key import save

class SaveKeyTest(unittest.TestCase):
    def test_private_and_preserves_options(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'media-corner.json'
            path.write_text('{"windowed":true,"sources":"[]"}')
            path.chmod(0o644)
            save(path, 'fixture-key')
            data = json.loads(path.read_text())
            self.assertTrue(data['windowed'])
            self.assertEqual(data['sources'], '[]')
            self.assertEqual(data['subtitleApiKey'], 'fixture-key')
            self.assertEqual(path.stat().st_mode & 0o777, 0o600)

if __name__ == '__main__':
    unittest.main()

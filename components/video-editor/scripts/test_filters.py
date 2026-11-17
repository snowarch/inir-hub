#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Validation, URL handling and atomic publication without external programs."""
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
from video_probe import BackendError, fraction, local_path
from video_recorder import recording_path
from video_filters import crop_dimensions, normalize_spec, output_dimensions, selected_range
from video_export import output_path_for, publish


class FilterTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='video-editor-test-')
        self.addCleanup(self.temporary.cleanup)
        self.source = Path(self.temporary.name) / "clip ' ação # $(name).mp4"
        self.source.write_bytes(b'original')
        self.metadata = {'duration': 8, 'video': {'width': 640, 'height': 480}}

    def spec(self, **values):
        return normalize_spec(dict(input=str(self.source), **values))

    def test_local_file_urls_round_trip(self):
        self.assertEqual(local_path(self.source.as_uri()), self.source)
        self.assertEqual(local_path(str(self.source)), self.source)
        self.assertEqual(local_path(self.source.as_uri().replace('file:///', 'file://localhost/')), self.source)
        for value in ['https://example.invalid/clip.mp4', 'file://server/clip.mp4', '', None, '\0']:
            with self.subTest(value=value), self.assertRaises(BackendError):
                local_path(value)

    def test_fraction_and_nonfinite_numbers(self):
        self.assertAlmostEqual(fraction('30000/1001'), 29.97002997)
        self.assertEqual(fraction('0/0'), 0)
        spec = self.spec(playbackRate=float('nan'), startSeconds=float('inf'))
        self.assertEqual(spec['playbackRate'], 1)
        self.assertEqual(spec['startSeconds'], 0)

    def test_crop_scales_before_rotation(self):
        spec = self.spec(crop={'x': 0.25, 'y': 0.25, 'w': 0.5, 'h': 0.5}, rotation=90)
        self.assertEqual(crop_dimensions(spec, self.metadata), (160, 120, 320, 240))
        self.assertEqual(output_dimensions(spec, self.metadata), (240, 320))
        spec['format'], spec['gifScale'] = 'gif', 0.5
        self.assertEqual(output_dimensions(spec, self.metadata), (120, 160))

    def test_bad_specs_and_empty_trim(self):
        for values in [{'format': 'webm'}, {'rotation': 45}, {'crop': [1]}]:
            with self.subTest(values=values), self.assertRaises(BackendError):
                self.spec(**values)
        with self.assertRaises(BackendError):
            selected_range(self.spec(startSeconds=4, endSeconds=3), self.metadata)
        with self.assertRaises(BackendError):
            crop_dimensions(self.spec(crop={'w': 1, 'h': 1, 'uiW': 0}), self.metadata)

    def test_numbered_exports_never_select_existing_copy(self):
        first, replaces = output_path_for(self.spec())
        first.write_bytes(b'earlier export')
        second, _ = output_path_for(self.spec())
        self.assertNotEqual(first, second)
        self.assertFalse(replaces)
        self.assertEqual(output_path_for(self.spec(replaceOriginal=True)), (self.source, True))
        gif, replaces = output_path_for(self.spec(replaceOriginal=True, format='gif'))
        self.assertNotEqual(gif, self.source)
        self.assertFalse(replaces)

    def test_atomic_publication_refuses_clobber(self):
        temporary = self.source.with_suffix('.tmp')
        temporary.write_bytes(b'new')
        with self.assertRaises(BackendError) as failure:
            publish(temporary, self.source)
        self.assertEqual(failure.exception.code, 'output_exists')
        self.assertEqual(self.source.read_bytes(), b'original')
        publish(temporary, self.source, replace=True)
        self.assertEqual(self.source.read_bytes(), b'new')
        self.assertFalse(temporary.exists())

    def test_recorder_output_arguments_and_missing_process(self):
        proc = self.source.parent
        process = proc / '42'
        process.mkdir()
        (process / 'stat').write_text('42 (wf-recorder) S ' + '0 ' * 18 + '100')
        (process / 'comm').write_text('wf-recorder\n')
        (process / 'cwd').symlink_to(proc)
        for arguments, expected in [
            ([b'wf-recorder', b'-f', "clip ' ação #.mp4".encode()], proc / "clip ' ação #.mp4"),
            ([b'wf-recorder', b'--file=/tmp/absolute.mp4'], Path('/tmp/absolute.mp4')),
            ([b'wf-recorder', b'--file', b'relative.mp4'], proc / 'relative.mp4'),
        ]:
            (process / 'cmdline').write_bytes(b'\0'.join(arguments) + b'\0')
            stat = (process / 'stat').read_text()
            with patch.object(Path, 'read_text', side_effect=[stat, 'wf-recorder', stat.replace('S 0 ', 'S 20 ', 1)]):
                self.assertEqual(recording_path(42, proc)['path'], str(expected))
        (process / 'comm').write_text('unrelated\n')
        self.assertEqual(recording_path(42, proc)['path'], '')
        self.assertEqual(recording_path(999, proc)['path'], '')
        self.assertEqual(recording_path(0, proc)['path'], '')

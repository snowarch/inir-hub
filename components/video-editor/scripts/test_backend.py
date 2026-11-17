#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Exercise the JSON worker with real, temporary FFmpeg media fixtures."""
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
from video_probe import BackendError, Cancelled, Runner
from video_filters import normalize_spec
from video_export import export_video

WORKER = Path(__file__).with_name('video_backend.py')


@unittest.skipUnless(shutil.which('ffmpeg') and shutil.which('ffprobe'), 'FFmpeg is required')
class BackendTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temporary = tempfile.TemporaryDirectory(prefix='video-editor-media-')
        cls.addClassCleanup(cls.temporary.cleanup)
        cls.directory = Path(cls.temporary.name)
        cls.source = cls.directory / "clip ' ação # $(name).mp4"
        cls.silent = cls.directory / 'silent.mp4'
        subprocess.run(['ffmpeg', '-v', 'error', '-f', 'lavfi', '-i', 'testsrc2=size=160x120:rate=12',
                        '-f', 'lavfi', '-i', 'sine=frequency=440:sample_rate=44100', '-t', '3',
                        '-c:v', 'libx264', '-threads', '1', '-c:a', 'aac', str(cls.source)], check=True)
        subprocess.run(['ffmpeg', '-v', 'error', '-i', str(cls.source), '-c:v', 'copy', '-an',
                        str(cls.silent)], check=True)

    def worker(self, operation, **values):
        payload = dict({'input': str(self.source), 'requestId': 'test-42'}, **values)
        result = subprocess.run([sys.executable, str(WORKER), operation, json.dumps(payload)],
                                env=dict(os.environ, XDG_CACHE_HOME=str(self.directory / 'cache')),
                                capture_output=True, text=True, timeout=45)
        messages = [json.loads(line) for line in result.stdout.splitlines()]
        self.assertTrue(messages, result.stderr)
        self.assertTrue(all(m['requestId'] == 'test-42' for m in messages))
        return result, messages

    def metadata(self, output):
        result = subprocess.run(['ffprobe', '-v', 'error', '-show_streams', '-show_format',
                                 '-of', 'json', str(output)], capture_output=True, text=True, check=True)
        return json.loads(result.stdout)

    def test_probe_and_thumbnails(self):
        result, messages = self.worker('probe', input=self.source.as_uri())
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(messages[-1]['path'], str(self.source))
        self.assertTrue(messages[-1]['audio']['present'])
        result, messages = self.worker('thumbnails')
        self.assertEqual(result.returncode, 0, result.stderr)
        images = [m for m in messages if m['event'] == 'thumbnail']
        self.assertEqual(len(images), 8)
        self.assertTrue(all(Path(m['path']).stat().st_size > 0 for m in images))

    def test_mp4_transform_trim_mute_and_speed(self):
        result, messages = self.worker('export', crop={'x': 0.25, 'y': 0.25, 'w': 0.5, 'h': 0.5},
                                      rotation=90, flipHorizontal=True, flipVertical=True,
                                      startSeconds=0.5, endSeconds=2.5, playbackRate=2, mute=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(messages[-1]['event'], 'finished')
        data = self.metadata(messages[-1]['outputPath'])
        video = next(s for s in data['streams'] if s['codec_type'] == 'video')
        self.assertEqual((video['width'], video['height']), (60, 80))
        self.assertFalse(any(s['codec_type'] == 'audio' for s in data['streams']))
        self.assertAlmostEqual(float(data['format']['duration']), 1, delta=0.2)
        self.assertTrue(any(m['event'] == 'progress' for m in messages))

    def test_slow_speed_keeps_audio_in_sync(self):
        result, messages = self.worker('export', startSeconds=0.5, endSeconds=1.5, playbackRate=0.25)
        self.assertEqual(result.returncode, 0, result.stderr)
        data = self.metadata(messages[-1]['outputPath'])
        tracks = {s['codec_type']: float(s['duration']) for s in data['streams']}
        self.assertAlmostEqual(tracks['video'], 4, delta=0.3)
        self.assertAlmostEqual(tracks['audio'], tracks['video'], delta=0.4)

    def test_gif_and_mp3_exports(self):
        for fmt in ['gif', 'mp3']:
            with self.subTest(format=fmt):
                result, messages = self.worker('export', format=fmt, startSeconds=0.5, endSeconds=1.5)
                self.assertEqual(result.returncode, 0, result.stderr)
                data = self.metadata(messages[-1]['outputPath'])
                self.assertEqual(data['streams'][0]['codec_name'], fmt)
                self.assertAlmostEqual(float(data['format']['duration']), 1, delta=0.2)
                if fmt == 'gif':
                    self.assertEqual((data['streams'][0]['width'], data['streams'][0]['height']), (80, 60))

    def test_no_audio_and_failed_replacement_preserve_input(self):
        before = self.silent.read_bytes()
        result, messages = self.worker('export', input=str(self.silent), format='mp3')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(messages[-1]['code'], 'no_audio')
        result, messages = self.worker('export', input=str(self.silent), replaceOriginal=True,
                                      startSeconds=2, endSeconds=1)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.silent.read_bytes(), before)
        self.assertFalse(list(self.directory.glob('.video-editor-*')))

    def test_estimate_snapshots_and_no_clobbering(self):
        result, messages = self.worker('estimate', format='mp4')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertGreater(messages[-1]['estimatedSize'], 0)
        result, messages = self.worker('estimate', format='mp3')
        self.assertEqual(messages[-1]['estimatedSize'], 72000)
        paths = []
        for _ in range(2):
            result, messages = self.worker('snapshot', positionSeconds=1, outputDir=str(self.directory / 'Pictures'))
            self.assertEqual(result.returncode, 0, result.stderr)
            paths.append(Path(messages[-1]['path']))
        self.assertNotEqual(*paths)
        self.assertTrue(all(p.stat().st_size > 0 for p in paths))

    def test_source_change_or_cancel_before_publication(self):
        source = self.directory / 'replace.mp4'
        shutil.copyfile(self.source, source)
        spec = normalize_spec({'input': str(source), 'replaceOriginal': True})
        runner = Runner(lambda _: None)
        changed = b'user replaced source'
        def change(command, duration):
            Path(command[-1]).write_bytes(b'encoded')
            source.write_bytes(changed)
        with patch.object(runner, 'render', side_effect=change), self.assertRaises(BackendError) as failure:
            export_video(spec, runner)
        self.assertEqual(failure.exception.code, 'input_changed')
        self.assertEqual(source.read_bytes(), changed)
        shutil.copyfile(self.source, source)
        before = source.read_bytes()
        with patch.object(runner, 'render', side_effect=Cancelled), self.assertRaises(Cancelled):
            export_video(spec, runner)
        self.assertEqual(source.read_bytes(), before)
        self.assertFalse(list(self.directory.glob('.video-editor-*')))

    def test_invalid_json_and_missing_program(self):
        result = subprocess.run([sys.executable, str(WORKER), 'probe', '{'], capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(json.loads(result.stdout)['ok'])
        result = subprocess.run([sys.executable, str(WORKER), 'probe', json.dumps({'input': str(self.source)})],
                                env=dict(os.environ, PATH=''), capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(json.loads(result.stdout)['code'], 'missing_dependency')


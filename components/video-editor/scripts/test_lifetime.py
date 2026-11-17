#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Deterministic TERM and parent-death tests around a real FFmpeg export."""
import json
import os
import shutil
import signal
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path

WORKER = Path(__file__).with_name('video_backend.py')


def running(pid):
    try:
        # A reparented zombie has exited and cannot keep encoding.
        return Path(f'/proc/{pid}/stat').read_text().split(') ')[1][0] != 'Z'
    except FileNotFoundError:
        return False


def wait_until(predicate, timeout=6):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if predicate():
            return True
        time.sleep(0.02)
    return False


@unittest.skipUnless(sys.platform == 'linux' and shutil.which('ffmpeg') and shutil.which('ffprobe'),
                     'Linux and FFmpeg are required')
class LifetimeTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='video-editor-lifetime-')
        self.addCleanup(self.temporary.cleanup)
        self.directory = Path(self.temporary.name)
        self.source = self.directory / 'source.mp4'
        self.pidfile = self.directory / 'encoder.pid'
        real = shutil.which('ffmpeg')
        subprocess.run([real, '-v', 'error', '-f', 'lavfi', '-i', 'testsrc2=size=160x120:rate=12',
                        '-t', '3', '-c:v', 'libx264', '-threads', '1', str(self.source)], check=True)
        self.before = self.source.read_bytes()
        binpath = self.directory / 'bin'
        binpath.mkdir()
        # Throttle a real encoder in the test, so cancellation cannot lose a race
        # against an export that completes in milliseconds on fast machines.
        wrapper = binpath / 'ffmpeg'
        wrapper.write_text('#!' + sys.executable + '\nimport os,sys\nfrom pathlib import Path\n'
                           + f'Path({str(self.pidfile)!r}).write_text(str(os.getpid()))\n'
                           + 'args=sys.argv[1:]\nargs.insert(args.index("-i"),"-re")\n'
                           + f'os.execv({real!r},[{real!r}]+args)\n')
        wrapper.chmod(0o755)
        self.environment = dict(os.environ, PATH=str(binpath) + os.pathsep + os.environ.get('PATH', ''),
                                XDG_CACHE_HOME=str(self.directory / 'cache'))
        self.worker = None
        self.encoder = None
        self.addCleanup(self.stop_workers)

    def stop_workers(self):
        if self.worker and self.worker.poll() is None:
            self.worker.kill()
            self.worker.wait(timeout=5)
        if self.encoder and running(self.encoder):
            os.kill(self.encoder, signal.SIGKILL)

    def start_worker(self):
        payload = {'input': str(self.source), 'replaceOriginal': True, 'requestId': 'cancel-1'}
        self.worker = subprocess.Popen([sys.executable, str(WORKER), 'export', json.dumps(payload)],
                                       env=self.environment, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        self.assertTrue(wait_until(self.pidfile.exists), 'FFmpeg did not start')
        self.encoder = int(self.pidfile.read_text())
        self.assertTrue(running(self.encoder))

    def test_term_reaps_encoder_cleans_temporary_and_preserves_input(self):
        self.start_worker()
        self.worker.send_signal(signal.SIGTERM)
        stdout, stderr = self.worker.communicate(timeout=6)
        self.assertEqual(self.worker.returncode, 130, stderr)
        self.assertEqual(json.loads(stdout.splitlines()[-1])['event'], 'cancelled')
        self.assertTrue(wait_until(lambda: not running(self.encoder)))
        self.assertEqual(self.source.read_bytes(), self.before)
        self.assertFalse(list(self.directory.glob('.video-editor-*')))

    def test_forced_worker_death_stops_encoder(self):
        self.start_worker()
        self.worker.kill()
        self.worker.communicate(timeout=5)
        self.assertTrue(wait_until(lambda: not running(self.encoder)))
        self.assertEqual(self.source.read_bytes(), self.before)
        # SIGKILL cannot run finally cleanup; an unpublished temporary may remain.
        self.assertFalse(list(self.directory.glob('*_edited*.mp4')))


from __future__ import annotations

import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
HELPER = ROOT / "packages/opencode/disable-code-splitting.sh"


@unittest.skipUnless(shutil.which("bash") and shutil.which("sed") and shutil.which("grep"),
                     "bash, sed and grep are required")
class OpenCodeBuildWorkaroundTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.path = Path(self.temp.name) / "build script.ts"
        self.original = (
            b'await Bun.build({\n  format: "esm",\n  minify: true,\n'
            b'  splitting: true,\n  compile: { autoloadBunfig: false },\n})\n'
        )
        self.path.write_bytes(self.original)

    def run_helper(self, *paths: Path) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["bash", str(HELPER), *map(str, paths)],
            capture_output=True, text=True, check=False, timeout=5,
        )

    def test_changes_only_splitting_and_accepts_path_with_spaces(self) -> None:
        result = self.run_helper(self.path)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.path.read_bytes(),
                         self.original.replace(b"splitting: true,", b"splitting: false,"))

    def test_already_patched_is_byte_inode_and_mtime_preserving(self) -> None:
        self.path.write_bytes(self.original.replace(b"splitting: true,", b"splitting: false,"))
        before = self.path.read_bytes(), self.path.stat()
        result = self.run_helper(self.path)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.path.read_bytes(), before[0])
        self.assertEqual(self.path.stat().st_ino, before[1].st_ino)
        self.assertEqual(self.path.stat().st_mtime_ns, before[1].st_mtime_ns)

    def test_second_application_is_idempotent(self) -> None:
        self.assertEqual(self.run_helper(self.path).returncode, 0)
        before = self.path.read_bytes(), self.path.stat().st_mtime_ns
        self.assertEqual(self.run_helper(self.path).returncode, 0)
        self.assertEqual((self.path.read_bytes(), self.path.stat().st_mtime_ns), before)

    def test_missing_or_changed_property_fails_without_writing(self) -> None:
        for content in (b"await Bun.build({})\n", b"splitting: enabled,\n",
                        b"splitting: true, // changed upstream shape\n"):
            with self.subTest(content=content):
                self.path.write_bytes(content)
                before = self.path.stat().st_mtime_ns
                result = self.run_helper(self.path)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(self.path.read_bytes(), content)
                self.assertEqual(self.path.stat().st_mtime_ns, before)

    def test_multiple_properties_fail_without_writing(self) -> None:
        content = self.original + b"splitting: false,\n"
        self.path.write_bytes(content)
        self.assertNotEqual(self.run_helper(self.path).returncode, 0)
        self.assertEqual(self.path.read_bytes(), content)

    def test_missing_file_and_wrong_argument_count_fail(self) -> None:
        for paths in ((), (self.path, self.path), (self.path.parent / "missing.ts",)):
            with self.subTest(paths=paths):
                self.assertNotEqual(self.run_helper(*paths).returncode, 0)
        self.assertEqual(self.path.read_bytes(), self.original)

    @unittest.skipUnless(os.name == "posix", "symlink test requires POSIX")
    def test_symlink_is_rejected_without_touching_target(self) -> None:
        link = self.path.parent / "link.ts"
        link.symlink_to(self.path)
        self.assertNotEqual(self.run_helper(link).returncode, 0)
        self.assertEqual(self.path.read_bytes(), self.original)

    def test_whitespace_and_mode_are_preserved(self) -> None:
        self.path.write_bytes(b"\tsplitting: true, \t\n")
        self.path.chmod(0o640)
        self.assertEqual(self.run_helper(self.path).returncode, 0)
        self.assertEqual(self.path.read_bytes(), b"\tsplitting: false, \t\n")
        self.assertEqual(self.path.stat().st_mode & 0o777, 0o640)


if __name__ == "__main__":
    unittest.main()

from __future__ import annotations

import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LEGACY_IDENTITIES = (
    "OpenCode" + "Policy",
    "opencode" + "Policy",
    "opencode" + "-policy",
    "opencode" + "_policy",
    "github:upiscium/" + "OpenCode" + "Policy",
)


class OpencodeContractIdentityTest(unittest.TestCase):
    def test_source_tree_contains_no_legacy_consumer_identity(self) -> None:
        result = subprocess.run(
            [
                "git",
                "ls-files",
                "--cached",
                "--others",
                "--exclude-standard",
                "-z",
            ],
            cwd=ROOT,
            check=True,
            capture_output=True,
        )
        matches: list[str] = []
        for raw_path in result.stdout.split(b"\0"):
            if not raw_path:
                continue
            relative_path = raw_path.decode("utf-8")
            path = ROOT / relative_path
            if not path.exists():
                continue
            for identity in LEGACY_IDENTITIES:
                if identity in relative_path:
                    matches.append(f"{relative_path}: path contains {identity}")
            try:
                lines = path.read_text(encoding="utf-8").splitlines()
            except (OSError, UnicodeDecodeError):
                continue
            for line_number, line in enumerate(lines, start=1):
                for identity in LEGACY_IDENTITIES:
                    if identity in line:
                        matches.append(
                            f"{relative_path}:{line_number}: contains {identity}"
                        )
        self.assertEqual([], matches, "\n".join(matches))


if __name__ == "__main__":
    unittest.main()

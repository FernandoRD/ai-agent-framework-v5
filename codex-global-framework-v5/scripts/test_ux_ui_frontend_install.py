#!/usr/bin/env python3
"""Exercise optional UX/UI skill selection in the supported local installers."""
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
NAME = "ux-ui-frontend-specialist"
SOURCE = ROOT / "optional" / NAME / ".agents" / "skills" / NAME / "SKILL.md"


class InstallTests(unittest.TestCase):
    def test_selection(self):
        installers = [("bash", ROOT / "scripts" / "install.sh")]
        if shutil.which("pwsh"):
            installers.append(("pwsh", ROOT / "scripts" / "install.ps1"))
        for shell, installer in installers:
            for mode in ("default", "individual", "all"):
                for target in ("project", "global"):
                    with self.subTest(shell=shell, mode=mode, target=target), tempfile.TemporaryDirectory() as tmp:
                        base = Path(tmp)
                        project = base / "project"
                        project.mkdir()
                        if shell == "bash":
                            args = [shell, str(installer), "--no-hook"]
                            args += ["--target", str(project)] if target == "project" else ["--global", "--codex-home", str(base / "codex"), "--skills-home", str(base / "skills")]
                            args += {"default": [], "individual": ["--with-ux-ui-frontend-specialist"], "all": ["--with-all-specialists"]}[mode]
                        else:
                            args = [shell, "-NoProfile", "-File", str(installer), "-NoHook"]
                            args += ["-Target", str(project)] if target == "project" else ["-Global", "-CodexHome", str(base / "codex"), "-SkillsHome", str(base / "skills")]
                            args += {"default": [], "individual": ["-WithUxUiFrontendSpecialist"], "all": ["-WithAllSpecialists"]}[mode]
                        result = subprocess.run(args, capture_output=True, text=True)
                        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                        installed = (project / ".agents" / "skills" if target == "project" else base / "skills") / NAME / "SKILL.md"
                        if mode == "default":
                            self.assertFalse(installed.exists())
                        else:
                            self.assertEqual(installed.read_bytes(), SOURCE.read_bytes())

    def test_conflicting_skill_is_not_overwritten(self):
        installers = [("bash", ROOT / "scripts" / "install.sh")]
        if shutil.which("pwsh"):
            installers.append(("pwsh", ROOT / "scripts" / "install.ps1"))
        for shell, installer in installers:
            with self.subTest(shell=shell), tempfile.TemporaryDirectory() as tmp:
                project = Path(tmp) / "project"
                existing = project / ".agents" / "skills" / NAME / "SKILL.md"
                existing.parent.mkdir(parents=True)
                existing.write_text("personal skill", encoding="utf-8")
                if shell == "bash":
                    args = [shell, str(installer), "--target", str(project), "--with-ux-ui-frontend-specialist"]
                else:
                    args = [shell, "-NoProfile", "-File", str(installer), "-Target", str(project), "-WithUxUiFrontendSpecialist"]
                result = subprocess.run(args, capture_output=True, text=True)
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertEqual(existing.read_text(encoding="utf-8"), "personal skill")

    @unittest.skipUnless(shutil.which("pwsh") and os.name == "posix", "requires PowerShell and a POSIX executable stub")
    def test_wsl_forwards_selection(self):
        for switch in ("-WithUxUiFrontendSpecialist", "-WithAllSpecialists"):
            with self.subTest(switch=switch), tempfile.TemporaryDirectory() as tmp:
                base = Path(tmp)
                stub = base / "wsl.exe"
                stub.write_text('#!/bin/sh\ncase "$*" in *wslpath*) echo /tmp/package ;; *) printf "%s" "$*" > "$WSL_TEST_OUTPUT" ;; esac\n')
                stub.chmod(0o755)
                output = base / "args"
                env = os.environ.copy()
                env["PATH"] = str(base) + os.pathsep + env["PATH"]
                env["WSL_TEST_OUTPUT"] = str(output)
                result = subprocess.run(["pwsh", "-NoProfile", "-File", str(ROOT / "scripts" / "install-wsl.ps1"), "-Distro", "test", switch], capture_output=True, text=True, env=env)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                command = output.read_text()
                self.assertIn("--with-ux-ui-frontend-specialist", command)
                if switch == "-WithAllSpecialists":
                    self.assertEqual(command.count(" --with-"), 10)


if __name__ == "__main__":
    unittest.main()

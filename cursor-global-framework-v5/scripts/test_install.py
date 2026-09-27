"""Offline installer regression checks. Run with Python 3.10+."""
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).with_name('install.sh').resolve()
PAYLOAD = SCRIPT.parents[1] / 'payload'
OPTIONAL_PAYLOAD = SCRIPT.parents[1] / 'optional' / 'zabbix-specialist' / 'payload'
GRAFANA_PAYLOAD = SCRIPT.parents[1] / 'optional' / 'grafana-specialist' / 'payload'


class InstallerTests(unittest.TestCase):
    def test_zabbix_specialist_is_opt_in(self):
        with tempfile.TemporaryDirectory() as temporary:
            target = Path(temporary) / 'project'
            base = subprocess.run(['bash', str(SCRIPT), '--target', str(target), '--apply'], capture_output=True, text=True)
            self.assertEqual(base.returncode, 0)
            specialist = target / '.cursor' / 'skills' / 'zabbix-specialist' / 'SKILL.md'
            native_agent = target / '.cursor' / 'agents' / 'zabbix-specialist.md'
            self.assertFalse(specialist.exists())
            audit = subprocess.run(['bash', str(SCRIPT), '--target', str(target), '--with-zabbix-specialist'], capture_output=True, text=True)
            self.assertEqual(audit.returncode, 0)
            self.assertFalse(specialist.exists(), 'optional audit must not write')
            install = subprocess.run(['bash', str(SCRIPT), '--target', str(target), '--with-zabbix-specialist', '--apply'], capture_output=True, text=True)
            self.assertEqual(install.returncode, 0)
            self.assertEqual(specialist.read_bytes(), (OPTIONAL_PAYLOAD / '.cursor' / 'skills' / 'zabbix-specialist' / 'SKILL.md').read_bytes())
            self.assertFalse(native_agent.exists(), 'specialist must not install a model-pinned native agent')

    def test_grafana_specialist_is_opt_in(self):
        with tempfile.TemporaryDirectory() as temporary:
            target = Path(temporary) / 'project'
            base = subprocess.run(['bash', str(SCRIPT), '--target', str(target), '--apply'], capture_output=True, text=True)
            self.assertEqual(base.returncode, 0)
            specialist = target / '.cursor' / 'skills' / 'grafana-specialist' / 'SKILL.md'
            native_agent = target / '.cursor' / 'agents' / 'grafana-specialist.md'
            self.assertFalse(specialist.exists())
            audit = subprocess.run(['bash', str(SCRIPT), '--target', str(target), '--with-grafana-specialist'], capture_output=True, text=True)
            self.assertEqual(audit.returncode, 0)
            self.assertFalse(specialist.exists(), 'optional audit must not write')
            install = subprocess.run(['bash', str(SCRIPT), '--target', str(target), '--with-grafana-specialist', '--apply'], capture_output=True, text=True)
            self.assertEqual(install.returncode, 0)
            self.assertEqual(specialist.read_bytes(), (GRAFANA_PAYLOAD / '.cursor' / 'skills' / 'grafana-specialist' / 'SKILL.md').read_bytes())
            self.assertFalse(native_agent.exists(), 'specialist must not install a model-pinned native agent')

    def test_with_all_specialists(self):
        with tempfile.TemporaryDirectory() as temporary:
            target = Path(temporary) / 'project_all'
            res = subprocess.run(['bash', str(SCRIPT), '--target', str(target), '--with-all-specialists', '--apply'], capture_output=True, text=True)
            self.assertEqual(res.returncode, 0)
            specs = [
                "zabbix-specialist", "grafana-specialist", "ansible-specialist",
                "loki-specialist", "prometheus-specialist", "netops-specialist",
                "sre-incident-specialist", "database-tuning-specialist"
            ]
            for s in specs:
                skill_file = target / '.cursor' / 'skills' / s / 'SKILL.md'
                self.assertTrue(skill_file.exists(), f"Skill {s} missing with --with-all-specialists")

    def test_install_preserves_existing_data(self):
        with tempfile.TemporaryDirectory() as temporary:
            target = Path(temporary) / 'project'

            def run(*extra):
                return subprocess.run(
                    ['bash', str(SCRIPT), '--target', str(target), *extra],
                    capture_output=True, text=True)

            self.assertEqual(run().returncode, 0)
            self.assertFalse(target.exists(), 'Audit must not create the target')
            self.assertEqual(run('--apply').returncode, 0)
            sources = [p for p in PAYLOAD.rglob('*') if p.is_file()]
            for source in sources:
                self.assertEqual((target / source.relative_to(PAYLOAD)).read_bytes(), source.read_bytes())
            self.assertEqual(run('--apply').returncode, 0)
            changed = target / sources[0].relative_to(PAYLOAD)
            changed.write_text('user content', encoding='utf-8')
            # A missing second file must not be created when preflight finds a conflict.
            missing = target / sources[1].relative_to(PAYLOAD)
            missing.unlink()
            self.assertEqual(run('--apply').returncode, 1)
            self.assertEqual(changed.read_text(encoding='utf-8'), 'user content')
            self.assertFalse(missing.exists())

    def test_global_install(self):
        with tempfile.TemporaryDirectory() as temporary:
            target = Path(temporary) / 'fake_home'
            res = subprocess.run(
                ['bash', str(SCRIPT), '--target', str(target), '--global', '--apply'],
                capture_output=True, text=True)
            self.assertEqual(res.returncode, 0)
            for p in PAYLOAD.glob('*.md'):
                self.assertFalse((target / p.name).exists(), f"{p.name} must not be in root during global install")
            tool_dot_dir = None
            for item in PAYLOAD.iterdir():
                if item.is_dir() and item.name.startswith('.'):
                    tool_dot_dir = item.name
                    break
            if tool_dot_dir:
                for p in PAYLOAD.glob('*.md'):
                    self.assertTrue((target / tool_dot_dir / p.name).exists(), f"{p.name} missing inside {tool_dot_dir}")

    def test_rejects_link_target(self):
        with tempfile.TemporaryDirectory() as temporary:
            base = Path(temporary)
            outside = base / 'outside'
            outside.mkdir()
            link = base / 'link'
            try:
                link.symlink_to(outside, target_is_directory=True)
            except OSError:
                self.skipTest('Symlink creation unavailable on this host')
            result = subprocess.run(
                ['bash', str(SCRIPT), '--target', str(link), '--apply'],
                capture_output=True, text=True)
            self.assertEqual(result.returncode, 1)
            self.assertEqual(list(outside.iterdir()), [])

    def test_shell_scripts_exist(self):
        scripts_dir = SCRIPT.parent
        self.assertTrue((scripts_dir / 'install.sh').is_file(), 'install.sh missing')
        self.assertTrue((scripts_dir / 'install.fish').is_file(), 'install.fish missing')
        self.assertTrue((scripts_dir / 'install.ps1').is_file(), 'install.ps1 missing')

    def test_install_sh(self):
        sh_script = SCRIPT.with_name('install.sh')
        with tempfile.TemporaryDirectory() as temporary:
            target = Path(temporary) / 'project_sh'
            res_audit = subprocess.run(['bash', str(sh_script), str(target)], capture_output=True, text=True)
            self.assertEqual(res_audit.returncode, 0)
            self.assertFalse(target.exists())
            res_apply = subprocess.run(['bash', str(sh_script), '--target', str(target), '--apply'], capture_output=True, text=True)
            self.assertEqual(res_apply.returncode, 0)
            self.assertTrue(target.exists())

    def test_install_sh_global(self):
        sh_script = SCRIPT.with_name('install.sh')
        with tempfile.TemporaryDirectory() as temporary:
            target = Path(temporary) / 'global_sh'
            res = subprocess.run(['bash', str(sh_script), '--target', str(target), '--global', '--apply'], capture_output=True, text=True)
            self.assertEqual(res.returncode, 0)
            for p in PAYLOAD.glob('*.md'):
                self.assertFalse((target / p.name).exists())

    def test_install_fish(self):
        if not shutil.which('fish'):
            self.skipTest('fish shell not available on host')
        fish_script = SCRIPT.with_name('install.fish')
        with tempfile.TemporaryDirectory() as temporary:
            target = Path(temporary) / 'project_fish'
            res = subprocess.run(['fish', str(fish_script), str(target), '--apply'], capture_output=True, text=True)
            self.assertEqual(res.returncode, 0)
            self.assertTrue(target.exists())


if __name__ == '__main__':
    unittest.main()

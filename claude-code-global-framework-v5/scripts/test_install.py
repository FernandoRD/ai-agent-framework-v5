"""Offline installer regression checks. Run with Python 3.10+."""
from pathlib import Path
import os
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
            specialist = target / '.claude' / 'skills' / 'zabbix-specialist' / 'SKILL.md'
            native_agent = target / '.claude' / 'agents' / 'zabbix-specialist.md'
            self.assertFalse(specialist.exists())
            audit = subprocess.run(['bash', str(SCRIPT), '--target', str(target), '--with-zabbix-specialist'], capture_output=True, text=True)
            self.assertEqual(audit.returncode, 0)
            self.assertFalse(specialist.exists(), 'optional audit must not write')
            install = subprocess.run(['bash', str(SCRIPT), '--target', str(target), '--with-zabbix-specialist', '--apply'], capture_output=True, text=True)
            self.assertEqual(install.returncode, 0)
            self.assertEqual(specialist.read_bytes(), (OPTIONAL_PAYLOAD / '.claude' / 'skills' / 'zabbix-specialist' / 'SKILL.md').read_bytes())
            self.assertTrue(native_agent.exists(), 'specialist must install its native agent')
            self.assertIn('skills:\n', native_agent.read_text(encoding='utf-8'))

    def test_grafana_specialist_is_opt_in(self):
        with tempfile.TemporaryDirectory() as temporary:
            target = Path(temporary) / 'project'
            base = subprocess.run(['bash', str(SCRIPT), '--target', str(target), '--apply'], capture_output=True, text=True)
            self.assertEqual(base.returncode, 0)
            specialist = target / '.claude' / 'skills' / 'grafana-specialist' / 'SKILL.md'
            native_agent = target / '.claude' / 'agents' / 'grafana-specialist.md'
            self.assertFalse(specialist.exists())
            audit = subprocess.run(['bash', str(SCRIPT), '--target', str(target), '--with-grafana-specialist'], capture_output=True, text=True)
            self.assertEqual(audit.returncode, 0)
            self.assertFalse(specialist.exists(), 'optional audit must not write')
            install = subprocess.run(['bash', str(SCRIPT), '--target', str(target), '--with-grafana-specialist', '--apply'], capture_output=True, text=True)
            self.assertEqual(install.returncode, 0)
            self.assertEqual(specialist.read_bytes(), (GRAFANA_PAYLOAD / '.claude' / 'skills' / 'grafana-specialist' / 'SKILL.md').read_bytes())
            self.assertTrue(native_agent.exists(), 'specialist must install its native agent')
            self.assertIn('skills:\n', native_agent.read_text(encoding='utf-8'))

    def test_with_all_specialists(self):
        with tempfile.TemporaryDirectory() as temporary:
            target = Path(temporary) / 'project_all'
            res = subprocess.run(['bash', str(SCRIPT), '--target', str(target), '--with-all-specialists', '--apply'], capture_output=True, text=True)
            self.assertEqual(res.returncode, 0)
            specs = [
                "zabbix-specialist", "grafana-specialist", "ansible-specialist",
                "loki-specialist", "prometheus-specialist", "netops-specialist",
                "sre-incident-specialist", "database-tuning-specialist",
                "proxmox-specialist", "shell-python-specialist",
                "docker-kubernetes-specialist"
            ]
            for s in specs:
                skill_file = target / '.claude' / 'skills' / s / 'SKILL.md'
                self.assertTrue(skill_file.exists(), f"Skill {s} missing with --with-all-specialists")
                agent_file = target / '.claude' / 'agents' / f'{s}.md'
                self.assertTrue(agent_file.exists(), f"Agent {s} missing with --with-all-specialists")
                text = agent_file.read_text(encoding='utf-8')
                self.assertTrue(text.startswith('---\n'), f"Agent {s} lacks frontmatter")
                self.assertIn(f'name: {s}\n', text)
                self.assertIn(f'skills:\n  - {s}\n', text, f"Agent {s} must preload its skill")
                self.assertNotIn('bypassPermissions', text)

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

    def test_uninstall_removes_only_intact_files(self):
        with tempfile.TemporaryDirectory() as temporary:
            home = Path(temporary) / 'home'

            def run(*extra):
                return subprocess.run(
                    ['bash', str(SCRIPT), '--target', str(home), '--global', '--with-all-specialists', *extra],
                    capture_output=True, text=True)

            self.assertEqual(run('--apply').returncode, 0)
            modified = home / '.claude' / 'skills' / 'zabbix-specialist' / 'api.md'
            modified.write_text('user content', encoding='utf-8')
            foreign = home / '.claude' / 'agents' / 'user-agent.md'
            foreign.write_text('user agent', encoding='utf-8')
            installed_agent = home / '.claude' / 'agents' / 'zabbix-specialist.md'

            audit = run('--uninstall')
            self.assertEqual(audit.returncode, 0)
            self.assertTrue(installed_agent.exists(), 'uninstall audit must not delete')

            res = run('--uninstall', '--apply')
            self.assertEqual(res.returncode, 0)
            self.assertFalse(installed_agent.exists())
            self.assertFalse((home / '.claude' / 'CLAUDE.md').exists())
            self.assertFalse((home / '.claude' / 'knowledge').exists(), 'empty dirs must be pruned')
            self.assertEqual(modified.read_text(encoding='utf-8'), 'user content')
            self.assertEqual(foreign.read_text(encoding='utf-8'), 'user agent')

    def test_global_audit_writes_nothing(self):
        with tempfile.TemporaryDirectory() as temporary:
            target = Path(temporary) / 'new_home'
            for extra in ([], ['--uninstall']):
                res = subprocess.run(['bash', str(SCRIPT), '--global', '--target', str(target), *extra],
                                     capture_output=True, text=True)
                self.assertEqual(res.returncode, 0, res.stderr)
                self.assertFalse(target.exists(), 'global audit must not create the target')

    def test_global_rejects_link_target(self):
        with tempfile.TemporaryDirectory() as temporary:
            base = Path(temporary)
            outside = base / 'outside'
            outside.mkdir()
            link = base / 'link'
            try:
                link.symlink_to(outside, target_is_directory=True)
            except OSError:
                self.skipTest('Symlink creation unavailable on this host')
            for extra in ([], ['--apply'], ['--uninstall', '--apply']):
                res = subprocess.run(['bash', str(SCRIPT), '--global', '--target', str(link), *extra],
                                     capture_output=True, text=True)
                self.assertEqual(res.returncode, 1, extra)
                self.assertEqual(list(outside.iterdir()), [])

    def test_trailing_slash_and_home_target_are_global(self):
        with tempfile.TemporaryDirectory() as temporary:
            home = Path(temporary) / 'home'
            home.mkdir()
            env = {**os.environ, 'HOME': str(home)}
            for target in ('~/', str(home) + '/', '~'):
                res = subprocess.run(['bash', str(SCRIPT), '--target', target, '--apply'],
                                     capture_output=True, text=True, env=env)
                self.assertEqual(res.returncode, 0, res.stderr)
                self.assertTrue((home / '.claude' / 'CLAUDE.md').is_file(), target)
                self.assertFalse((home / 'CLAUDE.md').exists(), target)
                un = subprocess.run(['bash', str(SCRIPT), '--target', target, '--uninstall', '--apply'],
                                    capture_output=True, text=True, env=env)
                self.assertEqual(un.returncode, 0, un.stderr)
                self.assertTrue(home.is_dir())
                self.assertFalse((home / '.claude').exists(), 'empty dirs must be pruned')

    def test_target_requires_value(self):
        for args in (['--target'], ['--target', '--apply'], ['--target=']):
            res = subprocess.run(['bash', str(SCRIPT), *args], capture_output=True, text=True)
            self.assertEqual(res.returncode, 1, args)
            self.assertIn('--target exige um caminho', res.stderr, args)

    def test_target_is_normalized_lexically(self):
        with tempfile.TemporaryDirectory() as temporary:
            home = Path(temporary) / 'home'
            (home / 'sub').mkdir(parents=True)
            env = {**os.environ, 'HOME': str(home)}

            def apply(cwd, target):
                return subprocess.run(['bash', str(SCRIPT), '--target', target, '--apply'],
                                      capture_output=True, text=True, env=env, cwd=cwd)

            # '.' inside HOME and '..' from a subdirectory are the global target.
            for cwd, target in ((home, '.'), (home / 'sub', '..'), (home, 'sub/..'), (home, './/')):
                res = apply(cwd, target)
                self.assertEqual(res.returncode, 0, res.stderr)
                self.assertTrue((home / '.claude' / 'CLAUDE.md').is_file(), target)
                self.assertFalse((home / 'CLAUDE.md').exists(), target)
                shutil.rmtree(home / '.claude')
            # '.' in a subdirectory of HOME stays a project install.
            self.assertEqual(apply(home / 'sub', '.').returncode, 0)
            self.assertTrue((home / 'sub' / 'CLAUDE.md').is_file())
            # Only '~' and '~/...' are expanded; '~foo' is a literal relative name.
            self.assertEqual(apply(home / 'sub', '~foo').returncode, 0)
            self.assertTrue((home / 'sub' / '~foo' / 'CLAUDE.md').is_file())

    def test_root_is_refused(self):
        for target in ('/', '//', '/x/..'):
            res = subprocess.run(['bash', str(SCRIPT), '--target', target, '--apply'],
                                 capture_output=True, text=True)
            self.assertEqual(res.returncode, 1, target)
            self.assertIn('raiz', res.stderr)

    def test_apply_never_overwrites_file_created_after_preflight(self):
        # The shim runs as the first `cat` (after its destination was created)
        # and then creates every OTHER destination as a "user" file, so the
        # result does not depend on the order in which files are installed.
        with tempfile.TemporaryDirectory() as temporary:
            target = Path(temporary) / 'project'
            bin_dir = Path(temporary) / 'bin'
            bin_dir.mkdir()
            marker = Path(temporary) / 'done'
            dests = [target / p.relative_to(PAYLOAD) for p in PAYLOAD.rglob('*') if p.is_file()]
            lines = ''.join(f'[ -e "{d}" ] || {{ mkdir -p "{d.parent}"; echo user > "{d}"; }}\n' for d in dests)
            real_cat = shutil.which('cat')
            (bin_dir / 'cat').write_text(
                f'#!/bin/sh\nif [ ! -e "{marker}" ]; then : > "{marker}"\n{lines}fi\nexec "{real_cat}" "$@"\n',
                encoding='utf-8')
            (bin_dir / 'cat').chmod(0o755)
            env = {**os.environ, 'PATH': f'{bin_dir}:{os.environ["PATH"]}'}
            res = subprocess.run(['bash', str(SCRIPT), '--target', str(target), '--apply'],
                                 capture_output=True, text=True, env=env)
            self.assertEqual(res.returncode, 1, res.stdout + res.stderr)
            self.assertIn('nada foi sobrescrito', res.stderr)
            contents = [d.read_text(encoding='utf-8') for d in dests]
            self.assertEqual(contents.count('user\n'), len(dests) - 1, 'only the first destination may be written')

    def test_legacy_hashes_cover_payload_paths(self):
        legacy = SCRIPT.with_name('legacy-hashes.sha256')
        self.assertTrue(legacy.is_file())
        for line in legacy.read_text(encoding='utf-8').splitlines():
            if not line or line.startswith('#'):
                continue
            digest, rel = line.split('  ', 1)
            self.assertEqual(len(digest), 64)
            self.assertTrue('/payload/' in '/' + rel, rel)

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

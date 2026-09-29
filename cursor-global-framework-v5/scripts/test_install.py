"""Offline installer regression checks. Run with Python 3.10+."""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).with_name('install.sh').resolve()
PAYLOAD = SCRIPT.parents[1] / 'payload'
OPTIONAL_PAYLOAD = SCRIPT.parents[1] / 'optional' / 'zabbix-specialist' / 'payload'
GRAFANA_PAYLOAD = SCRIPT.parents[1] / 'optional' / 'grafana-specialist' / 'payload'
TOOL = next(p.name for p in PAYLOAD.iterdir() if p.is_dir() and p.name.startswith('.'))
SPECS = [
    'zabbix-specialist', 'grafana-specialist', 'ansible-specialist',
    'loki-specialist', 'prometheus-specialist', 'netops-specialist',
    'sre-incident-specialist', 'database-tuning-specialist', 'proxmox-specialist',
]


def run(*args, **kwargs):
    return subprocess.run(['bash', str(SCRIPT), *args], capture_output=True, text=True, **kwargs)


def global_dest(root, source):
    rel = source.relative_to(PAYLOAD)
    return root / (rel if rel.parts[0].startswith('.') else Path(TOOL) / rel)


class InstallerTests(unittest.TestCase):
    def test_zabbix_specialist_is_opt_in(self):
        with tempfile.TemporaryDirectory() as temporary:
            target = Path(temporary) / 'project'
            base = subprocess.run(['bash', str(SCRIPT), '--target', str(target), '--apply'], capture_output=True, text=True)
            self.assertEqual(base.returncode, 0)
            specialist = target / TOOL / 'skills' / 'zabbix-specialist' / 'SKILL.md'
            native_agent = target / TOOL / 'agents' / 'zabbix-specialist.md'
            self.assertFalse(specialist.exists())
            audit = subprocess.run(['bash', str(SCRIPT), '--target', str(target), '--with-zabbix-specialist'], capture_output=True, text=True)
            self.assertEqual(audit.returncode, 0)
            self.assertFalse(specialist.exists(), 'optional audit must not write')
            install = subprocess.run(['bash', str(SCRIPT), '--target', str(target), '--with-zabbix-specialist', '--apply'], capture_output=True, text=True)
            self.assertEqual(install.returncode, 0)
            self.assertEqual(specialist.read_bytes(), (OPTIONAL_PAYLOAD / TOOL / 'skills' / 'zabbix-specialist' / 'SKILL.md').read_bytes())
            self.assertFalse(native_agent.exists(), 'specialist must not install a model-pinned native agent')

    def test_grafana_specialist_is_opt_in(self):
        with tempfile.TemporaryDirectory() as temporary:
            target = Path(temporary) / 'project'
            base = subprocess.run(['bash', str(SCRIPT), '--target', str(target), '--apply'], capture_output=True, text=True)
            self.assertEqual(base.returncode, 0)
            specialist = target / TOOL / 'skills' / 'grafana-specialist' / 'SKILL.md'
            native_agent = target / TOOL / 'agents' / 'grafana-specialist.md'
            self.assertFalse(specialist.exists())
            audit = subprocess.run(['bash', str(SCRIPT), '--target', str(target), '--with-grafana-specialist'], capture_output=True, text=True)
            self.assertEqual(audit.returncode, 0)
            self.assertFalse(specialist.exists(), 'optional audit must not write')
            install = subprocess.run(['bash', str(SCRIPT), '--target', str(target), '--with-grafana-specialist', '--apply'], capture_output=True, text=True)
            self.assertEqual(install.returncode, 0)
            self.assertEqual(specialist.read_bytes(), (GRAFANA_PAYLOAD / TOOL / 'skills' / 'grafana-specialist' / 'SKILL.md').read_bytes())
            self.assertFalse(native_agent.exists(), 'specialist must not install a model-pinned native agent')

    def test_with_all_specialists(self):
        with tempfile.TemporaryDirectory() as temporary:
            target = Path(temporary) / 'project_all'
            res = subprocess.run(['bash', str(SCRIPT), '--target', str(target), '--with-all-specialists', '--apply'], capture_output=True, text=True)
            self.assertEqual(res.returncode, 0)
            specs = [
                "zabbix-specialist", "grafana-specialist", "ansible-specialist",
                "loki-specialist", "prometheus-specialist", "netops-specialist",
                "sre-incident-specialist", "database-tuning-specialist",
                "proxmox-specialist"
            ]
            for s in specs:
                skill_file = target / TOOL / 'skills' / s / 'SKILL.md'
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
            self.assertEqual(run('--target', str(target), '--global', '--apply').returncode, 0)
            sources = [p for p in PAYLOAD.rglob('*') if p.is_file()]
            self.assertTrue(sources)
            for source in sources:
                dest = global_dest(target, source)
                self.assertEqual(dest.read_bytes(), source.read_bytes(), f'{dest} missing or different')
            for p in PAYLOAD.glob('*.md'):
                self.assertFalse((target / p.name).exists(), f'{p.name} must not be in root')

    def test_global_audit_does_not_write(self):
        with tempfile.TemporaryDirectory() as temporary:
            target = Path(temporary) / 'not_created'
            res = run('--target', str(target), '--global')
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
            for extra in ([], ['--apply']):
                res = run('--target', str(link), '--global', *extra)
                self.assertEqual(res.returncode, 1)
            self.assertEqual(list(outside.iterdir()), [])

    def test_trailing_slash_and_home_target(self):
        with tempfile.TemporaryDirectory() as temporary:
            home = Path(temporary) / 'home'
            home.mkdir()
            env = {**os.environ, 'HOME': str(home)}
            self.assertEqual(run('--target', f'{home}/', '--apply', env=env).returncode, 0)
            for source in PAYLOAD.rglob('*'):
                if source.is_file():
                    self.assertEqual(global_dest(home, source).read_bytes(), source.read_bytes())
            project = Path(temporary) / 'proj'
            self.assertEqual(run('--target', f'{project}//', '--apply').returncode, 0)
            self.assertTrue(project.is_dir())

    def test_target_requires_value(self):
        with tempfile.TemporaryDirectory() as temporary:
            for args in (['--target'], ['--target', '--apply'], ['--target='], ['--target', '']):
                res = run(*args, cwd=temporary)
                self.assertEqual(res.returncode, 1, args)
                self.assertIn('--target exige um caminho', res.stderr, args)
            self.assertEqual(list(Path(temporary).iterdir()), [], '--apply must not become a target directory')

    def test_dot_and_dotdot_targets_in_home_are_global(self):
        with tempfile.TemporaryDirectory() as temporary:
            home = Path(temporary) / 'home'
            sub = home / 'sub'
            sub.mkdir(parents=True)
            env = {**os.environ, 'HOME': str(home)}
            for target, cwd in (('.', home), ('..', sub), ('sub/..', home), ('~', sub), ('~/', sub)):
                res = run('--target', target, '--apply', env=env, cwd=cwd)
                self.assertEqual(res.returncode, 0, (target, res.stderr))
                for source in PAYLOAD.rglob('*'):
                    if source.is_file():
                        self.assertEqual(global_dest(home, source).read_bytes(), source.read_bytes())
                self.assertEqual([p.name for p in home.glob('*.md')], [], f'{target}: project-mode file in HOME')
                shutil.rmtree(home / TOOL)

    def test_dotdot_and_tilde_user_are_not_home(self):
        with tempfile.TemporaryDirectory() as temporary:
            base = Path(temporary)
            home = base / 'home'
            proj = base / 'proj'
            (home).mkdir()
            (proj / 'sub').mkdir(parents=True)
            env = {**os.environ, 'HOME': str(home)}
            self.assertEqual(run('--target', '..', '--apply', env=env, cwd=proj / 'sub').returncode, 0)
            self.assertTrue(any(proj.rglob('*')) and not (proj / 'sub' / TOOL).exists())
            self.assertEqual(list(home.iterdir()), [])
            self.assertEqual(run('--target', '~foo', '--apply', env=env, cwd=base).returncode, 0)
            self.assertTrue((base / '~foo').is_dir(), '~foo must stay a literal relative path')
            self.assertEqual(list(home.iterdir()), [], '~foo must not expand to <home>foo')

    def test_dotdot_through_link_is_refused(self):
        with tempfile.TemporaryDirectory() as temporary:
            base = Path(temporary)
            (base / 'real' / 'deep').mkdir(parents=True)
            try:
                (base / 'link').symlink_to(base / 'real' / 'deep', target_is_directory=True)
            except OSError:
                self.skipTest('Symlink creation unavailable on this host')
            res = run('--target', str(base / 'link' / '..' / 'x'), '--apply')
            self.assertEqual(res.returncode, 1)
            self.assertEqual(list((base / 'real').iterdir()), [base / 'real' / 'deep'])

    def test_create_is_exclusive_after_preflight(self):
        with tempfile.TemporaryDirectory() as temporary:
            base = Path(temporary)
            target = base / 'project'
            race = target / min(p for p in PAYLOAD.rglob('*') if p.is_file()).relative_to(PAYLOAD)
            shim_dir = base / 'shim'
            shim_dir.mkdir()
            shim = shim_dir / 'mkdir'
            shim.write_text(
                '#!/bin/sh\n'
                f'[ -e "{base}/mark" ] || {{ : > "{base}/mark"; {shutil.which("mkdir")} -p "$(dirname "{race}")"; printf "user content" > "{race}"; }}\n'
                f'exec {shutil.which("mkdir")} "$@"\n', encoding='utf-8')
            shim.chmod(0o755)
            env = {**os.environ, 'PATH': f'{shim_dir}:{os.environ["PATH"]}'}
            res = run('--target', str(target), '--apply', env=env)
            self.assertTrue((base / 'mark').exists(), 'shim did not run; race not exercised')
            self.assertEqual(res.returncode, 1)
            self.assertIn('Falha ao criar arquivo', res.stderr)
            self.assertEqual(race.read_text(encoding='utf-8'), 'user content')

    def test_link_inside_package_is_refused(self):
        with tempfile.TemporaryDirectory() as temporary:
            pkg = Path(temporary) / 'pkg'
            (pkg / 'scripts').mkdir(parents=True)
            shutil.copy(SCRIPT, pkg / 'scripts' / 'install.sh')
            shutil.copytree(PAYLOAD, pkg / 'payload')
            first = min(p for p in (pkg / 'payload').rglob('*') if p.is_file())
            try:
                (pkg / 'payload' / 'evil.md').symlink_to(first)
            except OSError:
                self.skipTest('Symlink creation unavailable on this host')
            target = Path(temporary) / 'project'
            res = subprocess.run(['bash', str(pkg / 'scripts' / 'install.sh'), '--target', str(target), '--apply'],
                                 capture_output=True, text=True)
            self.assertEqual(res.returncode, 1)
            self.assertIn('Link no pacote', res.stdout)
            self.assertFalse(target.exists())

    def test_specialist_conflict_is_refused(self):
        with tempfile.TemporaryDirectory() as temporary:
            target = Path(temporary) / 'project'
            args = ('--target', str(target), '--with-zabbix-specialist', '--apply')
            self.assertEqual(run(*args).returncode, 0)
            skill = target / TOOL / 'skills' / 'zabbix-specialist' / 'SKILL.md'
            skill.write_text('user content', encoding='utf-8')
            self.assertEqual(run(*args).returncode, 1)
            self.assertEqual(skill.read_text(encoding='utf-8'), 'user content')

    def test_default_install_has_no_specialists(self):
        with tempfile.TemporaryDirectory() as temporary:
            target = Path(temporary) / 'project'
            self.assertEqual(run('--target', str(target), '--apply').returncode, 0)
            installed = {str(p.relative_to(target)) for p in target.rglob('*') if p.is_file()}
            self.assertEqual(installed, {str(p.relative_to(PAYLOAD)) for p in PAYLOAD.rglob('*') if p.is_file()})
            names = SPECS + [s.removesuffix('-specialist') for s in SPECS] + ['sre-incident', 'database-tuning']
            for name in names:
                self.assertFalse([p for p in installed if name in p], name)

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

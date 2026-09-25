#!/usr/bin/env python3
"""Install framework files for project or global home; audit by default, never overwrite conflicts."""
import argparse
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--target', type=Path, default=None, help='Target directory for project installation')
    parser.add_argument('--global', '-g', dest='is_global', action='store_true', help='Install globally to user home directory')
    parser.add_argument('--apply', action='store_true', help='Apply changes (audit-only by default)')
    args = parser.parse_args()

    home = Path.home().resolve()
    if args.is_global:
        target = args.target.expanduser().absolute() if args.target else Path.home()
        is_global = True
    elif args.target is not None:
        target = args.target.expanduser().absolute()
        is_global = (target.resolve() == home)
    else:
        parser.error('one of --target <path> or --global is required')

    payload = Path(__file__).resolve().parents[1] / 'payload'

    # Discover tool dot-directory in payload (e.g. .gemini, .claude, .cursor)
    tool_dot_dir = None
    for item in payload.iterdir():
        if item.is_dir() and item.name.startswith('.'):
            tool_dot_dir = item.name
            break

    pending, errors = [], []
    for source in sorted(payload.rglob('*')):
        if source.is_symlink():
            errors.append(f'Link no pacote: {source}')
            continue
        if not source.is_file():
            continue
        source_rel = source.relative_to(payload)
        if is_global and tool_dot_dir and not source_rel.parts[0].startswith('.'):
            dest = target / tool_dot_dir / source_rel
        else:
            dest = target / source_rel

        chain = [dest, *dest.parents]
        if any(p.is_symlink() for p in chain):
            errors.append(f'Link no destino: {dest}')
        elif any(p.exists() and not p.is_dir() for p in dest.parents):
            errors.append(f'Pai não é diretório: {dest}')
        elif dest.exists():
            if not dest.is_file() or dest.read_bytes() != source.read_bytes():
                errors.append(f'Conflito, preservar e mesclar manualmente: {dest}')
            else:
                print(f'IDÊNTICO {dest}')
        else:
            pending.append((source, dest))
            print(f'CRIAR {dest}')
    if errors:
        for error in errors:
            print(error)
        raise SystemExit(1)
    if not args.apply:
        print(f'Auditoria: {len(pending)} arquivo(s) novo(s); nenhuma alteração.')
        return
    # Exclusive creation also refuses a conflicting file appearing after preflight.
    for source, dest in pending:
        if any(p.is_symlink() for p in [dest, *dest.parents]):
            raise SystemExit(f'Destino tornou-se link; instalação interrompida: {dest}')
        dest.parent.mkdir(parents=True, exist_ok=True)
        with dest.open('xb') as output:
            output.write(source.read_bytes())
    print(f'Instalados {len(pending)} arquivo(s). Configurações existentes preservadas.')


if __name__ == '__main__':
    main()

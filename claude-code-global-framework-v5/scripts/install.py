#!/usr/bin/env python3
"""Install new project files only; audit by default, never overwrite conflicts."""
import argparse
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--target', required=True, type=Path)
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    target = args.target.absolute()
    payload = Path(__file__).resolve().parents[1] / 'payload'
    pending, errors = [], []
    for source in sorted(payload.rglob('*')):
        if source.is_symlink():
            errors.append(f'Link no pacote: {source}')
            continue
        if not source.is_file():
            continue
        dest = target / source.relative_to(payload)
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

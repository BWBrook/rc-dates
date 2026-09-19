#!/usr/bin/env python3
"""Verify distributed bytes and each original evidence inventory."""
from pathlib import Path
import hashlib

GENERATED = ('.git', 'data', 'data-raw', 'out/reproduced', 'out/rerun',
             'renv/library', 'renv/staging', 'renv/sandbox')

ROOT = Path(__file__).resolve().parents[2]


def check(manifest: Path) -> int:
    count = 0
    for line in manifest.read_text().splitlines():
        if not line.strip():
            continue
        expected, name = line.split(maxsplit=1)
        name = name.lstrip('*')
        path = (manifest.parent / name).resolve()
        if not path.is_relative_to(ROOT) or not path.is_file():
            raise SystemExit(f'Missing or unsafe inventory path: {name}')
        with path.open('rb') as handle:
            observed = hashlib.file_digest(handle, 'sha256').hexdigest()
        if observed != expected:
            raise SystemExit(f'Checksum mismatch: {path.relative_to(ROOT)}')
        count += 1
    print(f'{manifest.relative_to(ROOT)}: {count} files verified')
    return count


if __name__ == '__main__':
    inventory = ROOT / 'SHA256SUMS'
    if not inventory.is_file():
        raise SystemExit('Run this check from the assembled release, which contains SHA256SUMS.')
    check(inventory)
    listed = {line.split(maxsplit=1)[1].lstrip('*')
              for line in inventory.read_text().splitlines() if line.strip()}
    # Nested manifests are distributed files; only the root inventory is exempt.
    actual = {p.relative_to(ROOT).as_posix() for p in ROOT.rglob('*')
              if p.is_file() and p != inventory}
    actual = {name for name in actual
              if not any(name == prefix or name.startswith(prefix + '/') for prefix in GENERATED)
              and name not in ('.Rhistory', '.RData')}
    if listed != actual:
        raise SystemExit(f'Inventory coverage differs: missing={sorted(actual-listed)}, '
                         f'absent={sorted(listed-actual)}')
    for folder in ('out/empirical-sampling', 'out/revision/signed-models',
                   'out/revision/endpoint-contrast-20260919',
                   'out/sensitivity/observation-noise',
                   'out/sensitivity/observation-noise/estimand-aligned-v2',
                   'provenance/observation-noise-20260726'):
        check(ROOT / folder / 'SHA256SUMS')

#!/usr/bin/env python3
"""Assemble only the scientific release files; never read governed source data."""
from pathlib import Path
import argparse
import hashlib
import json
import shutil
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[2]
NAME = 'rc-dates-scientific-reproducibility-2026-09-11'
TREES = ('R', 'tests', 'out/empirical-sampling', 'out/revision/signed-models',
         'out/sensitivity/observation-noise', 'provenance/observation-noise-20260726',
         'release/inputs', 'release/historical', 'manuscript/figures')
FILES = ('renv.lock', 'renv/activate.R', 'renv/settings.json',
         'scripts/source_population_simulation.R',
         'scripts/render_manuscript_methods_figures.R',
         'scripts/render_population_simulation_figures.R',
         'manuscript/text/main.md', 'manuscript/text/supplementary.md', 'manuscript/text/figures.md',
         'docs/STAGE3_EMPIRICAL_REPAIR.md', 'release/claims.csv', 'references/refs.yaml')
SCRIPTS = ('common.R', 'simulation_specification.R', 'rerun_simulations.R',
           'export_simulation_specification.R',
           'rebuild_signed_summaries.R', 'rebuild_noise_summaries.R',
           'render_empirical_figures.R', 'render_site_counts.R',
           'reconstruct_austarch_reference.R', 'compare_empirical.R',
           'audit_manuscript_claims.py', 'verify_release.py')
TEMPLATES = {'README.md': 'README.md', 'Makefile': 'Makefile',
             'Dockerfile': 'docker/Dockerfile',
             '99-rc-dates-fonts.conf': 'docker/99-rc-dates-fonts.conf',
             'install-release-packages.R': 'docker/install-release-packages.R',
             'VALIDATION.md': 'VALIDATION.md',
             'CLAIM_AUDIT.md': 'CLAIM_AUDIT.md',
             'AUSTARCH_PROVENANCE.md': 'docs/AUSTARCH_PROVENANCE.md',
             'tests/testthat/test_population_simulation.R': 'tests/testthat/test_population_simulation.R',
             'tests/testthat/test_manuscript_methods_figures.R': 'tests/testthat/test_manuscript_methods_figures.R'}


def sha(path):
    with path.open('rb') as handle:
        return hashlib.file_digest(handle, 'sha256').hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--destination', type=Path, default=ROOT / 'dist' / NAME)
    parser.add_argument('--allow-working-tree', action='store_true',
                        help='Permit a provisional candidate and label its uncommitted source state')
    args = parser.parse_args()
    dirty = bool(subprocess.check_output(
        ['git', 'status', '--porcelain', '--untracked-files=all'], cwd=ROOT, text=True).strip())
    if dirty and not args.allow_working_tree:
        raise SystemExit('Commit the release sources before final assembly, or use --allow-working-tree for a labelled candidate.')
    target = args.destination.resolve()
    if target.exists():
        raise SystemExit(f'Refusing to overwrite existing assembly: {target}')
    paths = set(FILES) | {f'scripts/release/{s}' for s in SCRIPTS}
    for tree in TREES:
        paths |= {p.relative_to(ROOT).as_posix() for p in (ROOT / tree).rglob('*')
                  if p.is_file() and not any(part.startswith('.') or part in
                      ('logs', '__pycache__') for part in p.relative_to(ROOT / tree).parts)}
    sources = {name: ROOT / name for name in paths}
    sources.update({dest: ROOT / 'release/templates' / src for src, dest in TEMPLATES.items()})
    for name, path in sources.items():
        if not path.is_file() or path.is_symlink():
            raise SystemExit(f'Missing or linked required source: {path}')
    target.mkdir(parents=True)
    for name, path in sorted(sources.items()):
        dest = target / name
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(path, dest)
    (target / '.gitignore').write_text('data/\ndata-raw/\nout/reproduced/\nout/rerun/\nrenv/library/\nrenv/staging/\nrenv/sandbox/\n.Rhistory\n.RData\n')
    commit = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    info = {'name': NAME, 'date': '2026-09-11', 'source_commit': commit, 'source_working_tree_dirty': dirty,
            'source_commit_is_exact': not dirty,
            'copied_source_files': len(sources), 'distributed_files': len(sources) + 3,
            'r_version': '4.5.3',
            'assembly': 'Explicit allowlist; no raw archaeological inputs or development Git history.'}
    (target / 'RELEASE.json').write_text(json.dumps(info, indent=2) + '\n')
    files = sorted(p for p in target.rglob('*') if p.is_file())
    (target / 'SHA256SUMS').write_text(''.join(f'{sha(p)}  {p.relative_to(target).as_posix()}\n' for p in files))
    subprocess.run(['python3', 'scripts/release/verify_release.py'], cwd=target, check=True)
    archive = target.with_suffix('.zip')
    if archive.exists():
        raise SystemExit(f'Refusing to overwrite existing ZIP: {archive}')
    with zipfile.ZipFile(archive, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as zipped:
        for path in sorted(p for p in target.rglob('*') if p.is_file()):
            entry = zipfile.ZipInfo(f'{NAME}/{path.relative_to(target).as_posix()}', (2026, 9, 11, 0, 0, 0))
            entry.compress_type = zipfile.ZIP_DEFLATED
            entry.external_attr = 0o100644 << 16
            zipped.writestr(entry, path.read_bytes())
    archive.with_suffix('.zip.sha256').write_text(f'{sha(archive)}  {archive.name}\n')
    print(f'Assembled {len(files)+1} files: {target}\nZIP: {archive} ({archive.stat().st_size:,} bytes)')


if __name__ == '__main__':
    main()

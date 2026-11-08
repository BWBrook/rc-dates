# Choosing among a site's radiocarbon dates can create or reverse regional trends

The same study is written three ways, all in `text/`, all from one evidence base:

| File | Reader | Rendered |
|---|---|---|
| `main.md` + `figures.md`, `supplement.md` + `supplement_figures.md` | scientists; the journal snapshot | `build/manuscript.pdf`, `build/supplement.pdf` |
| `brief.md` + `brief_figures.md` | anyone: two A4 pages, one sheet printed double-sided | `build/brief.pdf` |
| `for-agents.md` | an agent arriving cold: claims, provenance, traps, checks | read as Markdown |

`claims.csv` is the single claims ledger. All four renderings cite it, binding quoted numbers as
`[428.8]{.C01}` (invisible in PDF and DOCX); `value-bindings.csv` can bind a number further to one row
and field of its evidence. `estimands.md` states what each analysis bounds and which phrasings are
not allowed.

## Build

The paper builds with [makedoc](https://github.com/BWBrook/makedoc), expected at `~/work/makedoc`
(override with `MAKEDOC=...`). `makedoc.lock.json` pins its revision. TeX (xelatex), Pandoc and
poppler are system dependencies; `uv` supplies Python. From the repository root:

```sh
make manuscript-check             # claims ledger, glyphs, makedoc lint, citation audit, numeric registry
make manuscript-build             # PDF and DOCX into manuscript/build/, then the brief's two-page check
make submission-build             # journal-facing files in manuscript/submission/dist/
```

On a machine whose `/tmp` is a tmpfs (wsl-laptop since its Ubuntu 26.04 upgrade), makedoc's DOCX step
fails with "Invalid cross-device link"; set `TMPDIR` to a directory on the same filesystem as the
repository, for example `export TMPDIR=$HOME/.cache/tmp-makedoc`.

The bibliography is a Better BibTeX CSL-YAML export from Zotero (`references/refs.yaml`).
`references/dois.txt` lists every cited DOI, one per line, for Zotero's magic-wand import; two works
without DOIs (the R reference and Ulm et al. 1996) are maintained in Zotero directly. Re-export rather
than editing `refs.yaml` by hand, and cite the exported key as `[@key]`. Crossref-generated keys and
years differ from the Zotero export for a quarter of these works, so do not regenerate the file from
Crossref.

`release/claims.csv` is an older, finer-grained numeric registry (111 checks, each with a row filter
and operation), run by `scripts/release/audit_manuscript_claims.py`. It complements `claims.csv`
until the two are merged. Generated content is not edited by hand: `figures/`, `references/refs.yaml`
and `build/`.

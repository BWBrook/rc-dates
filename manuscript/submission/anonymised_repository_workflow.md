# Anonymised Repository Workflow

Purpose: prepare a de-identified code/data archive for peer review without making the named GitHub repository public before acceptance.

## Recommended route

Use Figshare for the review deposit unless there is a journal-portal reason to choose another repository. The fit is good because Figshare documents a pre-publication workflow in which an item remains unpublished, a DOI can be reserved for citation in the manuscript, and a private link can give reviewers anonymous access to files and metadata.

Official references:

- JAS requires relevant research data to be deposited in a repository and cited/linked in the article: <https://www.sciencedirect.com/journal/journal-of-archaeological-science/publish/guide-for-authors>
- JAS also recommends repository DOIs or similar persistent identifiers in the Data Availability Statement: <https://www.sciencedirect.com/journal/journal-of-archaeological-science/about/reproducibility-at-journal-of-archaeological-science/reproducibility-at-jas>
- Figshare private links can be used for anonymous peer review and expose an anonymised metadata view: <https://info.figshare.com/user-guide/how-to-use-private-links/>
- Figshare documents the reserve-DOI plus anonymous private-link workflow for datasets linked to papers: <https://info.figshare.com/user-guide/how-to-publish-a-dataset-at-the-same-time-as-the-associated-paper/>

## Fallback routes

- Zenodo can reserve a DOI and create secret links with draft-preview access, but check the draft-link view carefully for double-blind metadata before using it. Relevant docs: <https://help.zenodo.org/docs/share/link-sharing/> and <https://help.zenodo.org/docs/deposit/describe-records/reserve-doi/>.
- OSF supports anonymized view-only links for private projects, but OSF project DOI creation is tied to public projects. This is useful for blind review access but is less direct if the manuscript needs a reserved DOI before public release. Relevant docs: <https://help.osf.io/article/353-welcome-to-projects>.

## Pre-upload gate

Run these checks after the codebase and manuscript revisions are locked:

1. From the repository root, run `R_PROFILE_USER=/dev/null Rscript scripts/build_review_package.R`.
2. Rebuild `/home/bwbrook/papers/de_identified_repos/rc_review_package.zip` from the generated package directory.
3. Copy the zip into `manuscript/submission/dist/rc_review_package.zip`.
4. Record `sha256sum /home/bwbrook/papers/de_identified_repos/rc_review_package.zip`.
5. Confirm `zipinfo -1` contains no `manuscript/`, `csl/`, `docs/`, `references/`, `reports/`, `.git/`, `.github/`, or local agent notes.
6. Confirm the package README, `REPRODUCE.md`, and `SIMULATION_PROVENANCE.md` describe the fast verification path and high-volume simulation scope.
7. Search the unzipped archive for identifying author strings, local machine paths, ORCID identifiers, emails, and institution names.
8. From a clean checkout or temporary folder using R 4.5.x, restore `renv`, run tests, and run the documented fast verification path.

## Manual Figshare upload

1. Create a new unpublished item.
2. Upload `rc_review_package.zip`.
3. Use `private_review_repository_metadata.md` as the metadata template.
4. Reserve a DOI, but do not publish the item.
5. Create a private link for anonymous peer review.
6. Open the private link in a fresh browser session where you are not logged in.
7. Confirm the private-link page hides author identity and allows the zip to be downloaded.
8. Download the zip from the private link and confirm its SHA256 hash matches the local locked package.
9. Replace `[PRIVATE_REVIEW_LINK]`, `[RESERVED_DOI]`, and `[ARCHIVE_SHA256]` in the manuscript/submission files.
10. Submit the private link and reserved DOI with the manuscript.

After acceptance, update the record metadata with full author details, add the article DOI as a related material, review the licence and files one last time, then publish the repository record.

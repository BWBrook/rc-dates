#!/usr/bin/env python3
"""Count manuscript words in a built DOCX the way the 5,000-word limit is checked.

Counts whitespace-delimited words in all w:t and m:t text, including title, headings,
abstract, declarations and captions, and excludes the References heading through the
paragraph before the first figure caption. Reproduces the round-2 count of 4,766.
Usage: python3 scripts/release/count_manuscript_words.py manuscript.docx
"""
import re
import sys
import zipfile
from xml.etree import ElementTree as ET

W = "{http://schemas.openxmlformats.org/wordprocessingml/2006/main}"
M = "{http://schemas.openxmlformats.org/officeDocument/2006/math}"

root = ET.fromstring(zipfile.ZipFile(sys.argv[1]).read("word/document.xml"))
paras = ["".join(n.text or "" for n in p.iter() if n.tag in (W + "t", M + "t")) for p in root.iter(W + "p")]
start = next(i for i, t in enumerate(paras) if t.strip() == "References")
end = next(i for i, t in enumerate(paras) if i > start and re.match(r"^(Fig\.|Figure)\s*1[.:]", t.strip()))
abstract = next(i for i, t in enumerate(paras) if t.strip() == "Abstract")
total = sum(len(t.split()) for t in paras[:start] + paras[end:])
print(f"words={total} abstract={len(paras[abstract + 1].split())} captions={sum(len(t.split()) for t in paras[end:])}")

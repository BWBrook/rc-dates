#!/usr/bin/env python3
"""Replace standalone DOCX page-break paragraphs with paragraph formatting."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import tempfile
from xml.etree import ElementTree as ET
from zipfile import ZIP_DEFLATED, BadZipFile, ZipFile


WORD_NS = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
W = f"{{{WORD_NS}}}"


def is_standalone_page_break(paragraph: ET.Element) -> bool:
    if paragraph.tag != f"{W}p":
        return False
    if any((node.text or "").strip() for node in paragraph.iter(f"{W}t")):
        return False
    breaks = list(paragraph.iter(f"{W}br"))
    return bool(breaks) and all(node.get(f"{W}type") == "page" for node in breaks)


def add_page_break_before(paragraph: ET.Element) -> None:
    properties = paragraph.find(f"{W}pPr")
    if properties is None:
        properties = ET.Element(f"{W}pPr")
        paragraph.insert(0, properties)
    if properties.find(f"{W}pageBreakBefore") is None:
        properties.append(ET.Element(f"{W}pageBreakBefore"))


def normalize_document_xml(payload: bytes) -> tuple[bytes, int]:
    root = ET.fromstring(payload)
    body = root.find(f".//{W}body")
    if body is None:
        raise ValueError("word/document.xml has no document body")

    children = list(body)
    normalized = 0
    for index, child in enumerate(children):
        if not is_standalone_page_break(child):
            continue
        following = next(
            (candidate for candidate in children[index + 1 :] if candidate.tag == f"{W}p"),
            None,
        )
        if following is None:
            continue
        add_page_break_before(following)
        body.remove(child)
        normalized += 1

    return ET.tostring(root, encoding="utf-8", xml_declaration=True), normalized


def normalize_docx(path: Path) -> int:
    if not path.is_file():
        raise FileNotFoundError(f"DOCX not found: {path}")

    try:
        with ZipFile(path) as source:
            entries = source.infolist()
            document_xml = source.read("word/document.xml")
            normalized_xml, count = normalize_document_xml(document_xml)
            if count == 0:
                return 0

            handle, temporary_name = tempfile.mkstemp(
                prefix=f".{path.stem}.", suffix=".docx", dir=path.parent
            )
            os.close(handle)
            temporary_path = Path(temporary_name)
            try:
                with ZipFile(temporary_path, "w", compression=ZIP_DEFLATED) as target:
                    for entry in entries:
                        payload = (
                            normalized_xml
                            if entry.filename == "word/document.xml"
                            else source.read(entry.filename)
                        )
                        target.writestr(entry, payload)
                os.replace(temporary_path, path)
            finally:
                temporary_path.unlink(missing_ok=True)
    except BadZipFile as exc:
        raise ValueError(f"Invalid DOCX archive: {path}") from exc

    return count


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("docx", type=Path, help="DOCX file to normalize in place")
    args = parser.parse_args()

    count = normalize_docx(args.docx)
    print(f"Normalized {count} standalone page-break paragraph(s): {args.docx}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

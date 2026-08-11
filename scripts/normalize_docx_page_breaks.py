#!/usr/bin/env python3
"""Replace standalone DOCX page-break paragraphs with paragraph formatting."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import re
import tempfile
from xml.etree import ElementTree as ET
from zipfile import ZIP_DEFLATED, BadZipFile, ZipFile


WORD_NS = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
W = f"{{{WORD_NS}}}"
WINDOWS_ABSOLUTE_PATH = re.compile(r"^[A-Za-z]:[\\/]")


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


def is_absolute_resource_path(value: str) -> bool:
    return value.startswith(("/", "file:/")) or bool(WINDOWS_ABSOLUTE_PATH.match(value))


def resource_basename(value: str) -> str:
    return value.replace("\\", "/").rstrip("/").rsplit("/", maxsplit=1)[-1]


def scrub_absolute_resource_paths(
    payload: bytes, *, scrub_text: bool = False
) -> tuple[bytes, int]:
    root = ET.fromstring(payload)
    scrubbed = 0
    for element in root.iter():
        for attribute, value in list(element.attrib.items()):
            if is_absolute_resource_path(value):
                element.set(attribute, resource_basename(value))
                scrubbed += 1
        if (
            scrub_text
            and element.text is not None
            and is_absolute_resource_path(element.text.strip())
        ):
            element.text = resource_basename(element.text.strip())
            scrubbed += 1
    return ET.tostring(root, encoding="utf-8", xml_declaration=True), scrubbed


def normalize_docx(path: Path) -> tuple[int, int]:
    if not path.is_file():
        raise FileNotFoundError(f"DOCX not found: {path}")

    try:
        with ZipFile(path) as source:
            entries = source.infolist()
            document_xml = source.read("word/document.xml")
            normalized_xml, count = normalize_document_xml(document_xml)
            normalized_xml, document_paths = scrub_absolute_resource_paths(normalized_xml)
            custom_xml = None
            custom_paths = 0
            if "docProps/custom.xml" in source.namelist():
                custom_xml, custom_paths = scrub_absolute_resource_paths(
                    source.read("docProps/custom.xml"), scrub_text=True
                )
            scrubbed_paths = document_paths + custom_paths
            if count == 0 and scrubbed_paths == 0:
                return 0, 0

            handle, temporary_name = tempfile.mkstemp(
                prefix=f".{path.stem}.", suffix=".docx", dir=path.parent
            )
            os.close(handle)
            temporary_path = Path(temporary_name)
            try:
                with ZipFile(temporary_path, "w", compression=ZIP_DEFLATED) as target:
                    for entry in entries:
                        if entry.filename == "word/document.xml":
                            payload = normalized_xml
                        elif entry.filename == "docProps/custom.xml" and custom_xml is not None:
                            payload = custom_xml
                        else:
                            payload = source.read(entry.filename)
                        target.writestr(entry, payload)
                os.replace(temporary_path, path)
            finally:
                temporary_path.unlink(missing_ok=True)
    except BadZipFile as exc:
        raise ValueError(f"Invalid DOCX archive: {path}") from exc

    return count, scrubbed_paths


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("docx", type=Path, help="DOCX file to normalize in place")
    args = parser.parse_args()

    count, scrubbed_paths = normalize_docx(args.docx)
    print(
        f"Normalized {count} standalone page-break paragraph(s) and scrubbed "
        f"{scrubbed_paths} absolute resource path(s): {args.docx}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

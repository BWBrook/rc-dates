#!/usr/bin/env python3
"""Embed PDF figures as proportioned 300-dpi PNGs in the review DOCX."""

import argparse
import os
from pathlib import Path
import re
import statistics
import struct
import subprocess
import tempfile
from xml.etree import ElementTree as ET
from zipfile import ZipFile


NS = {
    "wp": "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing",
    "a": "http://schemas.openxmlformats.org/drawingml/2006/main",
    "pic": "http://schemas.openxmlformats.org/drawingml/2006/picture",
    "r": "http://schemas.openxmlformats.org/officeDocument/2006/relationships",
}


def normalize_figures(docx: Path, figures: Path) -> int:
    widths = {
        Path(path).name: float(width) / 100
        for path, width in re.findall(
            r"\]\(([^)]+)\)\{[^}]*width=([\d.]+)%", figures.read_text()
        )
    }
    with ZipFile(docx) as source:
        entries = source.infolist()
        payloads = {entry.filename: source.read(entry) for entry in entries}
    document = ET.fromstring(payloads["word/document.xml"])
    relationships = ET.fromstring(payloads["word/_rels/document.xml.rels"])
    rels = {rel.get("Id"): rel for rel in relationships}
    drawings = list(document.findall(".//wp:inline", NS))
    # Pandoc sizes PNGs correctly; use those and the source percentages to
    # recover its reference width, instead of retaining its PDF fallback size.
    reference_widths = []
    pending = []
    for drawing in drawings:
        blip = drawing.find(".//a:blip", NS)
        description = drawing.find(".//pic:cNvPr", NS)
        if blip is None or description is None:
            continue
        rel = rels[blip.get(f"{{{NS['r']}}}embed")]
        target = rel.get("Target", "")
        name = Path(description.get("descr", "")).name
        if target.lower().endswith(".pdf"):
            pending.append((drawing, rel, name))
        elif name in widths:
            extent = drawing.find("wp:extent", NS)
            reference_widths.append(int(extent.get("cx")) / widths[name])
    if not pending:
        return 0
    if not reference_widths:
        raise ValueError("No correctly sized raster figure to establish DOCX width")
    reference_width = statistics.median(reference_widths)
    replacements = {}
    with tempfile.TemporaryDirectory(prefix="rc-dates-docx-figures-") as directory:
        for drawing, rel, name in pending:
            old_path = "word/" + rel.get("Target")
            pdf = Path(directory) / "figure.pdf"
            png = Path(directory) / "figure.png"
            pdf.write_bytes(payloads[old_path])
            subprocess.run(
                ["pdftoppm", "-singlefile", "-f", "1", "-r", "300", "-png",
                 str(pdf), str(png.with_suffix(""))], check=True,
                stdout=subprocess.DEVNULL,
            )
            image = png.read_bytes()
            pixels_x, pixels_y = struct.unpack(">II", image[16:24])
            cx = round(reference_width * widths[name])
            cy = round(cx * pixels_y / pixels_x)
            for extent in (drawing.find("wp:extent", NS),
                           drawing.find(".//a:xfrm/a:ext", NS)):
                extent.set("cx", str(cx))
                extent.set("cy", str(cy))
            new_path = str(Path(old_path).with_suffix(".png"))
            replacements[old_path] = (new_path, image)
            rel.set("Target", str(Path(rel.get("Target")).with_suffix(".png")))
        content_types = ET.fromstring(payloads["[Content_Types].xml"])
        for entry in content_types:
            old_path = entry.get("PartName", "").lstrip("/")
            if old_path in replacements:
                entry.set("PartName", "/" + replacements[old_path][0])
                entry.set("ContentType", "image/png")
        # OPC package readers (including LibreOffice) require the package
        # metadata namespaces as default namespaces for these two parts.
        ET.register_namespace("", "http://schemas.openxmlformats.org/package/2006/content-types")
        payloads["[Content_Types].xml"] = ET.tostring(content_types, encoding="utf-8", xml_declaration=True)
        payloads["word/document.xml"] = ET.tostring(document, encoding="utf-8", xml_declaration=True)
        ET.register_namespace("", "http://schemas.openxmlformats.org/package/2006/relationships")
        payloads["word/_rels/document.xml.rels"] = ET.tostring(relationships, encoding="utf-8", xml_declaration=True)
        handle, temporary = tempfile.mkstemp(suffix=".docx", dir=docx.parent)
        os.close(handle)
        try:
            with ZipFile(temporary, "w") as target:
                for entry in entries:
                    if entry.filename in replacements:
                        entry.filename, payload = replacements[entry.filename]
                    else:
                        payload = payloads[entry.filename]
                    target.writestr(entry, payload)
            os.replace(temporary, docx)
        finally:
            Path(temporary).unlink(missing_ok=True)
    return len(pending)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("docx", type=Path)
    parser.add_argument("figures", type=Path)
    args = parser.parse_args()
    print(f"Normalised {normalize_figures(args.docx, args.figures)} PDF figures: {args.docx}")

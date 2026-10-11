#!/usr/bin/env python3
"""Regenerate square source artwork and opaque static catalog icons.

Maintenance only: requires CairoSVG; app builds use the committed assets.
"""
from pathlib import Path
import xml.etree.ElementTree as ET

import cairosvg

ROOT = Path(__file__).resolve().parents[2]
SVG = "http://www.w3.org/2000/svg"
ET.register_namespace("", SVG)
source = ET.parse(Path(__file__).with_name("OwlPhoenix.svg"))
canvas = source.getroot()
canvas.set("viewBox", "0 0 1024 1024")
emblem = canvas.find(f"{{{SVG}}}g")
emblem.set("transform", "translate(102.08 175.04) scale(0.96)")
emblem.set("fill", "#17191D")
artwork = ROOT / "Joghd/Resources/AppIcon.icon/Assets/OwlPhoenix.svg"
source.write(artwork, encoding="unicode")

catalog = ROOT / "Joghd/Resources/Assets.xcassets/AppIcon.appiconset"
background = ET.Element(f"{{{SVG}}}rect", width="1024", height="1024")
canvas.insert(2, background)
for name, foreground, fill in [
    ("AppIcon.png", "#17191D", "#F7F7F5"),
    ("AppIcon-dark.png", "#A8ADB5", "#17191D"),
    ("AppIcon-tinted.png", "#FFFFFF", "#17191D"),
]:
    emblem.set("fill", foreground)
    background.set("fill", fill)
    cairosvg.svg2png(
        bytestring=ET.tostring(canvas),
        write_to=str(catalog / name),
        output_width=1024,
        output_height=1024,
    )

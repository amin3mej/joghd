#!/usr/bin/env python3
import os
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "JoghdTests", "Fixtures", "sample.epub")

CONTAINER = """<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>
"""

PACKAGE = """<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="bookid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>A Tiny Book</dc:title>
    <dc:creator>Ada Lovelace</dc:creator>
  </metadata>
  <manifest>
    <item id="second" href="second.xhtml" media-type="application/xhtml+xml"/>
    <item id="first" href="Text/first.xhtml" media-type="application/xhtml+xml"/>
    <item id="third" href="third.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="first"/>
    <itemref idref="second"/>
    <itemref idref="third"/>
  </spine>
</package>
"""

FIRST = """<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <title>First Chapter</title>
  </head>
  <body>
    <h1>First Chapter</h1>
    <p>Alpha with <em>italic</em> and <strong>bold</strong>.</p>
    <blockquote>A quoted line.</blockquote>
    <ul>
      <li>One</li>
      <li>Two</li>
    </ul>
  </body>
</html>
"""

SECOND = """<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <title>Second Chapter</title>
  </head>
  <body>
    <h2>Section</h2>
    <p>Beta</p>
  </body>
</html>
"""

THIRD = """<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <title>Third Chapter</title>
  </head>
  <body>
    <p>Gamma</p>
  </body>
</html>
"""


def main():
    with zipfile.ZipFile(OUT, "w") as archive:
        archive.writestr(
            "mimetype",
            "application/epub+zip",
            compress_type=zipfile.ZIP_STORED,
        )
        archive.writestr("META-INF/container.xml", CONTAINER, zipfile.ZIP_DEFLATED)
        archive.writestr("OEBPS/content.opf", PACKAGE, zipfile.ZIP_DEFLATED)
        archive.writestr("OEBPS/Text/first.xhtml", FIRST, zipfile.ZIP_DEFLATED)
        archive.writestr("OEBPS/second.xhtml", SECOND, zipfile.ZIP_DEFLATED)
        archive.writestr("OEBPS/third.xhtml", THIRD, zipfile.ZIP_DEFLATED)
    print("wrote", os.path.abspath(OUT))


if __name__ == "__main__":
    main()

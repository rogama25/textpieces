#!/usr/bin/env python3

# SPDX-FileCopyrightText: 2022 Adrián Bíro
#
# SPDX-License-Identifier: GPL-3.0-or-later

from xml.etree import ElementTree
from sys import stdin, stdout, stderr, argv

try:
    tree = ElementTree.parse(stdin)
except ElementTree.ParseError as err:
    stderr.write(f"Can't parse OPML-XML: {err.msg}")
    exit(1)

titles_urls = {}
for i in tree.findall('.//outline'):
    url = i.attrib.get('xmlUrl')
    title = i.attrib.get('title')
    titles_urls.update({title: url})

for v in titles_urls.values():
    # Some RSS readers tend to export invalid duplicities, this takes care of that.
    if v is not None:
        stdout.write(f'{v.strip()}\n')

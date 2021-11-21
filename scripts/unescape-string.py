#!/usr/bin/env python3

import warnings
from sys import stdin, stderr, stdout

with warnings.catch_warnings(record=True) as w:
    stdout.write(stdin.read().encode('utf-8').decode('unicode_escape'))
    if w:
        for warning in map(lambda warning: warning.message, w):
            if isinstance(warning, DeprecationWarning):
                stderr.write(f"Can't unescape string: {str(warning)}")
                exit(1)

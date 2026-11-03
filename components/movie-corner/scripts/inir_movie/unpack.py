"""Dean Edwards' p.a.c.k.e.r. undone as text: the packed script is never run.

A packed page carries `}('<payload>',<radix>,<count>,'<w0>|<w1>|...'.split('|')`; every word token in the payload
is a number in that radix naming its replacement in the list (an empty slot keeps the token).
"""

import re

PACKED = re.compile(r"}\('(.*)',\s*(\d+),\s*(\d+),\s*'(.*?)'\.split\('\|'\)", re.S)
DIGITS = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"


def _number(token, radix):
    value = 0
    for char in token:
        at = DIGITS.find(char)
        if at < 0 or at >= radix:
            return -1
        value = value * radix + at
    return value


def unpack(page):
    """Every packed script in page, unpacked and joined; "" when there is none."""
    out = []
    for payload, radix, count, words in PACKED.findall(page):
        radix, words = int(radix), words.split("|")
        if not 2 <= radix <= len(DIGITS):
            continue
        payload = payload.replace("\\'", "'").replace("\\\\", "\\")

        def swap(match):
            at = _number(match.group(0), radix)
            return words[at] if 0 <= at < len(words) and words[at] else match.group(0)

        out.append(re.sub(r"\b\w+\b", swap, payload))
    return "\n".join(out)

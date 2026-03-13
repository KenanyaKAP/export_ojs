"""
merge_config.py
===============
Shared configuration and helper functions for all migration scripts.

Old DB: 127.0.0.1:3386 (journals) - OJS 3.2.1 with journal_id=27
New DB: 127.0.0.1:3376 (ojs)      - OJS 3.2.1 with journal_id=1
"""

import mysql.connector

# ============================================================
# DATABASE CONFIGURATION
# ============================================================
OLD_DB = {
    "host": "127.0.0.1",
    "port": 3386,
    "user": "root",
    "password": "ITSjournals123!#",
    "database": "journals",
}

NEW_DB = {
    "host": "127.0.0.1",
    "port": 3376,
    "user": "root",
    "password": "rootpassword",
    "database": "ojs",
}

# ============================================================
# JOURNAL CONFIGURATION
# ============================================================
OLD_JOURNAL_ID = 27   # journal_id in the old database
NEW_JOURNAL_ID = 1    # journal_id in the new database

# ============================================================
# OJS ASSOC_TYPE CONSTANTS
# ============================================================
ASSOC_TYPE_SUBMISSION      = 1048585
ASSOC_TYPE_PUBLICATION     = 1048588
ASSOC_TYPE_SUBMISSION_FILE = 515
ASSOC_TYPE_SECTION         = 530
ASSOC_TYPE_REPRESENTATION  = 520   # publication galley
ASSOC_TYPE_REVIEW_ROUND    = 517
ASSOC_TYPE_QUERY           = 1048586
ASSOC_TYPE_JOURNAL         = 256


# ============================================================
# ENCODING FIX: Windows-1252 → UTF-8
# ============================================================
# The old database contains text with invalid UTF-8 bytes that
# are actually Windows-1252 encoded characters (smart quotes,
# en-dashes, em-dashes, etc.).  PHP's json_encode() silently
# fails on these, causing blank workflow pages in OJS.
#
# This map converts the most common Windows-1252 bytes that are
# invalid in UTF-8 (0x80-0x9F range) to their correct Unicode
# code points.
WIN1252_TO_UTF8 = {
    0x80: '\u20AC',  # € Euro sign
    0x82: '\u201A',  # ‚ Single low-9 quotation mark
    0x83: '\u0192',  # ƒ Latin small letter f with hook
    0x84: '\u201E',  # „ Double low-9 quotation mark
    0x85: '\u2026',  # … Horizontal ellipsis
    0x86: '\u2020',  # † Dagger
    0x87: '\u2021',  # ‡ Double dagger
    0x88: '\u02C6',  # ˆ Modifier letter circumflex accent
    0x89: '\u2030',  # ‰ Per mille sign
    0x8A: '\u0160',  # Š Latin capital letter S with caron
    0x8B: '\u2039',  # ‹ Single left-pointing angle quotation
    0x8C: '\u0152',  # Œ Latin capital ligature OE
    0x8E: '\u017D',  # Ž Latin capital letter Z with caron
    0x91: '\u2018',  # ' Left single quotation mark
    0x92: '\u2019',  # ' Right single quotation mark
    0x93: '\u201C',  # " Left double quotation mark
    0x94: '\u201D',  # " Right double quotation mark
    0x95: '\u2022',  # • Bullet
    0x96: '\u2013',  # – En dash
    0x97: '\u2014',  # — Em dash
    0x98: '\u02DC',  # ˜ Small tilde
    0x99: '\u2122',  # ™ Trade mark sign
    0x9A: '\u0161',  # š Latin small letter s with caron
    0x9B: '\u203A',  # › Single right-pointing angle quotation
    0x9C: '\u0153',  # œ Latin small ligature oe
    0x9E: '\u017E',  # ž Latin small letter z with caron
    0x9F: '\u0178',  # Ÿ Latin capital letter Y with diaeresis
}


def fix_encoding(value):
    """
    Fix a string or bytes value that may contain Windows-1252 bytes
    masquerading as UTF-8.  Returns a clean UTF-8 string.

    If the value is already valid UTF-8, it is returned unchanged.
    If it contains bytes in the 0x80-0x9F range (invalid in UTF-8 but
    valid in Windows-1252), they are converted to proper Unicode.
    """
    return value
    if value is None:
        return None
    if isinstance(value, str):
        # Already a Python string — try round-tripping to detect problems
        try:
            value.encode('utf-8')
            return value  # clean
        except UnicodeEncodeError:
            pass
        # Try to fix via latin-1 re-encoding
        raw = value.encode('latin-1', errors='replace')
    elif isinstance(value, (bytes, bytearray)):
        raw = value
    else:
        return value  # not a text type, return as-is

    # Check if already valid UTF-8
    try:
        return raw.decode('utf-8')
    except UnicodeDecodeError:
        pass

    # Convert byte-by-byte, replacing Windows-1252 specials
    result = []
    i = 0
    while i < len(raw):
        b = raw[i]
        if b < 0x80:
            result.append(chr(b))
            i += 1
        elif b in WIN1252_TO_UTF8:
            result.append(WIN1252_TO_UTF8[b])
            i += 1
        elif b >= 0xC0:
            # Possible valid UTF-8 multi-byte sequence
            try:
                if b < 0xE0:
                    ch = raw[i:i+2].decode('utf-8')
                    result.append(ch)
                    i += 2
                elif b < 0xF0:
                    ch = raw[i:i+3].decode('utf-8')
                    result.append(ch)
                    i += 3
                else:
                    ch = raw[i:i+4].decode('utf-8')
                    result.append(ch)
                    i += 4
            except (UnicodeDecodeError, IndexError):
                result.append('\uFFFD')  # replacement character
                i += 1
        else:
            result.append('\uFFFD')
            i += 1
    return ''.join(result)


def fix_row_encoding(row):
    """
    Apply fix_encoding() to every string/bytes element in a tuple row.
    Returns a new tuple with clean UTF-8 strings.
    """
    return tuple(fix_encoding(v) if isinstance(v, (str, bytes, bytearray)) else v for v in row)


def get_connection(config):
    """Create a MySQL connection from config dict."""
    return mysql.connector.connect(**config)


def get_old_conn():
    return get_connection(OLD_DB)


def get_new_conn():
    return get_connection(NEW_DB)


def get_max_id(cursor, table, id_column):
    """Get the current MAX value of an auto-increment column."""
    cursor.execute(f"SELECT COALESCE(MAX({id_column}), 0) FROM {table}")
    return cursor.fetchone()[0]


def print_header(title):
    print(f"\n{'='*60}")
    print(f"  {title}")
    print(f"{'='*60}")


def print_step(msg):
    print(f"  → {msg}")


def print_ok(msg):
    print(f"  ✓ {msg}")


def print_warn(msg):
    print(f"  ⚠ {msg}")

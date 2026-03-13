"""
Step 6c: convert_charset.py
============================
Safely convert the OJS database from latin1 to utf8mb4 so that
`connection_charset = utf8` in config.inc.php works without mojibake
AND without breaking json_encode().

THE PROBLEM:
  The database has MIXED byte content in latin1 columns:

  A) OLD data (pre-migration): contains proper UTF-8 multi-byte sequences
     stored inside latin1 columns.  For example, a right single quote is
     stored as 3 bytes: E2 80 99 (valid UTF-8 for U+2019).

  B) MIGRATED data (from the old journal): contains raw Windows-1252
     single bytes.  For example, an en-dash is stored as 1 byte: 96
     (Windows-1252 for U+2013).  This byte is NOT valid UTF-8.

  If we just convert the column charset to utf8mb4 (the old step6c),
  type A data works perfectly, but type B data (0x96 etc.) becomes
  invalid UTF-8 and breaks PHP's json_encode().

THE FIX (two phases):
  Phase 1 — NORMALIZE BYTES:
    Connect with charset=latin1 so Python sees raw bytes as latin1 chars.
    For each text column, read every row, decode the raw bytes
    intelligently: try UTF-8 first (preserves multi-byte sequences),
    and for any byte that fails, map it from Windows-1252 to the correct
    Unicode character, then re-encode to UTF-8 and write back.

    After this, ALL bytes in the column are valid UTF-8.

  Phase 2 — CONVERT COLUMN CHARSET:
    ALTER each column: text → binary → text utf8mb4.
    Since all bytes are now valid UTF-8, this is safe.

RUN ORDER:
  Run this AFTER step6b (fix_encoding) and BEFORE step7 (verify).

Usage:
    python step6c_convert_charset.py            # dry-run (list columns)
    python step6c_convert_charset.py --apply    # actually convert
"""

import argparse
import sys
import mysql.connector

from merge_config import (
    NEW_DB, print_header, print_step, print_ok, print_warn,
)

# ============================================================
# Windows-1252 byte → correct Unicode character
# Only bytes 0x80-0x9F differ between latin1 and Windows-1252.
# ============================================================
WIN1252_MAP = {
    0x80: '\u20AC',  # € Euro sign
    0x81: '',        # undefined
    0x82: '\u201A',  # ‚ Single low-9 quotation mark
    0x83: '\u0192',  # ƒ Latin small f with hook
    0x84: '\u201E',  # „ Double low-9 quotation mark
    0x85: '\u2026',  # … Horizontal ellipsis
    0x86: '\u2020',  # † Dagger
    0x87: '\u2021',  # ‡ Double dagger
    0x88: '\u02C6',  # ˆ Modifier letter circumflex accent
    0x89: '\u2030',  # ‰ Per mille sign
    0x8A: '\u0160',  # Š Latin capital S with caron
    0x8B: '\u2039',  # ‹ Single left-pointing angle quotation
    0x8C: '\u0152',  # Œ Latin capital ligature OE
    0x8D: '',        # undefined
    0x8E: '\u017D',  # Ž Latin capital Z with caron
    0x8F: '',        # undefined
    0x90: '',        # undefined
    0x91: '\u2018',  # ' Left single quotation mark
    0x92: '\u2019',  # ' Right single quotation mark
    0x93: '\u201C',  # " Left double quotation mark
    0x94: '\u201D',  # " Right double quotation mark
    0x95: '\u2022',  # • Bullet
    0x96: '\u2013',  # – En dash
    0x97: '\u2014',  # — Em dash
    0x98: '\u02DC',  # ˜ Small tilde
    0x99: '\u2122',  # ™ Trade mark sign
    0x9A: '\u0161',  # š Latin small s with caron
    0x9B: '\u203A',  # › Single right-pointing angle quotation
    0x9C: '\u0153',  # œ Latin small ligature oe
    0x9D: '\u201D',  # " (undefined, most commonly right double quote)
    0x9E: '\u017E',  # ž Latin small z with caron
    0x9F: '\u0178',  # Ÿ Latin capital Y with diaeresis
}

TARGET_CHARSET = 'utf8mb4'
TARGET_COLLATION = 'utf8mb4_unicode_ci'

BLOB_MAP = {
    'char':       'VARBINARY',
    'varchar':    'VARBINARY',
    'text':       'BLOB',
    'mediumtext': 'MEDIUMBLOB',
    'longtext':   'LONGBLOB',
}

# ============================================================
# Tables and text columns that contain user/content data and
# may have mixed encoding.  We process these in Phase 1.
# System/structural columns (like setting_name, locale, etc.)
# contain only ASCII and are safe to skip in Phase 1.
# ============================================================
CONTENT_COLUMNS = [
    # Main content tables
    ('publication_settings',              'setting_value'),
    ('author_settings',                   'setting_value'),
    ('citations',                         'raw_citation'),
    ('submission_comments',               'comments'),
    ('submission_comments',               'comment_title'),
    ('submission_file_settings',          'setting_value'),
    ('submission_files',                  'original_file_name'),
    ('controlled_vocab_entry_settings',   'setting_value'),
    ('section_settings',                  'setting_value'),
    ('submission_settings',               'setting_value'),

    # User data
    ('user_settings',                     'setting_value'),
    ('users',                             'gossip'),

    # Review data
    ('review_form_responses',             'response_value'),
    ('review_form_settings',              'setting_value'),
    ('review_form_element_settings',      'setting_value'),
    ('review_assignments',                'competing_interests'),

    # Log and notification tables
    ('notes',                             'title'),
    ('notes',                             'contents'),
    ('email_log',                         'subject'),
    ('email_log',                         'body'),
    ('email_log',                         'recipients'),
    ('email_log',                         'cc_recipients'),
    ('email_log',                         'bcc_recipients'),
    ('event_log',                         'message'),
    ('event_log_settings',                'setting_value'),

    # System/template tables
    ('email_templates_default_data',      'subject'),
    ('email_templates_default_data',      'body'),
    ('email_templates_default_data',      'description'),
    ('journal_settings',                  'setting_value'),
    ('plugin_settings',                   'setting_value'),
    ('site_settings',                     'setting_value'),
    ('static_page_settings',              'setting_value'),

    # Navigation
    ('navigation_menu_item_settings',     'setting_value'),

    # Search index
    ('submission_search_keyword_list',    'keyword_text'),

    # Issue data
    ('issue_settings',                    'setting_value'),

    # Galleys
    ('publication_galley_settings',       'setting_value'),
]


# ============================================================
# Helper functions
# ============================================================

def get_latin1_conn():
    """Connect with charset=latin1 so we see raw bytes (no transcoding)."""
    cfg = dict(NEW_DB)
    cfg['charset'] = 'latin1'
    return mysql.connector.connect(**cfg)


def get_conn():
    """Normal connection for schema operations."""
    return mysql.connector.connect(**NEW_DB)


def fix_mixed_bytes(raw_bytes):
    """
    Take raw bytes from a latin1 column and produce a clean UTF-8 string.

    Strategy: walk byte by byte.  Try to decode UTF-8 multi-byte sequences
    where possible (preserving existing valid UTF-8).  For lone bytes in
    the 0x80-0x9F range (Windows-1252 specials), map them to Unicode.
    For bytes 0xA0-0xFF (valid latin1 = valid Unicode), keep them.
    """
    if not raw_bytes:
        return raw_bytes

    result = []
    i = 0
    n = len(raw_bytes)

    while i < n:
        b = raw_bytes[i]

        # ASCII: pass through
        if b < 0x80:
            result.append(chr(b))
            i += 1
            continue

        # Try UTF-8 multi-byte sequence
        if b >= 0xC2:  # valid UTF-8 lead bytes start at C2
            seq_len = 0
            if 0xC2 <= b <= 0xDF:
                seq_len = 2
            elif 0xE0 <= b <= 0xEF:
                seq_len = 3
            elif 0xF0 <= b <= 0xF4:
                seq_len = 4

            if seq_len > 0 and i + seq_len <= n:
                chunk = raw_bytes[i:i + seq_len]
                try:
                    decoded = chunk.decode('utf-8')
                    result.append(decoded)
                    i += seq_len
                    continue
                except UnicodeDecodeError:
                    pass  # fall through to single-byte handling

        # Single byte in 0x80-0x9F: Windows-1252 special
        if 0x80 <= b <= 0x9F:
            result.append(WIN1252_MAP.get(b, ''))
            i += 1
            continue

        # Byte 0xA0-0xFF: latin1 = Unicode code point (e.g. ñ = 0xF1)
        result.append(chr(b))
        i += 1

    return ''.join(result)


def table_exists(cur, table):
    """Check if a table exists."""
    try:
        cur.execute("SELECT 1 FROM `{}` LIMIT 1".format(table))
        cur.fetchall()
        return True
    except Exception:
        return False


def get_primary_key(cur, db, table):
    """Get the primary key, first unique key, or first index columns for a table."""
    cur.execute("SHOW INDEX FROM `{}`".format(table))
    index_rows = cur.fetchall()

    # Group columns by index name, separating unique from non-unique
    unique_indexes = {}
    other_indexes = {}
    for r in index_rows:
        idx_name = r[2]
        non_unique = r[1]
        col_name = r[4]
        seq = r[3]
        target = other_indexes if non_unique else unique_indexes
        target.setdefault(idx_name, []).append((seq, col_name))

    # Prefer PRIMARY, then any unique, then any non-unique index
    if 'PRIMARY' in unique_indexes:
        chosen = unique_indexes['PRIMARY']
    elif unique_indexes:
        chosen = list(unique_indexes.values())[0]
    elif other_indexes:
        chosen = list(other_indexes.values())[0]
    else:
        return []

    chosen.sort()
    return [col for _, col in chosen]


def list_latin1_columns(conn, db):
    """Find all text-like columns still declared as latin1."""
    cur = conn.cursor(dictionary=True)
    cur.execute("""
        SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE, COLUMN_TYPE,
               CHARACTER_MAXIMUM_LENGTH, IS_NULLABLE, COLUMN_DEFAULT
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = %s
          AND CHARACTER_SET_NAME = 'latin1'
          AND DATA_TYPE IN ('char','varchar','text','mediumtext','longtext')
        ORDER BY TABLE_NAME, COLUMN_NAME
    """, (db,))
    rows = cur.fetchall()
    cur.close()
    return rows


def blob_type_for(col):
    """Return the matching BINARY/BLOB type for a text column."""
    dt = col['DATA_TYPE'].lower()
    if dt in ('char', 'varchar'):
        length = col['CHARACTER_MAXIMUM_LENGTH'] or 255
        return "VARBINARY({})".format(length)
    return BLOB_MAP.get(dt, 'BLOB')


def text_type_for(col):
    """Return the target TEXT type with utf8mb4 charset."""
    dt = col['DATA_TYPE'].lower()
    if dt in ('char', 'varchar'):
        length = col['CHARACTER_MAXIMUM_LENGTH'] or 255
        return "{typ}({len}) CHARACTER SET {cs} COLLATE {co}".format(
            typ=dt.upper(), len=length,
            cs=TARGET_CHARSET, co=TARGET_COLLATION,
        )
    return "{typ} CHARACTER SET {cs} COLLATE {co}".format(
        typ=dt.upper(), cs=TARGET_CHARSET, co=TARGET_COLLATION,
    )


def nullable_clause(col):
    """Build the NULL/NOT NULL + DEFAULT portion of a MODIFY statement."""
    parts = []
    if col['IS_NULLABLE'] == 'NO':
        parts.append('NOT NULL')
    else:
        parts.append('NULL')
    if col['COLUMN_DEFAULT'] is not None:
        escaped = str(col['COLUMN_DEFAULT']).replace("'", "''")
        parts.append("DEFAULT '{}'".format(escaped))
    return ' '.join(parts)


# ============================================================
# Phase 1: Normalize mixed bytes to valid UTF-8
# ============================================================

def phase1_normalize(dry_run=False):
    """
    Read raw bytes via latin1 connection, fix any Windows-1252 single
    bytes to proper UTF-8 multi-byte sequences, write back.
    """
    print_header("PHASE 1: NORMALIZE MIXED BYTES TO VALID UTF-8")

    conn = get_latin1_conn()
    db = NEW_DB['database']
    cur = conn.cursor()

    total_fixed = 0

    for table, column in CONTENT_COLUMNS:
        if not table_exists(cur, table):
            continue

        pk_cols = get_primary_key(cur, db, table)
        if not pk_cols:
            print_warn("  Skipping {}.{} — no primary key".format(table, column))
            continue

        pk_select = ', '.join('`{}`'.format(c) for c in pk_cols)

        # Find rows with bytes in 0x80-0x9F range
        # We read ALL rows with any high byte and let Python decide
        # which ones actually need fixing.
        cur.execute(
            "SELECT {pk}, `{col}` FROM `{tbl}` "
            "WHERE `{col}` IS NOT NULL AND `{col}` != ''".format(
                pk=pk_select, col=column, tbl=table,
            )
        )
        rows = cur.fetchall()

        fixed_in_table = 0
        for row in rows:
            pk_values = row[:len(pk_cols)]
            raw_value = row[len(pk_cols)]

            if raw_value is None:
                continue

            # Get the raw bytes
            if isinstance(raw_value, str):
                raw_bytes = raw_value.encode('latin-1', errors='surrogateescape')
            elif isinstance(raw_value, (bytes, bytearray)):
                raw_bytes = bytes(raw_value)
            else:
                continue

            # Skip if all ASCII (no high bytes at all)
            if all(b < 0x80 for b in raw_bytes):
                continue

            # Skip if already valid UTF-8
            try:
                raw_bytes.decode('utf-8')
                continue
            except UnicodeDecodeError:
                pass

            # Fix the mixed content
            fixed_str = fix_mixed_bytes(raw_bytes)
            fixed_bytes = fixed_str.encode('utf-8')

            # Don't write if nothing changed
            if fixed_bytes == raw_bytes:
                continue

            if not dry_run:
                # Build WHERE clause from primary key
                where = ' AND '.join(
                    '`{}` = %s'.format(c) for c in pk_cols
                )
                cur.execute(
                    "UPDATE `{tbl}` SET `{col}` = %s WHERE {where}".format(
                        tbl=table, col=column, where=where,
                    ),
                    (fixed_bytes,) + tuple(pk_values),
                )

            fixed_in_table += 1

        if not dry_run and fixed_in_table > 0:
            conn.commit()

        if fixed_in_table > 0:
            total_fixed += fixed_in_table
            print_ok("  {}.{}: {} rows normalized".format(
                table, column, fixed_in_table,
            ))

    cur.close()
    conn.close()

    if total_fixed == 0:
        print_ok("  All content columns already have valid UTF-8 bytes!")
    else:
        action = "would normalize" if dry_run else "normalized"
        print_ok("  TOTAL: {} {} rows".format(action, total_fixed))

    return total_fixed


# ============================================================
# Phase 2: ALTER columns from latin1 to utf8mb4
# ============================================================

def phase2_convert(dry_run=False, limit_table=None):
    """
    Convert all latin1 text columns to utf8mb4 using the safe
    two-step ALTER: text → binary → text utf8mb4.

    For indexed VARCHAR(255) columns where utf8mb4 would exceed the
    1000-byte key limit, we use utf8 (3-byte) instead.
    """
    print_header("PHASE 2: CONVERT COLUMN CHARSET (latin1 -> utf8mb4)")

    conn = get_conn()
    db = NEW_DB['database']

    candidates = list_latin1_columns(conn, db)
    if limit_table:
        candidates = [c for c in candidates if c['TABLE_NAME'] == limit_table]

    if not candidates:
        print_ok("No latin1 text columns found — nothing to convert!")
        conn.close()
        return

    tables = {}
    for c in candidates:
        tables.setdefault(c['TABLE_NAME'], []).append(c)

    print_step("Found {} latin1 columns across {} tables".format(
        len(candidates), len(tables),
    ))

    if dry_run:
        for tbl, cols in sorted(tables.items()):
            col_names = ', '.join(c['COLUMN_NAME'] for c in cols)
            print("    {}: {}".format(tbl, col_names))
        print_warn("\nDRY RUN — no changes made.")
        conn.close()
        return

    # Build a set of (table, column) pairs that are part of an index
    # so we know which ones might hit the key-length limit.
    indexed_cols = set()
    cur = conn.cursor()
    for tbl in tables:
        try:
            cur.execute("SHOW INDEX FROM `{}`".format(tbl))
            for r in cur.fetchall():
                col_name = r[4]
                indexed_cols.add((tbl, col_name))
        except Exception:
            pass

    succeeded = 0
    failed = []

    for col in candidates:
        table = col['TABLE_NAME']
        col_name = col['COLUMN_NAME']
        dt = col['DATA_TYPE'].lower()
        max_len = col['CHARACTER_MAXIMUM_LENGTH'] or 0
        blob = blob_type_for(col)
        null_default = nullable_clause(col)

        # Decide charset: use utf8 (3-byte) for indexed varchar/char
        # columns where utf8mb4 would exceed index key limit (1000 bytes).
        # VARCHAR(255) * 4 bytes/char = 1020 > 1000, but * 3 = 765 OK.
        is_indexed = (table, col_name) in indexed_cols
        if is_indexed and dt in ('char', 'varchar') and max_len * 4 > 1000:
            cs = 'utf8'
            co = 'utf8_unicode_ci'
        else:
            cs = TARGET_CHARSET
            co = TARGET_COLLATION

        if dt in ('char', 'varchar'):
            text = "{typ}({len}) CHARACTER SET {cs} COLLATE {co}".format(
                typ=dt.upper(), len=max_len, cs=cs, co=co,
            )
        else:
            text = "{typ} CHARACTER SET {cs} COLLATE {co}".format(
                typ=dt.upper(), cs=cs, co=co,
            )

        try:
            # Step 1: text → binary
            cur.execute("ALTER TABLE `{}` MODIFY `{}` {} {}".format(
                table, col_name, blob, null_default,
            ))
            conn.commit()

            # Step 2: binary → text utf8(mb4)
            cur.execute("ALTER TABLE `{}` MODIFY `{}` {} {}".format(
                table, col_name, text, null_default,
            ))
            conn.commit()

            suffix = " (utf8 3-byte, indexed)" if cs == 'utf8' else ""
            print_ok("  {}.{} -> {}{}".format(table, col_name, cs, suffix))
            succeeded += 1
        except Exception as e:
            conn.rollback()
            print_warn("  FAILED {}.{}: {}".format(table, col_name, e))
            failed.append((table, col_name, str(e)))

    cur.close()

    # Verify
    remaining = list_latin1_columns(conn, db)
    if limit_table:
        remaining = [c for c in remaining if c['TABLE_NAME'] == limit_table]
    conn.close()

    print_step("\n" + "=" * 60)
    print_ok("Converted: {} columns".format(succeeded))
    if failed:
        print_warn("Failed: {} columns".format(len(failed)))
        for t, c, e in failed:
            print_warn("  {}.{}: {}".format(t, c, e))
    if remaining:
        print_warn("Still latin1: {} columns".format(len(remaining)))
    else:
        print_ok("All text columns are now utf8/utf8mb4!")

    return succeeded


# ============================================================
# Main
# ============================================================

def main():
    parser = argparse.ArgumentParser(
        description="Fix mixed encoding and convert OJS columns to utf8mb4",
    )
    parser.add_argument(
        '--apply', action='store_true',
        help='Actually make changes (default is dry-run)',
    )
    parser.add_argument(
        '--table', type=str, default=None,
        help='Limit Phase 2 to a single table (for testing)',
    )
    parser.add_argument(
        '--phase', type=int, default=0,
        help='Run only phase 1 or 2 (default: both)',
    )
    args = parser.parse_args()

    dry_run = not args.apply

    if dry_run:
        print_header("STEP 6c: CONVERT CHARSET (DRY RUN)")
        print_warn("No changes will be made. Re-run with --apply to execute.")
        print_warn("ALWAYS take a DB backup first!\n")
    else:
        print_header("STEP 6c: CONVERT CHARSET")

    # Phase 1: normalize mixed bytes
    if args.phase in (0, 1):
        phase1_normalize(dry_run=dry_run)

    # Phase 2: ALTER columns to utf8mb4
    if args.phase in (0, 2):
        phase2_convert(dry_run=dry_run, limit_table=args.table)

    print_step("\n" + "=" * 60)
    if dry_run:
        print_warn("DRY RUN complete. Run with --apply to execute.")
    else:
        print_ok("Step 6c complete!")
        print_ok("Set connection_charset = utf8 in OJS config.inc.php")
        print_ok("Then restart: docker restart <app-container>")


if __name__ == '__main__':
    main()

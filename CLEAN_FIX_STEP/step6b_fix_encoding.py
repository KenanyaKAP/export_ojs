"""
Step 6b: fix_encoding.py
========================
Post-migration fixes for the new OJS database:

1. **Fix empty locales** (PRIMARY) — Keywords/subjects/agencies migrated
   with locale='' (empty string) which causes PHP "Invalid argument
   supplied for foreach()" warnings in SubmissionKeywordDAO.inc.php.
   Sets the locale to the journal's primary_locale.

2. **Fix raw Windows-1252 bytes** (DEFENSIVE) — Replaces raw 0x80-0x9F
   bytes (smart quotes, en-dash, em-dash, etc.) with their correct UTF-8
   Unicode equivalents using MySQL native REPLACE().

   NOTE ON ENCODING: The PRIMARY fix for blank workflow pages caused by
   "Malformed UTF-8 characters" in json_encode() is to add this line
   to OJS's config.inc.php under [database]:

       connection_charset = utf8

   Without this, PHP's MySQL connection defaults to latin1 and serves
   raw bytes to json_encode(), which rejects them.  The SQL REPLACE
   here is a "belt and suspenders" measure — it converts the raw bytes
   in the database itself so they survive regardless of connection
   charset settings.

   IMPORTANT: Python's mysql.connector with charset='utf8mb4' silently
   drops these invalid bytes when reading, so a Python-level string fix
   never sees them.  This is why we use raw MySQL REPLACE().

Run this AFTER steps 1-6 and BEFORE step 7 (verify).

Usage:
    python step6b_fix_encoding.py
"""

import mysql.connector
import sys

from merge_config import (
    get_new_conn, print_header, print_step, print_ok, print_warn,
)

# ============================================================
# Windows-1252 byte -> correct Unicode character
# Each entry: raw_byte_value -> Unicode replacement string
# ============================================================
WIN1252_REPLACEMENTS = {
    0x80: '\u20AC',  # Euro sign
    0x81: '',        # undefined -> remove
    0x82: '\u201A',  # Single low-9 quotation mark
    0x83: '\u0192',  # Latin small f with hook
    0x84: '\u201E',  # Double low-9 quotation mark
    0x85: '\u2026',  # Horizontal ellipsis
    0x86: '\u2020',  # Dagger
    0x87: '\u2021',  # Double dagger
    0x88: '\u02C6',  # Modifier letter circumflex accent
    0x89: '\u2030',  # Per mille sign
    0x8A: '\u0160',  # Latin capital S with caron
    0x8B: '\u2039',  # Single left-pointing angle quotation
    0x8C: '\u0152',  # Latin capital ligature OE
    0x8D: '',        # undefined -> remove
    0x8E: '\u017D',  # Latin capital Z with caron
    0x8F: '',        # undefined -> remove
    0x90: '',        # undefined -> remove
    0x91: '\u2018',  # Left single quotation mark
    0x92: '\u2019',  # Right single quotation mark
    0x93: '\u201C',  # Left double quotation mark
    0x94: '\u201D',  # Right double quotation mark
    0x95: '\u2022',  # Bullet
    0x96: '\u2013',  # En dash
    0x97: '\u2014',  # Em dash
    0x98: '\u02DC',  # Small tilde
    0x99: '\u2122',  # Trade mark sign
    0x9A: '\u0161',  # Latin small s with caron
    0x9B: '\u203A',  # Single right-pointing angle quotation
    0x9C: '\u0153',  # Latin small ligature oe
    0x9D: '\u201D',  # (undefined, most commonly right double quote)
    0x9E: '\u017E',  # Latin small z with caron
    0x9F: '\u0178',  # Latin capital Y with diaeresis
}


def build_replace_chain(column):
    """
    Build a nested MySQL REPLACE() expression that replaces each bad byte
    with its correct UTF-8 equivalent.

    Returns: (sql_expression, list_of_params)
    """
    expr = column
    params = []

    for byte_val, unicode_char in WIN1252_REPLACEMENTS.items():
        expr = f"REPLACE({expr}, UNHEX('{byte_val:02X}'), %s)"
        params.append(unicode_char)

    return expr, params


def fix_table_column(conn, table, column):
    """
    Fix a single text column in a table by replacing raw 0x80-0x9F bytes.
    Uses MySQL's REPLACE() at the binary level.

    Returns: number of rows affected
    """
    cur = conn.cursor()

    # Count affected rows
    count_query = f"""
        SELECT COUNT(*) FROM `{table}`
        WHERE CAST(`{column}` AS BINARY)
              REGEXP CONCAT('[', UNHEX('80'), '-', UNHEX('9F'), ']')
    """
    cur.execute(count_query)
    count = cur.fetchone()[0]

    if count == 0:
        cur.close()
        return 0

    # Build the nested REPLACE chain
    replace_expr, params = build_replace_chain(f"`{column}`")

    update_query = f"""
        UPDATE `{table}` SET `{column}` = {replace_expr}
        WHERE CAST(`{column}` AS BINARY)
              REGEXP CONCAT('[', UNHEX('80'), '-', UNHEX('9F'), ']')
    """
    cur.execute(update_query, params)
    affected = cur.rowcount
    conn.commit()
    cur.close()

    return affected


def table_exists(conn, table):
    """Check if a table exists in the database."""
    cur = conn.cursor()
    try:
        cur.execute(f"SELECT 1 FROM `{table}` LIMIT 1")
        cur.fetchall()
        cur.close()
        return True
    except Exception:
        cur.close()
        return False


def main():
    print_header("STEP 6b: FIX ENCODING & LOCALES")

    conn = get_new_conn()

    # ── Part 1: Fix empty locales in controlled_vocab_entry_settings ──
    # Keywords/subjects/agencies migrated with locale='' (empty string)
    # which causes "Invalid argument supplied for foreach()" in PHP.
    print_step("Part 1: Fixing empty locales in controlled_vocab_entry_settings...")
    cur = conn.cursor()

    # Get the journal's primary locale
    cur.execute("SELECT primary_locale FROM journals LIMIT 1")
    row = cur.fetchone()
    primary_locale = row[0] if row else 'en_US'

    cur.execute("""
        UPDATE controlled_vocab_entry_settings
        SET locale = %s
        WHERE locale = '' AND setting_value IS NOT NULL AND setting_value != ''
    """, (primary_locale,))
    locale_fixed = cur.rowcount
    conn.commit()
    cur.close()

    if locale_fixed > 0:
        print_ok(f"  Set locale to '{primary_locale}' on {locale_fixed} entries")
    else:
        print_ok("  No empty locales found")

    # ── Part 2: Fix raw Windows-1252 bytes (defensive) ──────────────
    # This is a "belt and suspenders" fix. The primary fix for blank
    # workflow pages is connection_charset = utf8 in OJS config.inc.php.
    # This SQL REPLACE converts raw bytes in the DB itself as extra safety.
    print_step("\nPart 2: Fixing raw Windows-1252 bytes (defensive)...")

    # All tables and text columns to fix.
    tables_columns = [
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

        # User data
        ('user_settings',                     'setting_value'),

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
        ('event_log_settings',               'setting_value'),

        # System/template tables
        ('email_templates_default_data',      'subject'),
        ('email_templates_default_data',      'body'),
        ('email_templates_default_data',      'description'),
        ('journal_settings',                  'setting_value'),
        ('plugin_settings',                   'setting_value'),
        ('site_settings',                     'setting_value'),
        ('static_page_settings',              'setting_value'),

        # Search index
        ('submission_search_keyword_list',    'keyword_text'),

        # RT (Reading Tools) tables
        ('rt_searches',                       'description'),
        ('rt_searches',                       'url'),
    ]

    total_fixed = 0

    for table, column in tables_columns:
        if not table_exists(conn, table):
            continue

        affected = fix_table_column(conn, table, column)
        if affected > 0:
            print_ok(f"  {table}.{column}: fixed {affected} rows")
            total_fixed += affected

    # ── Verify: scan for any remaining bad bytes ────────────────────
    print_step("\nVerifying: scanning for remaining bad bytes...")

    remaining = 0
    for table, column in tables_columns:
        if not table_exists(conn, table):
            continue
        cur = conn.cursor()
        try:
            cur.execute(f"""
                SELECT COUNT(*) FROM `{table}`
                WHERE CAST(`{column}` AS BINARY)
                      REGEXP CONCAT('[', UNHEX('80'), '-', UNHEX('9F'), ']')
            """)
            count = cur.fetchone()[0]
            if count > 0:
                print_warn(f"  STILL BAD: {table}.{column}: {count} rows")
                remaining += count
        except Exception:
            pass
        cur.close()

    if remaining == 0:
        print_ok("  All targeted columns are clean!")
    else:
        print_warn(f"  {remaining} rows still have bad bytes")

    # ── Summary ─────────────────────────────────────────────────────
    print_step(f"\n{'='*60}")
    if locale_fixed > 0:
        print_ok(f"Part 1: Fixed {locale_fixed} rows with empty locale")
    else:
        print_ok("Part 1: No empty locales found")
    print_ok(f"Part 2: Fixed {total_fixed} rows with bad encoding bytes (defensive)")
    print_ok("Step 6b complete!")

    conn.close()


if __name__ == '__main__':
    main()

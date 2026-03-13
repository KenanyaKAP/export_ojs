"""
remap_submission_ids.py
========================
Remaps the 40 imported submission_ids from old DB (4244-8827) to sequential
IDs starting from 526 (next after the new DB's last ID of 525).

Also remaps the corresponding publication_ids to be sequential starting from
the next available ID.

Target: 127.0.0.1:3376, root / rootpassword, dbname: ojs
"""

import mysql.connector
from mysql.connector import Error

# ============================================================
# CONFIGURATION
# ============================================================
DB_CONFIG = {
    "host": "127.0.0.1",
    "port": 3376,
    "user": "root",
    "password": "rootpassword",
    "database": "ojs",
}

NEW_SUBMISSION_START = 526  # First new submission_id for old data
# ============================================================


def get_connection():
    return mysql.connector.connect(**DB_CONFIG)


def build_mapping(cursor):
    """Build old→new mapping for submission_id and publication_id."""

    # Get old submission IDs in order
    cursor.execute(
        "SELECT submission_id FROM submissions "
        "WHERE submission_id >= 4244 ORDER BY submission_id"
    )
    old_sub_ids = [row[0] for row in cursor.fetchall()]

    # Build submission_id mapping: old → new sequential
    sub_map = {}
    for i, old_id in enumerate(old_sub_ids):
        sub_map[old_id] = NEW_SUBMISSION_START + i

    # Get max publication_id from new data
    cursor.execute(
        "SELECT MAX(publication_id) FROM publications WHERE submission_id < 4244"
    )
    max_new_pub = cursor.fetchone()[0] or 0
    new_pub_start = max_new_pub + 1

    # Get old publication IDs in order (1 per submission)
    cursor.execute(
        "SELECT publication_id, submission_id FROM publications "
        "WHERE submission_id >= 4244 ORDER BY publication_id"
    )
    old_pubs = cursor.fetchall()

    pub_map = {}
    for i, (old_pub_id, _) in enumerate(old_pubs):
        pub_map[old_pub_id] = new_pub_start + i

    return sub_map, pub_map


def remap_ids(cursor, table, column, id_map, extra_where=""):
    """Update a column in a table using the given mapping."""
    updated = 0
    for old_id, new_id in id_map.items():
        where_clause = f"WHERE `{column}` = %s"
        if extra_where:
            where_clause += f" AND {extra_where}"
        sql = f"UPDATE `{table}` SET `{column}` = %s {where_clause}"
        cursor.execute(sql, (new_id, old_id))
        updated += cursor.rowcount
    return updated


def main():
    print("=" * 70)
    print("OJS Submission ID Remapping")
    print("=" * 70)

    conn = get_connection()
    cursor = conn.cursor()

    try:
        cursor.execute("SET FOREIGN_KEY_CHECKS = 0")
        cursor.execute("SET SQL_SAFE_UPDATES = 0")

        # ── Build mappings ──
        print("\n[1/5] Building ID mappings...")
        sub_map, pub_map = build_mapping(cursor)

        print(f"  Submission mapping: {len(sub_map)} entries")
        print(f"    {list(sub_map.items())[0]}  ...  {list(sub_map.items())[-1]}")
        print(f"  Publication mapping: {len(pub_map)} entries")
        print(f"    {list(pub_map.items())[0]}  ...  {list(pub_map.items())[-1]}")

        # ── Use temporary offset to avoid PK collisions ──
        # Since we're remapping IDs within the same table, we first shift all
        # old IDs to a temporary range (+ 1,000,000), then shift to final values.
        OFFSET = 1_000_000

        # ────────────────────────────────────────────────
        # PHASE 2: REMAP SUBMISSION_IDs
        # ────────────────────────────────────────────────
        print("\n[2/5] Remapping submission_ids (phase 1: shift to temp range)...")

        sub_tables = [
            ("submissions", "submission_id"),
            ("publications", "submission_id"),
            ("edit_decisions", "submission_id"),
            ("review_assignments", "submission_id"),
            ("review_rounds", "submission_id"),
            ("review_round_files", "submission_id"),
            ("stage_assignments", "submission_id"),
            ("submission_files", "submission_id"),
        ]

        # Also update submissions.current_publication_id (references publication_id)
        # And event_log/email_log assoc_id (polymorphic → submission_id)

        # Phase 1: old → temp (old + OFFSET)
        for table, col in sub_tables:
            for old_id in sub_map:
                temp_id = old_id + OFFSET
                cursor.execute(
                    f"UPDATE `{table}` SET `{col}` = %s WHERE `{col}` = %s",
                    (temp_id, old_id),
                )

        # event_log: assoc_type = 1048585 (SUBMISSION), assoc_id = submission_id
        for old_id in sub_map:
            temp_id = old_id + OFFSET
            cursor.execute(
                "UPDATE event_log SET assoc_id = %s "
                "WHERE assoc_type = 1048585 AND assoc_id = %s",
                (temp_id, old_id),
            )

        # email_log: assoc_type = 1048585 (SUBMISSION), assoc_id = submission_id
        for old_id in sub_map:
            temp_id = old_id + OFFSET
            cursor.execute(
                "UPDATE email_log SET assoc_id = %s "
                "WHERE assoc_type = 1048585 AND assoc_id = %s",
                (temp_id, old_id),
            )

        print("  Phase 1 done (shifted to temp range).")

        # Phase 2: temp → final
        print("  Remapping submission_ids (phase 2: temp → final)...")
        for table, col in sub_tables:
            total = 0
            for old_id, new_id in sub_map.items():
                temp_id = old_id + OFFSET
                cursor.execute(
                    f"UPDATE `{table}` SET `{col}` = %s WHERE `{col}` = %s",
                    (new_id, temp_id),
                )
                total += cursor.rowcount
            print(f"    {table}.{col}: {total} rows")

        # event_log final
        total = 0
        for old_id, new_id in sub_map.items():
            temp_id = old_id + OFFSET
            cursor.execute(
                "UPDATE event_log SET assoc_id = %s "
                "WHERE assoc_type = 1048585 AND assoc_id = %s",
                (new_id, temp_id),
            )
            total += cursor.rowcount
        print(f"    event_log.assoc_id (SUBMISSION): {total} rows")

        # email_log final
        total = 0
        for old_id, new_id in sub_map.items():
            temp_id = old_id + OFFSET
            cursor.execute(
                "UPDATE email_log SET assoc_id = %s "
                "WHERE assoc_type = 1048585 AND assoc_id = %s",
                (new_id, temp_id),
            )
            total += cursor.rowcount
        print(f"    email_log.assoc_id (SUBMISSION): {total} rows")

        # ────────────────────────────────────────────────
        # PHASE 3: REMAP PUBLICATION_IDs
        # ────────────────────────────────────────────────
        print("\n[3/5] Remapping publication_ids...")

        pub_tables = [
            ("publications", "publication_id"),
            ("authors", "publication_id"),
            ("citations", "publication_id"),
            ("publication_settings", "publication_id"),
        ]

        # Also: submissions.current_publication_id
        # Also: controlled_vocabs.assoc_id where assoc_type = 1048588

        # Phase 1: old → temp
        for table, col in pub_tables:
            for old_id in pub_map:
                temp_id = old_id + OFFSET
                cursor.execute(
                    f"UPDATE `{table}` SET `{col}` = %s WHERE `{col}` = %s",
                    (temp_id, old_id),
                )

        # submissions.current_publication_id
        for old_id in pub_map:
            temp_id = old_id + OFFSET
            cursor.execute(
                "UPDATE submissions SET current_publication_id = %s "
                "WHERE current_publication_id = %s",
                (temp_id, old_id),
            )

        # controlled_vocabs (assoc_type 1048588 = PUBLICATION)
        for old_id in pub_map:
            temp_id = old_id + OFFSET
            cursor.execute(
                "UPDATE controlled_vocabs SET assoc_id = %s "
                "WHERE assoc_type = 1048588 AND assoc_id = %s",
                (temp_id, old_id),
            )

        print("  Phase 1 done (shifted to temp range).")

        # Phase 2: temp → final
        for table, col in pub_tables:
            total = 0
            for old_id, new_id in pub_map.items():
                temp_id = old_id + OFFSET
                cursor.execute(
                    f"UPDATE `{table}` SET `{col}` = %s WHERE `{col}` = %s",
                    (new_id, temp_id),
                )
                total += cursor.rowcount
            print(f"    {table}.{col}: {total} rows")

        # submissions.current_publication_id final
        total = 0
        for old_id, new_id in pub_map.items():
            temp_id = old_id + OFFSET
            cursor.execute(
                "UPDATE submissions SET current_publication_id = %s "
                "WHERE current_publication_id = %s",
                (new_id, temp_id),
            )
            total += cursor.rowcount
        print(f"    submissions.current_publication_id: {total} rows")

        # controlled_vocabs final
        total = 0
        for old_id, new_id in pub_map.items():
            temp_id = old_id + OFFSET
            cursor.execute(
                "UPDATE controlled_vocabs SET assoc_id = %s "
                "WHERE assoc_type = 1048588 AND assoc_id = %s",
                (new_id, temp_id),
            )
            total += cursor.rowcount
        print(f"    controlled_vocabs.assoc_id (PUBLICATION): {total} rows")

        # ────────────────────────────────────────────────
        # PHASE 4: RESET AUTO_INCREMENT
        # ────────────────────────────────────────────────
        print("\n[4/5] Resetting AUTO_INCREMENT values...")

        cursor.execute(
            "SELECT MAX(submission_id) FROM submissions"
        )
        max_sub = cursor.fetchone()[0]
        cursor.execute(f"ALTER TABLE submissions AUTO_INCREMENT = {max_sub + 1}")
        print(f"    submissions AUTO_INCREMENT = {max_sub + 1}")

        cursor.execute(
            "SELECT MAX(publication_id) FROM publications"
        )
        max_pub = cursor.fetchone()[0]
        cursor.execute(f"ALTER TABLE publications AUTO_INCREMENT = {max_pub + 1}")
        print(f"    publications AUTO_INCREMENT = {max_pub + 1}")

        # ────────────────────────────────────────────────
        # PHASE 5: VERIFY
        # ────────────────────────────────────────────────
        print("\n[5/5] Verifying...")

        cursor.execute(
            "SELECT MIN(submission_id), MAX(submission_id), COUNT(*) "
            "FROM submissions WHERE submission_id >= 526"
        )
        row = cursor.fetchone()
        print(f"    Remapped submissions: min={row[0]}, max={row[1]}, count={row[2]}")

        cursor.execute(
            "SELECT COUNT(*) FROM submissions WHERE submission_id >= 4244"
        )
        leftover = cursor.fetchone()[0]
        if leftover > 0:
            print(f"    [WARN] {leftover} submissions still have old IDs!")
        else:
            print("    [OK] No submissions with old IDs remain.")

        cursor.execute(
            "SELECT COUNT(*) FROM publications WHERE submission_id >= 4244"
        )
        leftover = cursor.fetchone()[0]
        if leftover > 0:
            print(f"    [WARN] {leftover} publications still reference old submission IDs!")
        else:
            print("    [OK] All publications reference new submission IDs.")

        # Check publications integrity
        cursor.execute(
            "SELECT COUNT(*) FROM submissions s "
            "WHERE NOT EXISTS (SELECT 1 FROM publications p WHERE p.publication_id = s.current_publication_id)"
        )
        broken = cursor.fetchone()[0]
        if broken > 0:
            print(f"    [WARN] {broken} submissions have broken current_publication_id!")
        else:
            print("    [OK] All current_publication_id references valid.")

        # Print the final mapping for reference
        print("\n  Final submission_id mapping:")
        print("  " + "-" * 40)
        for old_id, new_id in sub_map.items():
            print(f"    {old_id:>6} → {new_id}")

        cursor.execute("SET FOREIGN_KEY_CHECKS = 1")
        cursor.execute("SET SQL_SAFE_UPDATES = 1")
        conn.commit()

    except Error as e:
        print(f"\n[ERROR] {e}")
        conn.rollback()
        raise

    finally:
        cursor.close()
        conn.close()

    print("\n" + "=" * 70)
    print("Submission ID remapping complete!")
    print(f"Old IDs 4244-8827 → New IDs {NEW_SUBMISSION_START}-{NEW_SUBMISSION_START + len(sub_map) - 1}")
    print("=" * 70)


if __name__ == "__main__":
    main()

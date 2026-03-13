"""
Step 4: migrate_reviews.py
============================
Imports review-related data from old DB → new DB.

Tables migrated:
  - review_rounds
  - review_assignments
  - review_round_files
  - review_files
  - review_form_responses

Also updates:
  - edit_decisions.review_round_id (from step3)
  - submission_files.assoc_id where assoc_type=517 (REVIEW_ROUND)

Prerequisites: Run step1, step2, step3 first.
"""

import json
import sys
from merge_config import (
    get_old_conn, get_new_conn, OLD_JOURNAL_ID,
    get_max_id, print_header, print_step, print_ok, print_warn,
    fix_encoding,
)

MAP_FILE = "merge_id_maps.json"


def load_maps():
    try:
        with open(MAP_FILE, "r") as f:
            data = json.load(f)
        result = {}
        for key, val in data.items():
            if isinstance(val, dict):
                result[key] = {int(k): v for k, v in val.items()}
            else:
                result[key] = val
        return result
    except (FileNotFoundError, json.JSONDecodeError):
        print_warn(f"Could not load {MAP_FILE}. Did you run step3?")
        sys.exit(1)


def save_maps(maps):
    serializable = {}
    for key, val in maps.items():
        if isinstance(val, dict):
            serializable[key] = {str(k): v for k, v in val.items()}
        else:
            serializable[key] = val
    with open(MAP_FILE, "w") as f:
        json.dump(serializable, f, indent=2)
    print_ok(f"Saved ID mappings to {MAP_FILE}")


def migrate_review_rounds(old_cur, new_conn, new_cur, sub_map):
    """Import review_rounds with new sequential IDs."""
    print_step("Migrating review_rounds...")

    old_sub_ids = tuple(sub_map.keys())
    placeholders = ",".join(["%s"] * len(old_sub_ids))

    old_cur.execute(
        f"SELECT review_round_id, submission_id, stage_id, round, review_revision, status "
        f"FROM review_rounds WHERE submission_id IN ({placeholders}) ORDER BY review_round_id",
        old_sub_ids
    )
    old_rows = old_cur.fetchall()

    next_rr_id = get_max_id(new_cur, "review_rounds", "review_round_id") + 1
    rr_map = {}

    for row in old_rows:
        old_rr_id = row[0]
        new_rr_id = next_rr_id
        new_sub_id = sub_map[row[1]]

        new_cur.execute(
            "INSERT INTO review_rounds (review_round_id, submission_id, stage_id, round, "
            "review_revision, status) VALUES (%s, %s, %s, %s, %s, %s)",
            (new_rr_id, new_sub_id, row[2], row[3], row[4], row[5])
        )

        rr_map[old_rr_id] = new_rr_id
        next_rr_id += 1

    new_conn.commit()
    print_ok(f"Migrated {len(rr_map)} review_rounds")
    return rr_map


def migrate_review_assignments(old_cur, new_conn, new_cur, sub_map, rr_map, maps):
    """Import review_assignments with new sequential IDs."""
    print_step("Migrating review_assignments...")

    review_form_map = maps.get("review_form_map", {})
    file_map = maps.get("file_map", {})

    old_sub_ids = tuple(sub_map.keys())
    placeholders = ",".join(["%s"] * len(old_sub_ids))

    old_cur.execute(
        f"SELECT review_id, submission_id, reviewer_id, competing_interests, recommendation, "
        f"date_assigned, date_notified, date_confirmed, date_completed, date_acknowledged, "
        f"date_due, date_response_due, last_modified, reminder_was_automatic, declined, "
        f"cancelled, reviewer_file_id, date_rated, date_reminded, quality, "
        f"review_round_id, stage_id, review_method, round, step, review_form_id, unconsidered "
        f"FROM review_assignments WHERE submission_id IN ({placeholders}) ORDER BY review_id",
        old_sub_ids
    )
    old_rows = old_cur.fetchall()

    next_review_id = get_max_id(new_cur, "review_assignments", "review_id") + 1
    review_map = {}

    for row in old_rows:
        old_review_id = row[0]
        new_review_id = next_review_id
        new_sub_id = sub_map[row[1]]

        # Remap review_round_id
        old_rr_id = row[20]
        new_rr_id = rr_map.get(old_rr_id, old_rr_id) if old_rr_id else None

        # Remap reviewer_file_id
        old_rf_id = row[16]
        new_rf_id = file_map.get(old_rf_id) if old_rf_id else None

        # Remap review_form_id
        old_form_id = row[25]
        new_form_id = review_form_map.get(old_form_id) if old_form_id else None

        new_cur.execute(
            "INSERT INTO review_assignments (review_id, submission_id, reviewer_id, "
            "competing_interests, recommendation, date_assigned, date_notified, "
            "date_confirmed, date_completed, date_acknowledged, date_due, "
            "date_response_due, last_modified, reminder_was_automatic, declined, "
            "cancelled, reviewer_file_id, date_rated, date_reminded, quality, "
            "review_round_id, stage_id, review_method, round, step, review_form_id, "
            "unconsidered) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, "
            "%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)",
            (new_review_id, new_sub_id, row[2], fix_encoding(row[3]), row[4],
             row[5], row[6], row[7], row[8], row[9], row[10],
             row[11], row[12], row[13], row[14], row[15],
             new_rf_id, row[17], row[18], row[19],
             new_rr_id, row[21], row[22], row[23], row[24],
             new_form_id, row[26])
        )

        review_map[old_review_id] = new_review_id
        next_review_id += 1

    new_conn.commit()
    print_ok(f"Migrated {len(review_map)} review_assignments")
    return review_map


def migrate_review_round_files(old_cur, new_conn, new_cur, sub_map, rr_map, file_map):
    """Import review_round_files."""
    print_step("Migrating review_round_files...")

    old_sub_ids = tuple(sub_map.keys())
    placeholders = ",".join(["%s"] * len(old_sub_ids))

    old_cur.execute(
        f"SELECT submission_id, review_round_id, stage_id, file_id, revision "
        f"FROM review_round_files WHERE submission_id IN ({placeholders})",
        old_sub_ids
    )
    old_rows = old_cur.fetchall()

    count = 0
    skipped = 0
    for row in old_rows:
        new_sub_id = sub_map.get(row[0])
        new_rr_id = rr_map.get(row[1])
        new_file_id = file_map.get(row[3])

        if not new_sub_id or not new_rr_id or not new_file_id:
            skipped += 1
            continue

        try:
            new_cur.execute(
                "INSERT IGNORE INTO review_round_files "
                "(submission_id, review_round_id, stage_id, file_id, revision) "
                "VALUES (%s, %s, %s, %s, %s)",
                (new_sub_id, new_rr_id, row[2], new_file_id, row[4])
            )
            count += 1
        except Exception as e:
            print_warn(f"  Failed to insert review_round_file: {e}")

    new_conn.commit()
    print_ok(f"Migrated {count} review_round_files (skipped {skipped})")


def migrate_review_files(old_cur, new_conn, new_cur, review_map, file_map):
    """Import review_files."""
    print_step("Migrating review_files...")

    old_review_ids = tuple(review_map.keys())
    if not old_review_ids:
        print_ok("No review_files to migrate")
        return

    placeholders = ",".join(["%s"] * len(old_review_ids))

    old_cur.execute(
        f"SELECT review_id, file_id FROM review_files WHERE review_id IN ({placeholders})",
        old_review_ids
    )
    old_rows = old_cur.fetchall()

    count = 0
    skipped = 0
    for row in old_rows:
        new_review_id = review_map.get(row[0])
        new_file_id = file_map.get(row[1])

        if not new_review_id or not new_file_id:
            skipped += 1
            continue

        try:
            new_cur.execute(
                "INSERT IGNORE INTO review_files (review_id, file_id) VALUES (%s, %s)",
                (new_review_id, new_file_id)
            )
            count += 1
        except Exception as e:
            print_warn(f"  Failed to insert review_file: {e}")

    new_conn.commit()
    print_ok(f"Migrated {count} review_files (skipped {skipped})")


def migrate_review_form_responses(old_cur, new_conn, new_cur, review_map, maps):
    """Import review_form_responses."""
    print_step("Migrating review_form_responses...")

    review_form_element_map = maps.get("review_form_element_map", {})

    old_review_ids = tuple(review_map.keys())
    if not old_review_ids:
        print_ok("No review_form_responses to migrate")
        return

    placeholders = ",".join(["%s"] * len(old_review_ids))

    old_cur.execute(
        f"SELECT review_form_element_id, review_id, response_type, response_value "
        f"FROM review_form_responses WHERE review_id IN ({placeholders})",
        old_review_ids
    )
    old_rows = old_cur.fetchall()

    count = 0
    skipped = 0
    for row in old_rows:
        old_elem_id = row[0]
        new_elem_id = review_form_element_map.get(old_elem_id)
        new_review_id = review_map.get(row[1])

        if not new_elem_id or not new_review_id:
            skipped += 1
            continue

        try:
            new_cur.execute(
                "INSERT INTO review_form_responses "
                "(review_form_element_id, review_id, response_type, response_value) "
                "VALUES (%s, %s, %s, %s)",
                (new_elem_id, new_review_id, row[2], fix_encoding(row[3]))
            )
            count += 1
        except Exception as e:
            print_warn(f"  Failed to insert review_form_response: {e}")

    new_conn.commit()
    print_ok(f"Migrated {count} review_form_responses (skipped {skipped})")


def update_edit_decision_rounds(new_conn, new_cur, rr_map, maps):
    """Update edit_decisions.review_round_id that was left as NULL in step3."""
    print_step("Updating edit_decisions.review_round_id...")

    ed_round_refs = maps.get("edit_decision_round_refs", {})

    count = 0
    for new_ed_id, old_rr_id in ed_round_refs.items():
        new_rr_id = rr_map.get(old_rr_id)
        if new_rr_id:
            new_cur.execute(
                "UPDATE edit_decisions SET review_round_id = %s WHERE edit_decision_id = %s",
                (new_rr_id, new_ed_id)
            )
            count += 1

    new_conn.commit()
    print_ok(f"Updated {count} edit_decisions with review_round_id")


def update_submission_file_review_rounds(new_conn, new_cur, rr_map, file_map):
    """Update submission_files.assoc_id where assoc_type=517 (REVIEW_ROUND)."""
    print_step("Updating submission_files with review_round references...")

    # Get all new file_ids that need updating
    new_file_ids = list(file_map.values())
    if not new_file_ids:
        return

    placeholders = ",".join(["%s"] * len(new_file_ids))
    new_cur.execute(
        f"SELECT file_id, assoc_id FROM submission_files "
        f"WHERE assoc_type = 517 AND file_id IN ({placeholders})",
        tuple(new_file_ids)
    )
    rows = new_cur.fetchall()

    # Build reverse file_map: new → old
    reverse_file_map = {v: k for k, v in file_map.items()}

    # We need to find old assoc_ids to remap
    old_conn = get_old_conn()
    old_cur = old_conn.cursor()

    count = 0
    for new_fid, current_assoc_id in rows:
        old_fid = reverse_file_map.get(new_fid)
        if old_fid:
            old_cur.execute(
                "SELECT assoc_id FROM submission_files WHERE file_id = %s AND assoc_type = 517 LIMIT 1",
                (old_fid,)
            )
            result = old_cur.fetchone()
            if result:
                old_rr_id = result[0]
                new_rr_id = rr_map.get(old_rr_id)
                if new_rr_id:
                    new_cur.execute(
                        "UPDATE submission_files SET assoc_id = %s WHERE file_id = %s AND assoc_type = 517",
                        (new_rr_id, new_fid)
                    )
                    count += 1

    new_conn.commit()
    old_cur.close()
    old_conn.close()
    print_ok(f"Updated {count} submission_files review_round references")


def main():
    print_header("STEP 4: MIGRATE REVIEWS")

    maps = load_maps()
    sub_map = maps["submission_map"]
    file_map = maps["file_map"]

    old_conn = get_old_conn()
    new_conn = get_new_conn()
    old_cur = old_conn.cursor()
    new_cur = new_conn.cursor()

    new_cur.execute("SET FOREIGN_KEY_CHECKS = 0")
    new_cur.execute("SET SQL_SAFE_UPDATES = 0")

    # 1) Review rounds
    rr_map = migrate_review_rounds(old_cur, new_conn, new_cur, sub_map)

    # 2) Review assignments
    review_map = migrate_review_assignments(old_cur, new_conn, new_cur, sub_map, rr_map, maps)

    # 3) Review round files
    migrate_review_round_files(old_cur, new_conn, new_cur, sub_map, rr_map, file_map)

    # 4) Review files
    migrate_review_files(old_cur, new_conn, new_cur, review_map, file_map)

    # 5) Review form responses
    migrate_review_form_responses(old_cur, new_conn, new_cur, review_map, maps)

    # 6) Update edit_decisions.review_round_id from step3
    update_edit_decision_rounds(new_conn, new_cur, rr_map, maps)

    # 7) Update submission_files assoc_type=517 references
    update_submission_file_review_rounds(new_conn, new_cur, rr_map, file_map)

    # Save review maps
    maps["review_round_map"] = {str(k): v for k, v in rr_map.items()}
    maps["review_map"] = {str(k): v for k, v in review_map.items()}
    save_maps(maps)

    new_cur.execute("SET FOREIGN_KEY_CHECKS = 1")
    new_conn.commit()

    print_header("STEP 4 COMPLETE")
    print_ok(f"Review rounds: {len(rr_map)}")
    print_ok(f"Review assignments: {len(review_map)}")

    old_cur.close()
    new_cur.close()
    old_conn.close()
    new_conn.close()


if __name__ == "__main__":
    main()

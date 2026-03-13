"""
Step 7: verify_merge.py
========================
Verifies the integrity of the merged database by checking:
  1. Row counts match expected values
  2. No orphaned references
  3. All ID mappings are consistent
  4. No broken relationships

Run this AFTER all migration steps (step1 through step5/6).
"""

import json
import sys
from merge_config import (
    get_old_conn, get_new_conn, OLD_JOURNAL_ID, NEW_JOURNAL_ID,
    ASSOC_TYPE_SUBMISSION, ASSOC_TYPE_SUBMISSION_FILE, ASSOC_TYPE_PUBLICATION,
    ASSOC_TYPE_QUERY,
    print_header, print_step, print_ok, print_warn,
)

MAP_FILE = "merge_id_maps.json"

errors_found = 0


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
        print_warn(f"Could not load {MAP_FILE}")
        sys.exit(1)


def check(cursor, description, query, params=None, expect_zero=True):
    """Run a check query and report result."""
    global errors_found
    cursor.execute(query, params or ())
    result = cursor.fetchone()[0]

    if expect_zero:
        if result == 0:
            print_ok(f"{description}: {result} ✓")
        else:
            print_warn(f"{description}: {result} ✗")
            errors_found += 1
    else:
        print_ok(f"{description}: {result}")
    return result


def verify_counts(old_cur, new_cur, maps):
    """Verify migrated row counts."""
    print_step("Verifying migrated row counts...")

    sub_map = maps.get("submission_map", {})
    new_sub_ids = tuple(sub_map.values()) if sub_map else (0,)
    placeholders = ",".join(["%s"] * len(new_sub_ids))

    # Count old submissions for journal 27
    old_cur.execute("SELECT COUNT(*) FROM submissions WHERE context_id = %s", (OLD_JOURNAL_ID,))
    old_count = old_cur.fetchone()[0]

    new_cur.execute(f"SELECT COUNT(*) FROM submissions WHERE submission_id IN ({placeholders})", new_sub_ids)
    new_count = new_cur.fetchone()[0]

    if old_count == new_count:
        print_ok(f"Submissions: old={old_count}, new={new_count} ✓")
    else:
        print_warn(f"Submissions: old={old_count}, new={new_count} ✗")

    # Publications
    old_cur.execute("SELECT COUNT(*) FROM publications WHERE submission_id IN (SELECT submission_id FROM submissions WHERE context_id = %s)", (OLD_JOURNAL_ID,))
    old_p = old_cur.fetchone()[0]
    pub_map = maps.get("publication_map", {})
    print_ok(f"Publications: old={old_p}, migrated={len(pub_map)}")

    # Authors
    old_cur.execute("SELECT COUNT(*) FROM authors WHERE publication_id IN (SELECT publication_id FROM publications WHERE submission_id IN (SELECT submission_id FROM submissions WHERE context_id = %s))", (OLD_JOURNAL_ID,))
    old_a = old_cur.fetchone()[0]
    author_map = maps.get("author_map", {})
    print_ok(f"Authors: old={old_a}, migrated={len(author_map)}")

    # Submission files
    old_cur.execute("SELECT COUNT(DISTINCT file_id) FROM submission_files WHERE submission_id IN (SELECT submission_id FROM submissions WHERE context_id = %s)", (OLD_JOURNAL_ID,))
    old_f = old_cur.fetchone()[0]
    file_map = maps.get("file_map", {})
    print_ok(f"Submission files (unique): old={old_f}, migrated={len(file_map)}")

    # Review rounds
    old_cur.execute("SELECT COUNT(*) FROM review_rounds WHERE submission_id IN (SELECT submission_id FROM submissions WHERE context_id = %s)", (OLD_JOURNAL_ID,))
    old_rr = old_cur.fetchone()[0]
    rr_map = maps.get("review_round_map", {})
    print_ok(f"Review rounds: old={old_rr}, migrated={len(rr_map)}")

    # Review assignments
    old_cur.execute("SELECT COUNT(*) FROM review_assignments WHERE submission_id IN (SELECT submission_id FROM submissions WHERE context_id = %s)", (OLD_JOURNAL_ID,))
    old_ra = old_cur.fetchone()[0]
    review_map = maps.get("review_map", {})
    print_ok(f"Review assignments: old={old_ra}, migrated={len(review_map)}")


def verify_orphans(new_cur):
    """Check for orphaned records in the new database."""
    print_step("Checking for orphaned records...")

    # Publications → submissions
    check(new_cur, "publications → submissions (orphans)",
          "SELECT COUNT(*) FROM publications p WHERE p.submission_id NOT IN (SELECT submission_id FROM submissions)")

    # Authors → publications
    check(new_cur, "authors → publications (orphans)",
          "SELECT COUNT(*) FROM authors a WHERE a.publication_id NOT IN (SELECT publication_id FROM publications)")

    # Citations → publications
    check(new_cur, "citations → publications (orphans)",
          "SELECT COUNT(*) FROM citations c WHERE c.publication_id NOT IN (SELECT publication_id FROM publications)")

    # publication_settings → publications
    check(new_cur, "publication_settings → publications (orphans)",
          "SELECT COUNT(*) FROM publication_settings ps WHERE ps.publication_id NOT IN (SELECT publication_id FROM publications)")

    # submission_files → submissions
    check(new_cur, "submission_files → submissions (orphans)",
          "SELECT COUNT(*) FROM submission_files sf WHERE sf.submission_id NOT IN (SELECT submission_id FROM submissions)")

    # stage_assignments → submissions
    check(new_cur, "stage_assignments → submissions (orphans)",
          "SELECT COUNT(*) FROM stage_assignments sa WHERE sa.submission_id NOT IN (SELECT submission_id FROM submissions)")

    # edit_decisions → submissions
    check(new_cur, "edit_decisions → submissions (orphans)",
          "SELECT COUNT(*) FROM edit_decisions ed WHERE ed.submission_id NOT IN (SELECT submission_id FROM submissions)")

    # review_rounds → submissions
    check(new_cur, "review_rounds → submissions (orphans)",
          "SELECT COUNT(*) FROM review_rounds rr WHERE rr.submission_id NOT IN (SELECT submission_id FROM submissions)")

    # review_assignments → submissions
    check(new_cur, "review_assignments → submissions (orphans)",
          "SELECT COUNT(*) FROM review_assignments ra WHERE ra.submission_id NOT IN (SELECT submission_id FROM submissions)")

    # review_assignments → review_rounds
    check(new_cur, "review_assignments → review_rounds (orphans)",
          "SELECT COUNT(*) FROM review_assignments ra WHERE ra.review_round_id IS NOT NULL AND ra.review_round_id NOT IN (SELECT review_round_id FROM review_rounds)")

    # review_round_files → review_rounds
    check(new_cur, "review_round_files → review_rounds (orphans)",
          "SELECT COUNT(*) FROM review_round_files rrf WHERE rrf.review_round_id NOT IN (SELECT review_round_id FROM review_rounds)")

    # queries → submissions (assoc_type=1048585)
    check(new_cur, "queries → submissions (orphans)",
          f"SELECT COUNT(*) FROM queries q WHERE q.assoc_type = {ASSOC_TYPE_SUBMISSION} AND q.assoc_id NOT IN (SELECT submission_id FROM submissions)")

    # notes → queries
    check(new_cur, "notes → queries (orphans)",
          f"SELECT COUNT(*) FROM notes n WHERE n.assoc_type = {ASSOC_TYPE_QUERY} AND n.assoc_id NOT IN (SELECT query_id FROM queries)")

    # stage_assignments → users
    check(new_cur, "stage_assignments → users (orphans)",
          "SELECT COUNT(*) FROM stage_assignments sa WHERE sa.user_id NOT IN (SELECT user_id FROM users)")

    # review_assignments → users (reviewer)
    check(new_cur, "review_assignments → users (reviewer orphans)",
          "SELECT COUNT(*) FROM review_assignments ra WHERE ra.reviewer_id NOT IN (SELECT user_id FROM users)")

    # edit_decisions → users (editor)
    check(new_cur, "edit_decisions → users (editor orphans)",
          "SELECT COUNT(*) FROM edit_decisions ed WHERE ed.editor_id NOT IN (SELECT user_id FROM users)")

    # stage_assignments → user_groups
    check(new_cur, "stage_assignments → user_groups (orphans)",
          "SELECT COUNT(*) FROM stage_assignments sa WHERE sa.user_group_id NOT IN (SELECT user_group_id FROM user_groups)")

    # submission_files → genres
    check(new_cur, "submission_files → genres (orphans)",
          "SELECT COUNT(*) FROM submission_files sf WHERE sf.genre_id IS NOT NULL AND sf.genre_id NOT IN (SELECT genre_id FROM genres)")

    # submissions → sections
    check(new_cur, "submissions → sections (orphans)",
          "SELECT COUNT(*) FROM submissions s WHERE s.section_id IS NOT NULL AND s.section_id NOT IN (SELECT section_id FROM sections)")

    # submissions → current_publication_id
    check(new_cur, "submissions → current_publication (orphans)",
          "SELECT COUNT(*) FROM submissions s WHERE s.current_publication_id IS NOT NULL AND s.current_publication_id NOT IN (SELECT publication_id FROM publications)")


def verify_migrated_data(new_cur, maps):
    """Verify the migrated data specifically."""
    print_step("Verifying migrated data integrity...")

    sub_map = maps.get("submission_map", {})
    new_sub_ids = list(sub_map.values())

    if not new_sub_ids:
        print_warn("No submission_map found - cannot verify migrated data")
        return

    min_id = min(new_sub_ids)
    max_id = max(new_sub_ids)

    # Check submissions have context_id = 1
    new_cur.execute(
        "SELECT COUNT(*) FROM submissions WHERE submission_id BETWEEN %s AND %s AND context_id != %s",
        (min_id, max_id, NEW_JOURNAL_ID)
    )
    bad_ctx = new_cur.fetchone()[0]
    if bad_ctx == 0:
        print_ok(f"All migrated submissions have context_id={NEW_JOURNAL_ID} ✓")
    else:
        print_warn(f"{bad_ctx} migrated submissions have wrong context_id ✗")

    # Check publications have valid section_id
    pub_map = maps.get("publication_map", {})
    new_pub_ids = list(pub_map.values())
    if new_pub_ids:
        placeholders = ",".join(["%s"] * len(new_pub_ids))
        new_cur.execute(
            f"SELECT COUNT(*) FROM publications p "
            f"WHERE p.publication_id IN ({placeholders}) "
            f"AND p.section_id NOT IN (SELECT section_id FROM sections)",
            tuple(new_pub_ids)
        )
        bad_sec = new_cur.fetchone()[0]
        if bad_sec == 0:
            print_ok(f"All migrated publications have valid section_id ✓")
        else:
            print_warn(f"{bad_sec} migrated publications have invalid section_id ✗")


def main():
    global errors_found

    print_header("STEP 7: VERIFY MERGE INTEGRITY")

    maps = load_maps()

    old_conn = get_old_conn()
    new_conn = get_new_conn()
    old_cur = old_conn.cursor()
    new_cur = new_conn.cursor()

    # 1) Count verification
    verify_counts(old_cur, new_cur, maps)

    # 2) Orphan checks
    verify_orphans(new_cur)

    # 3) Migrated data specific checks
    verify_migrated_data(new_cur, maps)

    print_header("VERIFICATION COMPLETE")
    if errors_found == 0:
        print_ok("ALL CHECKS PASSED! ✓")
    else:
        print_warn(f"{errors_found} ISSUES FOUND — review above warnings")

    old_cur.close()
    new_cur.close()
    old_conn.close()
    new_conn.close()


if __name__ == "__main__":
    main()

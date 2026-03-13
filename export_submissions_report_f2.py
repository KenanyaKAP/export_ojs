"""
export_submissions_report.py
============================
Exports a CSV report of all submissions in the OJS database.

Fixed columns:
  1. Date of Submission
  2. Paper ID
  3. Title
  4. Submission Status  (matches OJS dashboard UI labels)
  5. Last Update

Dynamic columns (appended at the end):
  - Author 1 Name, Author 1 Email, Author 2 Name, Author 2 Email, …
  - Section Editor 1 Name, Section Editor 1 Email, …
  - Reviewer 1 Name, Reviewer 1 Email, …

Usage:
    python export_submissions_report.py
"""

import csv
from collections import defaultdict

import mysql.connector

# ============================================================
# CONFIGURATION — edit these to match your environment
# ============================================================
# jaree.kenanya.my.id
# DB_CONFIG = {
#     "host": "127.0.0.1",
#     "port": 3376,
#     "user": "root",
#     "password": "rootpassword",
#     "database": "ojs",
#     "charset": "utf8mb4",
# }

# jaree ojs3
DB_CONFIG = {
    "host": "127.0.0.1",
    "port": 33063,
    "user": "root",
    "password": "0j5_3lektr0_*1=^@~2025",
    "database": "ojs_3213_v2",
    "charset": "utf8mb4",
}

# jaree-old ITS
# DB_CONFIG = {
#     "host": "127.0.0.1",
#     "port": 3386,
#     "user": "root",
#     "password": "ITSjournals123!#",
#     "database": "journals",
#     "charset": "utf8mb4",
# }

OUTPUT_CSV = "submissions_report.csv"

JOURNAL_ID = 1          # context_id in the submissions table
# JOURNAL_ID = 27          # context_id in the submissions table

# user_group_id for "Section editor" in this journal (see user_groups table)
SECTION_EDITOR_GROUP_ID = 5
# SECTION_EDITOR_GROUP_ID = 447

# ============================================================
# OJS STATUS + STAGE → Dashboard UI label mapping
# ============================================================
# OJS 3.x internal constants:
#   status:   1=Queued, 3=Published, 4=Declined, 5=Scheduled
#   stage_id: 1=Submission, 2=Internal Review, 3=External Review,
#             4=Copyediting, 5=Production
#
# When status=1 (Queued), the dashboard shows the current workflow
# stage name.  Other statuses override the stage label.
# ============================================================

STATUS_MAP = {
    3: "Published",
    4: "Declined",
    5: "Scheduled",
}

STAGE_MAP = {
    1: "Submission",
    2: "Internal Review",
    3: "Review",
    4: "Copyediting",
    5: "Production",
}


def get_dashboard_status(status, stage_id):
    """Map OJS status + stage_id to the label shown in the dashboard UI."""
    if status in STATUS_MAP:
        return STATUS_MAP[status]
    # status == 1 (Queued): show the current workflow stage
    return STAGE_MAP.get(stage_id, f"Unknown (status={status}, stage={stage_id})")


# ────────────────────────────────────────────────────────────────────
# Data fetchers — each returns {submission_id: [(name, email), …]}
# ────────────────────────────────────────────────────────────────────

def fetch_submissions(cur):
    """Return basic submission rows (fixed columns including issue/year for published)."""
    cur.execute("""
        SELECT
            s.submission_id,
            s.status,
            s.stage_id,
            DATE(s.date_submitted)              AS date_submitted,
            s.last_modified                     AS last_update,
            MAX(CASE WHEN ps.setting_name = 'title'
                     THEN ps.setting_value END) AS title,
            i.volume                            AS issue_volume,
            i.number                            AS issue_number,
            i.year                              AS issue_year
        FROM submissions s
        JOIN publications p
            ON p.submission_id = s.submission_id
           AND p.publication_id = s.current_publication_id
        LEFT JOIN publication_settings ps
            ON ps.publication_id = p.publication_id
           AND ps.setting_name = 'title'
        LEFT JOIN publication_settings ps_issue
            ON ps_issue.publication_id = p.publication_id
           AND ps_issue.setting_name = 'issueId'
        LEFT JOIN issues i
            ON i.issue_id = ps_issue.setting_value
        WHERE s.context_id = %s
        GROUP BY s.submission_id, s.status, s.stage_id,
                 s.date_submitted, s.last_modified,
                 i.volume, i.number, i.year
        ORDER BY s.submission_id ASC
    """, (JOURNAL_ID,))
    return cur.fetchall()


def fetch_authors(cur):
    """Return authors per submission: {submission_id: [(username, name, email, seq), …]}."""
    cur.execute("""
        SELECT
            s.submission_id,
            COALESCE(u.username, '')             AS username,
            CONCAT(
                COALESCE(aus_fn.setting_value, ''), ' ',
                COALESCE(aus_ln.setting_value, '')
            )                       AS author_name,
            a.email                 AS author_email,
            a.seq                   AS seq
        FROM submissions s
        JOIN publications p
            ON p.submission_id = s.submission_id
           AND p.publication_id = s.current_publication_id
        JOIN authors a
            ON a.publication_id = p.publication_id
        LEFT JOIN author_settings aus_fn
            ON aus_fn.author_id = a.author_id
           AND aus_fn.setting_name = 'givenName'
           AND aus_fn.locale = p.locale
        LEFT JOIN author_settings aus_ln
            ON aus_ln.author_id = a.author_id
           AND aus_ln.setting_name = 'familyName'
           AND aus_ln.locale = p.locale
        LEFT JOIN users u
            ON LOWER(u.email) = LOWER(a.email)
        WHERE s.context_id = %s
        ORDER BY s.submission_id, a.seq ASC
    """, (JOURNAL_ID,))

    result = defaultdict(list)
    for row in cur.fetchall():
        username = (row["username"] or "").strip()
        name = (row["author_name"] or "").strip()
        email = (row["author_email"] or "").strip()
        result[row["submission_id"]].append((username, name, email))
    return result


def fetch_section_editors(cur):
    """Return section editors per submission from stage_assignments.

    Uses user_group_id = SECTION_EDITOR_GROUP_ID (default 5).
    Returns {submission_id: [(username, name, email), …]}.
    """
    cur.execute("""
        SELECT
            sa.submission_id,
            u.username,
            CONCAT(
                COALESCE(us_fn.setting_value, ''), ' ',
                COALESCE(us_ln.setting_value, '')
            )                       AS editor_name,
            u.email                 AS editor_email
        FROM stage_assignments sa
        JOIN users u
            ON u.user_id = sa.user_id
        LEFT JOIN user_settings us_fn
            ON us_fn.user_id = u.user_id
           AND us_fn.setting_name = 'givenName'
           AND us_fn.locale = 'en_US'
        LEFT JOIN user_settings us_ln
            ON us_ln.user_id = u.user_id
           AND us_ln.setting_name = 'familyName'
           AND us_ln.locale = 'en_US'
        WHERE sa.user_group_id = %s
          AND sa.submission_id IN (
              SELECT submission_id FROM submissions WHERE context_id = %s
          )
        ORDER BY sa.submission_id, sa.stage_assignment_id ASC
    """, (SECTION_EDITOR_GROUP_ID, JOURNAL_ID))

    result = defaultdict(list)
    for row in cur.fetchall():
        username = (row["username"] or "").strip()
        name = (row["editor_name"] or "").strip()
        email = (row["editor_email"] or "").strip()
        result[row["submission_id"]].append((username, name, email))
    return result


def fetch_reviewers(cur):
    """Return reviewers per submission from review_assignments.

    Returns {submission_id: [(username, name, email), …]}.
    """
    cur.execute("""
        SELECT
            ra.submission_id,
            u.username,
            CONCAT(
                COALESCE(us_fn.setting_value, ''), ' ',
                COALESCE(us_ln.setting_value, '')
            )                       AS reviewer_name,
            u.email                 AS reviewer_email
        FROM review_assignments ra
        JOIN users u
            ON u.user_id = ra.reviewer_id
        LEFT JOIN user_settings us_fn
            ON us_fn.user_id = u.user_id
           AND us_fn.setting_name = 'givenName'
           AND us_fn.locale = 'en_US'
        LEFT JOIN user_settings us_ln
            ON us_ln.user_id = u.user_id
           AND us_ln.setting_name = 'familyName'
           AND us_ln.locale = 'en_US'
        WHERE ra.submission_id IN (
            SELECT submission_id FROM submissions WHERE context_id = %s
        )
        ORDER BY ra.submission_id, ra.round ASC, ra.review_id ASC
    """, (JOURNAL_ID,))

    result = defaultdict(list)
    for row in cur.fetchall():
        username = (row["username"] or "").strip()
        name = (row["reviewer_name"] or "").strip()
        email = (row["reviewer_email"] or "").strip()
        result[row["submission_id"]].append((username, name, email))
    return result


# ────────────────────────────────────────────────────────────────────

def main():
    conn = mysql.connector.connect(**DB_CONFIG)
    cur = conn.cursor(dictionary=True)

    # 1. Fetch all data
    submissions = fetch_submissions(cur)
    authors_map = fetch_authors(cur)
    editors_map = fetch_section_editors(cur)
    reviewers_map = fetch_reviewers(cur)

    cur.close()
    conn.close()

    # 2. Determine max counts for dynamic columns
    all_sub_ids = [r["submission_id"] for r in submissions]
    max_authors   = max((len(authors_map.get(sid, []))   for sid in all_sub_ids), default=0)
    max_editors   = max((len(editors_map.get(sid, []))   for sid in all_sub_ids), default=0)
    max_reviewers = max((len(reviewers_map.get(sid, [])) for sid in all_sub_ids), default=0)

    # 3. Build CSV header
    header = [
        "Date of Submission",
        "Paper ID",
        "Title",
        "Submission Status",
        "Last Update",
        "Published Issue",
        "Published Year",
        "Username",
        "Name",
        "Email",
        "Role",
    ]

    # 4. Write CSV (normalized format: one row per person per submission)
    with open(OUTPUT_CSV, "w", newline="", encoding="utf-8-sig") as f:
        writer = csv.writer(f)
        writer.writerow(header)

        for row in submissions:
            sid = row["submission_id"]
            status_label = get_dashboard_status(row["status"], row["stage_id"])
            
            # Format issue information (populated when issue data exists)
            issue_text = ""
            issue_year = ""
            if row["issue_volume"] or row["issue_number"]:
                parts = []
                if row["issue_volume"]:
                    parts.append(f"Vol {row['issue_volume']}")
                if row["issue_number"]:
                    parts.append(f"No {row['issue_number']}")
                issue_text = ", ".join(parts) if parts else ""
            if row["issue_year"]:
                issue_year = str(row["issue_year"])

            # Base submission info (shared across all role rows)
            base_row = [
                row["date_submitted"] or "",
                sid,
                row["title"] or "",
                status_label,
                row["last_update"] or "",
                issue_text,
                issue_year,
            ]

            # Collect all people for this submission
            all_people = []
            
            # Authors
            for i, (username, name, email) in enumerate(authors_map.get(sid, []), 1):
                all_people.append([username, name, email, f"Author {i}"])
            
            # Section Editors
            for i, (username, name, email) in enumerate(editors_map.get(sid, []), 1):
                all_people.append([username, name, email, f"Section Editor {i}"])
            
            # Reviewers
            for i, (username, name, email) in enumerate(reviewers_map.get(sid, []), 1):
                all_people.append([username, name, email, f"Reviewer {i}"])

            # If no people, write one row with empty person columns
            if not all_people:
                csv_row = base_row + ["", "", "", ""]
                writer.writerow(csv_row)
            else:
                # Write one row per person
                for username, name, email, role in all_people:
                    csv_row = base_row + [username, name, email, role]
                    writer.writerow(csv_row)

    print(f"✅ Exported {len(submissions)} submissions to {OUTPUT_CSV}")
    print(f"   Format: Normalized (one row per person per submission)")
    print(f"   Columns: 7 fixed + 4 person columns (Username, Name, Email, Role)")
    print(f"   Total authors: {sum(len(authors_map.get(sid, [])) for sid in all_sub_ids)}")
    print(f"   Total section editors: {sum(len(editors_map.get(sid, [])) for sid in all_sub_ids)}")
    print(f"   Total reviewers: {sum(len(reviewers_map.get(sid, [])) for sid in all_sub_ids)}")


if __name__ == "__main__":
    main()

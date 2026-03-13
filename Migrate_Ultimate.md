# Ultimate OJS Database Merge Guide

## Overview

This guide merges submission data from an **old OJS database** (port 3386, `journals`, journal_id=27)
into a **new OJS database** (port 3376, `ojs`, journal_id=1).

The migration is **dynamic** — it reads current max IDs from the new database and assigns sequential
IDs starting from the next available value. No hardcoded IDs.

## What Gets Migrated

### Core Data

| Table                         | Description             | Expected Count |
| ----------------------------- | ----------------------- | -------------- |
| `submissions`                 | Main submission records | 40             |
| `publications`                | Publication metadata    | 40             |
| `authors` + `author_settings` | Author information      | ~93 + ~628     |
| `citations`                   | Reference citations     | ~235           |
| `publication_settings`        | Pub titles, abstracts   | ~225           |

### Files

| Table                            | Description         | Expected Count |
| -------------------------------- | ------------------- | -------------- |
| `submission_files`               | Uploaded files      | ~219           |
| `submission_file_settings`       | File metadata       | ~438           |
| `submission_supplementary_files` | Supplementary files | ~45            |

### Workflow

| Table                   | Description                 | Expected Count |
| ----------------------- | --------------------------- | -------------- |
| `stage_assignments`     | User-submission assignments | ~88            |
| `edit_decisions`        | Editorial decisions         | ~125           |
| `review_rounds`         | Review round info           | ~33            |
| `review_assignments`    | Reviewer assignments        | ~77            |
| `review_round_files`    | Files per review round      | ~82            |
| `review_files`          | Files assigned to reviewers | ~83            |
| `review_form_responses` | Reviewer form answers       | ~400           |
| `submission_comments`   | Editor comments             | ~1             |

### Metadata & Structure

| Table                                    | Description                | Expected Count     |
| ---------------------------------------- | -------------------------- | ------------------ |
| `sections` + `section_settings`          | Journal sections           | 6 new + 1 mapped   |
| `review_forms` + elements + settings     | Review form definitions    | 1 form, 7 elements |
| `controlled_vocabs` + entries + settings | Keywords, subjects         | ~200 vocabs        |
| `subeditor_submission_group`             | Section editor assignments | ~15                |

### Logs & Communication

| Table                              | Description         | Expected Count |
| ---------------------------------- | ------------------- | -------------- |
| `queries` + `query_participants`   | Discussion threads  | ~37 + ~68      |
| `notes`                            | Discussion messages | ~37            |
| `event_log` + `event_log_settings` | Activity log        | ~874 + ~3494   |
| `email_log` + `email_log_users`    | Email records       | ~280 + ~355    |

### Users

| Table                     | Description           | Expected Count |
| ------------------------- | --------------------- | -------------- |
| `users` + `user_settings` | Missing user accounts | ~66            |
| `user_user_groups`        | User role assignments | Variable       |

## ID Remapping Strategy

All IDs are dynamically remapped. The mapping is saved to `merge_id_maps.json` between steps.

| Old ID                    | New ID Start    | Notes                                 |
| ------------------------- | --------------- | ------------------------------------- |
| submission_id: 4244-8827  | 526+            | Sequential after last new submission  |
| publication_id: 4245-8837 | 379+            | Sequential after last new publication |
| author_id: 12735-24327    | 1121+           | Sequential after last new author      |
| file_id: 14741-21580      | 1587+           | Sequential after last new file        |
| section_id: 36,63-68      | 36→1, 63-68→new | "Articles" maps to existing section   |
| user_group_id: 444-460    | 2-18            | Mapped by role_id position            |
| genre_id: 317-328         | 1-12            | Mapped by position                    |
| review_form_id: 13        | next available  | New review form created               |
| All other IDs             | next available  | Sequential from current max           |

---

## Execution Steps

### Prerequisites

```bash
pip install mysql-connector-python
```

Make sure both databases are accessible:

- Old DB: `127.0.0.1:3386` (root / ITSjournals123!#)
- New DB: `127.0.0.1:3376` (root / rootpassword)

**⚠️ CRITICAL: OJS config.inc.php must have `connection_charset = utf8` under `[database]`!**

Without this setting, PHP's MySQL connection defaults to latin1, causing blank
workflow pages for submissions with Windows-1252 characters (smart quotes,
en-dash, etc.) because `json_encode()` rejects raw latin1 bytes as malformed UTF-8.

### Step-by-Step Execution

Run each step **in order** from the `Export CSV` directory:

#### Step 1: Migrate Users

```bash
python step1_migrate_users.py
```

- Finds all users referenced by old submission data
- Imports missing users (those not already in new DB)
- Copies user_settings for imported users
- Sets up user_user_groups with remapped group IDs

#### Step 2: Migrate Sections & Review Forms

```bash
python step2_migrate_sections.py
```

- Imports 6 new sections (PES, CSE, EL, TSP, BME, CIT)
- Maps old "Articles" section (36) to existing section (1)
- Imports review form 13 with all elements and settings
- Builds genre and user_group mappings
- **Saves all maps to `merge_id_maps.json`**

#### Step 3: Migrate Submissions & Related Data

```bash
python step3_migrate_submissions.py
```

- Imports 40 submissions with new sequential IDs
- Imports publications, authors, author_settings
- Imports citations, publication_settings
- Imports submission_files, file_settings, supplementary_files
- Imports stage_assignments, edit_decisions, submission_comments
- **Updates `merge_id_maps.json` with new mappings**

#### Step 4: Migrate Reviews

```bash
python step4_migrate_reviews.py
```

- Imports review_rounds with new IDs
- Imports review_assignments (with remapped review_form_id)
- Imports review_round_files, review_files
- Imports review_form_responses (with remapped element IDs)
- Updates edit_decisions.review_round_id (from step 3)
- Updates submission_files review_round references

#### Step 5: Migrate Logs & Miscellaneous

```bash
python step5_migrate_logs.py
```

- Imports queries + query_participants
- Imports notes (linked to queries)
- Imports event_log + event_log_settings
- Imports email_log + email_log_users
- Imports controlled_vocabs + entries + settings (keywords, subjects)
- Imports subeditor_submission_group

#### Step 6: Rename Submission Folders (Optional)

```bash
# First edit step6_rename_folders.py and set:
#   SOURCE_DIR = "/path/to/old/ojs/files"
#   TARGET_DIR = "/path/to/new/ojs/files"
#   DRY_RUN = True  (preview first!)

python step6_rename_folders.py   # Preview
# Then set DRY_RUN = False and run again to actually rename
```

- Renames/copies article folders from old submission IDs to new ones
- Handles `journals/{journal_id}/articles/{submission_id}/` directories

#### Step 6b: Fix Encoding & Locales

```bash
python step6b_fix_encoding.py
```

- **Part 1 (Primary):** Fixes empty locale ('') on `controlled_vocab_entry_settings` rows.
  Without this, PHP throws "Invalid argument supplied for foreach()" in
  `SubmissionKeywordDAO.inc.php` for migrated keywords/subjects.
- **Part 2 (Defensive):** Replaces raw Windows-1252 bytes (0x80-0x9F) in text columns
  with correct UTF-8 equivalents using MySQL native `REPLACE()`. This is a "belt and
  suspenders" measure — the primary fix is `connection_charset = utf8` in OJS config.

#### Step 6c: Convert Database Charset (latin1 → utf8mb4)

```bash
python step6c_convert_charset.py            # dry-run first (safe, lists columns)
python step6c_convert_charset.py --apply    # actually convert (BACKUP FIRST!)
```

- Converts all latin1 text columns to `utf8mb4` using a safe two-step ALTER
  (text → binary → text utf8mb4) that preserves existing byte content.
- After this, `connection_charset = utf8` in OJS config.inc.php works correctly
  without producing mojibake (e.g. `â€™` instead of `'`).
- **CRITICAL:** Take a full database backup before running with `--apply`.
- Safe to run multiple times (idempotent — skips already-converted columns).
- Use `--table TABLE_NAME` to test on a single table first.

#### Step 7: Verify Merge

```bash
python step7_verify_merge.py
```

- Compares row counts with old database
- Checks for orphaned records in all tables
- Validates all migrated data has correct relationships

---

## Files Created

| File                           | Purpose                                        |
| ------------------------------ | ---------------------------------------------- |
| `merge_config.py`              | Shared DB config and helper functions          |
| `step1_migrate_users.py`       | Import missing users                           |
| `step2_migrate_sections.py`    | Import sections, review forms, build mappings  |
| `step3_migrate_submissions.py` | Import submissions and core data               |
| `step4_migrate_reviews.py`     | Import review data                             |
| `step5_migrate_logs.py`        | Import logs, queries, controlled vocabs        |
| `step6_rename_folders.py`      | Rename article file directories                |
| `step6b_fix_encoding.py`       | Fix empty locales & encoding (post-migration)  |
| `step6c_convert_charset.py`    | Convert latin1 columns to utf8mb4              |
| `step7_verify_merge.py`        | Verify merge integrity                         |
| `merge_id_maps.json`           | Auto-generated ID mappings (created by step2+) |

## Rollback

If something goes wrong, the migration can be reversed by:

1. Deleting submissions where `submission_id > 525`
2. Deleting sections where `section_id > 1`
3. Deleting imported users
4. Or simply restoring the new DB from a backup

**⚠️ ALWAYS backup the new database before running the migration!**

```bash
mysqldump -h 127.0.0.1 -P 3376 -u root -prootpassword ojs > ojs_backup_before_merge.sql
```

## Troubleshooting

### "Could not load merge_id_maps.json"

Run the steps in order. Each step depends on the mappings from previous steps.

### Username/email conflicts

Step 1 will detect and report conflicts. Resolve them manually before proceeding.

### OJS shows broken submissions after merge

Run `step7_verify_merge.py` to identify orphaned records, then fix manually.

### Wrong file folders

Make sure you run step 6 to rename the article file directories.

### Blank workflow pages / JS error "Cannot read properties of null (reading 'status')"

This means PHP's `json_encode()` failed on the workflow data, returning `null` to the
JavaScript frontend. The root cause is raw Windows-1252 bytes (0x80-0x9F) in the database
being served as-is through a latin1 MySQL connection.

**Fix:** Add `connection_charset = utf8` under `[database]` in OJS's `config.inc.php`:

```ini
[database]
driver = mysqli
host = db
username = ojs
password = ojspassword
name = ojs
connection_charset = utf8
```

Then restart the app container. Step 6b provides an additional defensive fix by converting
the raw bytes in the database itself.

### PHP warning "Invalid argument supplied for foreach()" in SubmissionKeywordDAO

This is caused by migrated keywords/subjects having an empty locale string.
Run `step6b_fix_encoding.py` to fix it (Part 1 sets locale to the journal's primary_locale).

### Mojibake characters (â€™ instead of ' , â€" instead of –)

The database columns are declared `latin1` but contain UTF-8 byte sequences.
When `connection_charset = utf8` is set, MySQL re-encodes them, producing mojibake.

**Fix:** Run `step6c_convert_charset.py --apply` to convert all latin1 columns to
utf8mb4 (preserving the existing bytes). Then set `connection_charset = utf8` in
OJS config.inc.php. Both old and migrated data will display correctly.

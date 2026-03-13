-- =============================================================================
-- OJS DATABASE MERGE FIX
-- Fixes the broken merge between old DB (port 3386) and new DB (port 3376)
--
-- Target: 127.0.0.1:3376, dbname: ojs
-- Date: 2026-03-03
--
-- ROOT CAUSE ANALYSIS:
-- ====================
-- The merge broke because of several missing/mismatched data:
--
-- 1. MISSING USERS (66 users):
--    Old DB users were NOT imported to the new DB. These users are referenced
--    by stage_assignments, review_assignments, edit_decisions, email_log,
--    event_log, notes, query_participants, subeditor_submission_group, etc.
--    → OJS crashes when it tries to JOIN these tables with the users table.
--
-- 2. DUPLICATE USER_GROUPS (IDs 444-460):
--    The old DB had user_groups with IDs 444-460 (originally journal_id=27,
--    remapped to 1). These are exact duplicates of the new DB's groups 2-18.
--    The imported data (stage_assignments, authors, user_user_groups) references
--    the OLD group IDs (444-460) instead of the NEW ones (2-18).
--    → OJS shows wrong role labels or fails to filter by role correctly.
--
-- 3. MISSING GENRES (IDs 317-328):
--    The old DB had genres 317-328. These were NOT imported but are referenced
--    by 217 submission_files rows.
--    → Files appear with broken genre references.
--
-- 4. ORPHAN user_user_groups (30,122 rows):
--    Massive number of user_user_groups referencing user IDs that don't exist.
--    → Causes performance issues and potential OJS errors.
--
-- 5. OTHER ORPHAN DATA:
--    - edit_decisions with invalid editor_id (23 rows)
--    - email_log with invalid sender_id (74 rows)
--    - event_log with invalid user_id (503 rows)
--    - notes with invalid user_id (771 rows)
--    - query_participants with invalid user_id (39 rows)
--    - subeditor_submission_group with invalid user_id (3 rows)
--    - submission_files with invalid uploader_user_id (140 rows)
--
-- FIX STRATEGY:
-- =============
-- STEP 1: Import the 66 missing users + their settings from old DB
-- STEP 2: Remap user_group IDs from old (444-460) to new (2-18) in all tables
-- STEP 3: Remap genre IDs from old (317-328) to new (1-12) in submission_files
-- STEP 4: Clean up duplicate user_groups, user_group_settings, user_group_stage
-- STEP 5: Clean remaining orphan data
-- STEP 6: Verify data integrity
-- =============================================================================

-- ─────────────────────────────────────────────
-- SAFETY: Disable FK checks
-- ─────────────────────────────────────────────
SET FOREIGN_KEY_CHECKS = 0;
SET SQL_SAFE_UPDATES = 0;

-- ═══════════════════════════════════════════════
-- STEP 1: IMPORT MISSING USERS FROM OLD DB
-- ═══════════════════════════════════════════════
-- These 66 users exist in old DB (port 3386) but are missing from new DB (port 3376).
-- They are referenced by stage_assignments, review_assignments, edit_decisions, etc.
--
-- METHOD: Use DBeaver or mysqldump to export ONLY these users from the old DB:
--
--   1a. Export from old DB `users` table WHERE user_id IN (<list below>)
--   1b. Export from old DB `user_settings` table WHERE user_id IN (<list below>)
--   1c. Import both into the new DB (port 3376, ojs)
--
-- Missing user IDs (66 total):
-- 497, 3063, 3064, 3456, 3482, 3525, 3545, 3552, 3558, 3560, 3563, 3564,
-- 3567, 3568, 3570, 3584, 3589, 3594, 3598, 3602, 3612, 3621, 3624, 3626,
-- 3635, 3636, 3649, 3665, 3674, 3675, 3679, 3680, 3683, 3686, 3699, 3719,
-- 3723, 3737, 3740, 3746, 3753, 3754, 3756, 3758, 3760, 3777, 3835, 3883,
-- 3886, 3927, 3949, 4093, 4252, 4264, 4270, 4284, 4296, 4403, 4407, 4413,
-- 4451, 4500, 4529, 4537, 4577, 4585
--
-- No email/username collisions were found — safe to insert directly.
--
-- >>> RUN THE PYTHON SCRIPT: migrate_users.py (generated alongside this file) <<<
-- >>> OR use DBeaver to manually export/import the users listed above.        <<<
-- ─────────────────────────────────────────────


-- ═══════════════════════════════════════════════
-- STEP 2: REMAP USER_GROUP IDs (444→2, 445→3, ... 460→18)
-- ═══════════════════════════════════════════════
-- The old DB user_groups had IDs 444-460. The new DB already has identical groups
-- at IDs 2-18. We need to update all references from old IDs to new IDs.
--
-- Mapping (verified by matching role_id AND setting_name='name'):
--   444 (Journal manager)                 → 2
--   445 (Journal editor)                  → 3
--   446 (Production editor)               → 4
--   447 (Section editor)                  → 5
--   448 (Guest editor)                    → 6
--   449 (Copyeditor)                      → 7
--   450 (Designer)                        → 8
--   451 (Funding coordinator)             → 9
--   452 (Indexer)                         → 10
--   453 (Layout Editor)                   → 11
--   454 (Marketing and sales coordinator) → 12
--   455 (Proofreader)                     → 13
--   456 (Author)                          → 14
--   457 (Translator)                      → 15
--   458 (Reviewer)                        → 16
--   459 (Reader)                          → 17
--   460 (Subscription Manager)            → 18

-- 2a. stage_assignments
UPDATE stage_assignments SET user_group_id = 2  WHERE user_group_id = 444;
UPDATE stage_assignments SET user_group_id = 3  WHERE user_group_id = 445;
UPDATE stage_assignments SET user_group_id = 4  WHERE user_group_id = 446;
UPDATE stage_assignments SET user_group_id = 5  WHERE user_group_id = 447;
UPDATE stage_assignments SET user_group_id = 6  WHERE user_group_id = 448;
UPDATE stage_assignments SET user_group_id = 7  WHERE user_group_id = 449;
UPDATE stage_assignments SET user_group_id = 8  WHERE user_group_id = 450;
UPDATE stage_assignments SET user_group_id = 9  WHERE user_group_id = 451;
UPDATE stage_assignments SET user_group_id = 10 WHERE user_group_id = 452;
UPDATE stage_assignments SET user_group_id = 11 WHERE user_group_id = 453;
UPDATE stage_assignments SET user_group_id = 12 WHERE user_group_id = 454;
UPDATE stage_assignments SET user_group_id = 13 WHERE user_group_id = 455;
UPDATE stage_assignments SET user_group_id = 14 WHERE user_group_id = 456;
UPDATE stage_assignments SET user_group_id = 15 WHERE user_group_id = 457;
UPDATE stage_assignments SET user_group_id = 16 WHERE user_group_id = 458;
UPDATE stage_assignments SET user_group_id = 17 WHERE user_group_id = 459;
UPDATE stage_assignments SET user_group_id = 18 WHERE user_group_id = 460;

-- 2b. authors
UPDATE authors SET user_group_id = 2  WHERE user_group_id = 444;
UPDATE authors SET user_group_id = 3  WHERE user_group_id = 445;
UPDATE authors SET user_group_id = 4  WHERE user_group_id = 446;
UPDATE authors SET user_group_id = 5  WHERE user_group_id = 447;
UPDATE authors SET user_group_id = 6  WHERE user_group_id = 448;
UPDATE authors SET user_group_id = 7  WHERE user_group_id = 449;
UPDATE authors SET user_group_id = 8  WHERE user_group_id = 450;
UPDATE authors SET user_group_id = 9  WHERE user_group_id = 451;
UPDATE authors SET user_group_id = 10 WHERE user_group_id = 452;
UPDATE authors SET user_group_id = 11 WHERE user_group_id = 453;
UPDATE authors SET user_group_id = 12 WHERE user_group_id = 454;
UPDATE authors SET user_group_id = 13 WHERE user_group_id = 455;
UPDATE authors SET user_group_id = 14 WHERE user_group_id = 456;
UPDATE authors SET user_group_id = 15 WHERE user_group_id = 457;
UPDATE authors SET user_group_id = 16 WHERE user_group_id = 458;
UPDATE authors SET user_group_id = 17 WHERE user_group_id = 459;
UPDATE authors SET user_group_id = 18 WHERE user_group_id = 460;

-- 2c. user_user_groups
-- PK is (user_group_id, user_id). We use INSERT IGNORE + DELETE to avoid
-- duplicate key errors when a user already has the new group_id assigned.
INSERT IGNORE INTO user_user_groups (user_group_id, user_id) SELECT 2,  user_id FROM user_user_groups WHERE user_group_id = 444;
INSERT IGNORE INTO user_user_groups (user_group_id, user_id) SELECT 3,  user_id FROM user_user_groups WHERE user_group_id = 445;
INSERT IGNORE INTO user_user_groups (user_group_id, user_id) SELECT 4,  user_id FROM user_user_groups WHERE user_group_id = 446;
INSERT IGNORE INTO user_user_groups (user_group_id, user_id) SELECT 5,  user_id FROM user_user_groups WHERE user_group_id = 447;
INSERT IGNORE INTO user_user_groups (user_group_id, user_id) SELECT 6,  user_id FROM user_user_groups WHERE user_group_id = 448;
INSERT IGNORE INTO user_user_groups (user_group_id, user_id) SELECT 7,  user_id FROM user_user_groups WHERE user_group_id = 449;
INSERT IGNORE INTO user_user_groups (user_group_id, user_id) SELECT 8,  user_id FROM user_user_groups WHERE user_group_id = 450;
INSERT IGNORE INTO user_user_groups (user_group_id, user_id) SELECT 9,  user_id FROM user_user_groups WHERE user_group_id = 451;
INSERT IGNORE INTO user_user_groups (user_group_id, user_id) SELECT 10, user_id FROM user_user_groups WHERE user_group_id = 452;
INSERT IGNORE INTO user_user_groups (user_group_id, user_id) SELECT 11, user_id FROM user_user_groups WHERE user_group_id = 453;
INSERT IGNORE INTO user_user_groups (user_group_id, user_id) SELECT 12, user_id FROM user_user_groups WHERE user_group_id = 454;
INSERT IGNORE INTO user_user_groups (user_group_id, user_id) SELECT 13, user_id FROM user_user_groups WHERE user_group_id = 455;
INSERT IGNORE INTO user_user_groups (user_group_id, user_id) SELECT 14, user_id FROM user_user_groups WHERE user_group_id = 456;
INSERT IGNORE INTO user_user_groups (user_group_id, user_id) SELECT 15, user_id FROM user_user_groups WHERE user_group_id = 457;
INSERT IGNORE INTO user_user_groups (user_group_id, user_id) SELECT 16, user_id FROM user_user_groups WHERE user_group_id = 458;
INSERT IGNORE INTO user_user_groups (user_group_id, user_id) SELECT 17, user_id FROM user_user_groups WHERE user_group_id = 459;
INSERT IGNORE INTO user_user_groups (user_group_id, user_id) SELECT 18, user_id FROM user_user_groups WHERE user_group_id = 460;
-- The old group_id rows (444-460) will be cleaned in Step 5b.

-- 2d. subeditor_submission_group (no user_group_id column, uses assoc_type=530, ok)

-- 2e. review_assignments (has user_group_id? check)
-- review_assignments does NOT have user_group_id, it uses reviewer_id → users


-- ═══════════════════════════════════════════════
-- STEP 3: REMAP GENRE IDs (317→1, 318→2, ... 328→12)
-- ═══════════════════════════════════════════════
-- Old DB genres 317-328 map 1:1 to new DB genres 1-12 (same names, same order).
--
-- Mapping:
--   317 (Article Text)        → 1
--   318 (Research Instrument) → 2
--   319 (Research Materials)  → 3
--   320 (Research Results)    → 4
--   321 (Transcripts)         → 5
--   322 (Data Analysis)       → 6
--   323 (Data Set)            → 7
--   324 (Source Texts)        → 8
--   325 (Multimedia)          → 9
--   326 (Image)               → 10
--   327 (HTML Stylesheet)     → 11
--   328 (Other)               → 12

UPDATE submission_files SET genre_id = 1  WHERE genre_id = 317;
UPDATE submission_files SET genre_id = 2  WHERE genre_id = 318;
UPDATE submission_files SET genre_id = 3  WHERE genre_id = 319;
UPDATE submission_files SET genre_id = 4  WHERE genre_id = 320;
UPDATE submission_files SET genre_id = 5  WHERE genre_id = 321;
UPDATE submission_files SET genre_id = 6  WHERE genre_id = 322;
UPDATE submission_files SET genre_id = 7  WHERE genre_id = 323;
UPDATE submission_files SET genre_id = 8  WHERE genre_id = 324;
UPDATE submission_files SET genre_id = 9  WHERE genre_id = 325;
UPDATE submission_files SET genre_id = 10 WHERE genre_id = 326;
UPDATE submission_files SET genre_id = 11 WHERE genre_id = 327;
UPDATE submission_files SET genre_id = 12 WHERE genre_id = 328;


-- ═══════════════════════════════════════════════
-- STEP 4: REMOVE DUPLICATE USER_GROUPS (444-460)
-- ═══════════════════════════════════════════════
-- After remapping all references, the old user_groups 444-460 are no longer
-- referenced. Remove them and their settings.

-- 4a. Remove old user_group_settings
DELETE FROM user_group_settings WHERE user_group_id >= 444 AND user_group_id <= 460;

-- 4b. Remove old user_group_stage entries
DELETE FROM user_group_stage WHERE user_group_id >= 444 AND user_group_id <= 460;

-- 4c. Remove old user_groups
DELETE FROM user_groups WHERE user_group_id >= 444 AND user_group_id <= 460;


-- ═══════════════════════════════════════════════
-- STEP 5: CLEAN UP ORPHAN DATA
-- ═══════════════════════════════════════════════
-- NOTE: Run this AFTER Step 1 (importing missing users).
--       After importing users, most orphans will be resolved.
--       These statements handle any remaining orphans.

-- 5a. Clean user_user_groups with non-existent users
DELETE FROM user_user_groups
WHERE user_id NOT IN (SELECT user_id FROM users);

-- 5b. user_user_groups has composite PK (user_group_id, user_id).
-- After remapping from 444→2, 445→3, etc., there may be duplicate key conflicts.
-- The UPDATE in Step 2c will skip rows that cause duplicate key errors.
-- Any remaining rows with old group IDs should be cleaned:
DELETE FROM user_user_groups WHERE user_group_id >= 444 AND user_group_id <= 460;

-- 5c. Clean stage_assignments with invalid user_id (if any remain after user import)
DELETE FROM stage_assignments
WHERE user_id NOT IN (SELECT user_id FROM users);

-- 5d. Clean review_assignments with invalid reviewer_id
DELETE FROM review_assignments
WHERE reviewer_id NOT IN (SELECT user_id FROM users);

-- 5e. Clean edit_decisions with invalid editor_id
DELETE FROM edit_decisions
WHERE editor_id NOT IN (SELECT user_id FROM users);

-- 5f. Clean email_log with invalid sender_id
UPDATE email_log SET sender_id = 0
WHERE sender_id IS NOT NULL AND sender_id != 0
AND sender_id NOT IN (SELECT user_id FROM users);

-- 5g. Clean event_log with invalid user_id
UPDATE event_log SET user_id = 0
WHERE user_id IS NOT NULL AND user_id != 0
AND user_id NOT IN (SELECT user_id FROM users);

-- 5h. Clean notes with invalid user_id
DELETE FROM notes
WHERE user_id NOT IN (SELECT user_id FROM users);

-- 5i. Clean email_log_users with invalid user_id
DELETE FROM email_log_users
WHERE user_id NOT IN (SELECT user_id FROM users);

-- 5j. Clean query_participants with invalid user_id
DELETE FROM query_participants
WHERE user_id NOT IN (SELECT user_id FROM users);

-- 5k. Clean queries that have NO participants left
DELETE FROM queries
WHERE query_id NOT IN (SELECT query_id FROM query_participants);

-- 5l. Clean subeditor_submission_group with invalid user_id
DELETE FROM subeditor_submission_group
WHERE user_id NOT IN (SELECT user_id FROM users);

-- 5m. Clean submission_files with invalid uploader_user_id
-- Set to admin user (user_id=1) rather than deleting files
UPDATE submission_files SET uploader_user_id = 1
WHERE uploader_user_id NOT IN (SELECT user_id FROM users);

-- 5n. Clean user_settings for non-existent users
DELETE FROM user_settings
WHERE user_id NOT IN (SELECT user_id FROM users);

-- 5o. Clean notification_subscription_settings for non-existent users
DELETE FROM notification_subscription_settings
WHERE user_id NOT IN (SELECT user_id FROM users);


-- ═══════════════════════════════════════════════
-- STEP 6: VERIFY DATA INTEGRITY
-- ═══════════════════════════════════════════════

-- 6a. Check for remaining orphan references
SELECT 'stage_assignments → users' as chk,
  COUNT(*) as orphans
FROM stage_assignments sa
WHERE NOT EXISTS (SELECT 1 FROM users u WHERE u.user_id = sa.user_id)

UNION ALL SELECT 'stage_assignments → user_groups',
  COUNT(*)
FROM stage_assignments sa
WHERE NOT EXISTS (SELECT 1 FROM user_groups ug WHERE ug.user_group_id = sa.user_group_id)

UNION ALL SELECT 'stage_assignments → submissions',
  COUNT(*)
FROM stage_assignments sa
WHERE NOT EXISTS (SELECT 1 FROM submissions s WHERE s.submission_id = sa.submission_id)

UNION ALL SELECT 'review_assignments → users',
  COUNT(*)
FROM review_assignments ra
WHERE NOT EXISTS (SELECT 1 FROM users u WHERE u.user_id = ra.reviewer_id)

UNION ALL SELECT 'review_assignments → review_rounds',
  COUNT(*)
FROM review_assignments ra
WHERE NOT EXISTS (SELECT 1 FROM review_rounds rr WHERE rr.review_round_id = ra.review_round_id)

UNION ALL SELECT 'edit_decisions → users',
  COUNT(*)
FROM edit_decisions ed
WHERE NOT EXISTS (SELECT 1 FROM users u WHERE u.user_id = ed.editor_id)

UNION ALL SELECT 'authors → publications',
  COUNT(*)
FROM authors a
WHERE a.publication_id IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM publications p WHERE p.publication_id = a.publication_id)

UNION ALL SELECT 'authors → user_groups',
  COUNT(*)
FROM authors a
WHERE a.user_group_id IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM user_groups ug WHERE ug.user_group_id = a.user_group_id)

UNION ALL SELECT 'publications → submissions',
  COUNT(*)
FROM publications p
WHERE NOT EXISTS (SELECT 1 FROM submissions s WHERE s.submission_id = p.submission_id)

UNION ALL SELECT 'submissions → sections',
  COUNT(*)
FROM submissions s
WHERE s.section_id IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sections sec WHERE sec.section_id = s.section_id)

UNION ALL SELECT 'submission_files → genres',
  COUNT(*)
FROM submission_files sf
WHERE sf.genre_id IS NOT NULL AND sf.genre_id != 0
AND NOT EXISTS (SELECT 1 FROM genres g WHERE g.genre_id = sf.genre_id)

UNION ALL SELECT 'submission_files → users (uploader)',
  COUNT(*)
FROM submission_files sf
WHERE sf.uploader_user_id IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM users u WHERE u.user_id = sf.uploader_user_id)

UNION ALL SELECT 'user_user_groups → users',
  COUNT(*)
FROM user_user_groups uug
WHERE NOT EXISTS (SELECT 1 FROM users u WHERE u.user_id = uug.user_id)

UNION ALL SELECT 'user_user_groups → user_groups',
  COUNT(*)
FROM user_user_groups uug
WHERE NOT EXISTS (SELECT 1 FROM user_groups ug WHERE ug.user_group_id = uug.user_group_id)

UNION ALL SELECT 'duplicate user_groups (444-460)',
  COUNT(*)
FROM user_groups WHERE user_group_id >= 444 AND user_group_id <= 460;

-- ALL rows above should show 0 orphans.

-- 6b. Check submission counts
SELECT 'Total submissions' as metric, COUNT(*) as val FROM submissions
UNION ALL SELECT 'Active (status=1)', COUNT(*) FROM submissions WHERE status = 1
UNION ALL SELECT 'Published (status=3)', COUNT(*) FROM submissions WHERE status = 3
UNION ALL SELECT 'Declined (status=4)', COUNT(*) FROM submissions WHERE status = 4
UNION ALL SELECT 'Imported submissions (id>=4244)', COUNT(*) FROM submissions WHERE submission_id >= 4244;


-- ─────────────────────────────────────────────
-- RE-ENABLE FK checks
-- ─────────────────────────────────────────────
SET FOREIGN_KEY_CHECKS = 1;
SET SQL_SAFE_UPDATES = 1;

-- ═══════════════════════════════════════════════
-- DONE! Test the OJS website:
-- 1. Open localhost (new OJS)
-- 2. Go to Submissions page
-- 3. Check "All Active" tab — should show active submissions
-- 4. Check "Archives" tab — should show published/declined submissions
-- 5. Check "Unassigned" tab — should show unassigned submissions
-- 6. Click into individual submissions to verify details load
-- ═══════════════════════════════════════════════

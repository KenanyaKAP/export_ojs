# Migration Plan: Submission 4244

> Source: Port 3386 | Database: `ojs` | Journal context_id: 27
>
> Title: **JADWAL EAS PRODI SARJANA GASAL 24-25 DTE**
> Author: **Agatha Rama Annata** (agatha.rama@its.ac.id)
> Status: 4 (Declined/Archived) | Stage: 5 (Production)
> Published in Issue ID: 415

---

## Users Involved (MUST EXIST in target DB first!)

| user_id | username    | email                   | Role in this submission       |
| ------- | ----------- | ----------------------- | ----------------------------- |
| 3482    | agatha_rama | agatha.rama@its.ac.id   | Author (submitter)            |
| 3064    | prasetiyono | prasetiyono@its.ac.id   | Editor                        |
| 3531    | vitagrum    | lystianingrum@its.ac.id | Reviewer                      |
| 3594    | rahmaadista | rahmaadista10@gmail.com | Production (uploaded galleys) |

⚠️ **These users must be created first in the target DB. Their user_ids will likely be DIFFERENT, so you'll need to remap ALL user_id references below.**

---

## Migration Order & Data

Tables must be inserted in this order due to dependencies:

```
PHASE 1: Core (no dependencies on other submission data)
  ├─ 1. submissions              (1 row)
  ├─ 2. submission_settings      (0 rows - empty)
  └─ 3. publications             (1 row)

PHASE 2: Publication metadata
  ├─ 4. publication_settings     (9 rows)
  ├─ 5. authors                  (1 row)
  ├─ 6. author_settings          (4 rows)
  ├─ 7. citations                (0 rows - empty)
  ├─ 8. publication_categories   (0 rows - empty)
  └─ 9. controlled_vocabs +      (5 vocab rows, 0 entries - all empty keywords)
        controlled_vocab_entries
        controlled_vocab_entry_settings

PHASE 3: Files (depends on submissions)
  └─ 10. submission_files        (21 rows across 13 file_ids)
         submission_file_settings (13 rows)

PHASE 4: Review process (depends on submissions + files)
  ├─ 11. review_rounds           (2 rows)
  ├─ 12. review_round_files      (5 rows)
  ├─ 13. review_assignments      (2 rows)
  ├─ 14. review_files            (2 rows)
  └─ 15. review_form_responses   (14 rows)

PHASE 5: Editorial workflow
  ├─ 16. edit_decisions           (9 rows)
  ├─ 17. stage_assignments        (3 rows)
  ├─ 18. queries                  (4 rows)
  └─ 19. query_participants       (6 rows)

PHASE 6: Galleys (depends on publications + files)
  ├─ 20. publication_galleys      (0 rows - no galleys yet!)
  └─ 21. publication_galley_settings (0 rows)

PHASE 7: Logs & notifications (optional, can skip)
  ├─ 22. event_log               (45 rows)
  ├─ 23. event_log_settings      (176 rows)
  ├─ 24. email_log               (12 rows)
  ├─ 25. email_log_users         (12 rows)
  └─ 26. notifications           (6 rows)

PHASE 8: Metrics (optional)
  └─ 27. metrics                 (1 row)
```

---

## Detailed Row Data

### 1. `submissions` (1 row)

```sql
INSERT INTO submissions (submission_id, locale, context_id, section_id,
  current_publication_id, date_last_activity, date_submitted, last_modified,
  stage_id, status, submission_progress, work_type)
VALUES (
  4244,           -- ⚠️ REMAP to new ID
  NULL,
  27,             -- ⚠️ REMAP to target journal context_id
  NULL,
  4245,           -- ⚠️ REMAP after inserting publications
  '2025-06-27 09:42:27',
  '2025-05-15 08:51:52',
  '2025-05-29 23:39:13',
  5,              -- stage: Production
  4,              -- status: Declined
  0,
  0
);
```

### 2. `publications` (1 row)

```sql
INSERT INTO publications (publication_id, access_status, date_published,
  last_modified, locale, primary_contact_id, section_id, seq, submission_id,
  status, url_path, version)
VALUES (
  4245,           -- ⚠️ REMAP to new ID
  0,
  '2025-06-27',
  '2025-06-27 09:41:43',
  'en_US',
  12735,          -- ⚠️ REMAP after inserting authors
  36,             -- ⚠️ REMAP to target section_id
  0,
  4244,           -- ⚠️ REMAP to new submission_id
  1,
  NULL,
  1
);
```

### 3. `publication_settings` (9 rows)

```sql
INSERT INTO publication_settings (publication_id, locale, setting_name, setting_value) VALUES
(4245, '',      'categoryIds',    'a:0:{}'),
(4245, '',      'copyrightYear',  '2025'),
(4245, '',      'issueId',        '415'),          -- ⚠️ REMAP to target issue_id
(4245, '',      'licenseUrl',     'https://creativecommons.org/licenses/by-nc/4.0'),
(4245, 'en_US', 'abstract',       '<p>Jadwal EAS Prodi Sarjana Gasal 24-25 DTE</p>'),
(4245, 'en_US', 'copyrightHolder','Agatha Rama Annata'),
(4245, 'en_US', 'prefix',         ''),
(4245, 'en_US', 'subtitle',       ''),
(4245, 'en_US', 'title',          'JADWAL EAS PRODI SARJANA GASAL 24-25 DTE');
-- ⚠️ REMAP publication_id in all rows
```

### 4. `authors` (1 row)

```sql
INSERT INTO authors (author_id, email, include_in_browse, publication_id,
  submission_id, seq, user_group_id)
VALUES (
  12735,          -- ⚠️ REMAP to new ID
  'agatha.rama@its.ac.id',
  1,
  4245,           -- ⚠️ REMAP
  NULL,
  0,
  456             -- ⚠️ REMAP to target user_group_id for "Author"
);
```

### 5. `author_settings` (4 rows)

```sql
INSERT INTO author_settings (author_id, locale, setting_name, setting_value, setting_type) VALUES
(12735, '',      'country',     'ID',                                  NULL),
(12735, 'en_US', 'affiliation', 'Institut Teknologi Sepuluh Nopember', NULL),
(12735, 'en_US', 'familyName',  '',                                    NULL),
(12735, 'en_US', 'givenName',   'Agatha Rama Annata',                  NULL);
-- ⚠️ REMAP author_id in all rows
```

### 6. `submission_files` (21 rows, 13 distinct file_ids)

File IDs: **14741, 15026, 15184, 15199, 15578, 15579, 15581, 15583, 15584, 15591, 15592, 15593, 16760**

| file_id | revision(s) | file_stage             | original_file_name               | uploader |
| ------- | ----------- | ---------------------- | -------------------------------- | -------- |
| 14741   | 1, 2        | 2 (Submission)         | paper.pdf → JADWAL EAS...pdf     | 3482     |
| 15026   | 1           | 4 (Review)             | JADWAL EAS...pdf                 | 3482     |
| 15184   | 1           | 15 (Production Ready)  | Daftar Hadir...pdf               | 3482     |
| 15199   | 1           | 4 (Review)             | Daftar Hadir...pdf               | 3482     |
| 15578   | 2, 3        | 15                     | Panduan Penggunaan Anydesk...pdf | 3482     |
| 15579   | 1           | 18 (Review Attachment) | Response to reviewers...docx     | 3482     |
| 15581   | 1-7         | 15                     | Various files (.pdf, .docx)      | 3482     |
| 15583   | 1           | 18 (Review Attachment) | Response to reviewers...docx     | 3482     |
| 15584   | 1           | 15                     | Response to reviewers...docx     | 3482     |
| 15591   | 1           | 6 (Copyediting)        | Alat untuk pengujian...docx      | 3482     |
| 15592   | 1           | 9 (Production)         | 4244-Article Text...pdf          | 3594     |
| 15593   | 1           | 11 (Production Ready)  | 4244-Article Text...pdf          | 3594     |
| 16760   | 1           | 11 (Production Ready)  | 4244-Article Text...pdf          | 3594     |

⚠️ **REMAP all**: `file_id`, `submission_id`, `source_file_id`, `uploader_user_id`

⚠️ **ALSO COPY THE ACTUAL FILES** from the filesystem:

```
files/journals/27/articles/4244/
```

### 7. `submission_file_settings` (13 rows)

One row per file_id with `setting_name = 'name'`.
⚠️ REMAP all `file_id` values.

### 8. `review_rounds` (2 rows)

```sql
INSERT INTO review_rounds (review_round_id, submission_id, stage_id, round, review_revision, status) VALUES
(1258, 4244, 3, 1, NULL, 6),   -- Round 1, status: Pending Reviews
(1274, 4244, 3, 2, NULL, 5);   -- Round 2, status: Review Accepted
-- ⚠️ REMAP review_round_id, submission_id
```

### 9. `review_round_files` (5 rows)

```sql
INSERT INTO review_round_files (submission_id, review_round_id, stage_id, file_id, revision) VALUES
(4244, 1258, 3, 15026, 1),
(4244, 1258, 3, 15184, 1),
(4244, 1274, 3, 15199, 1),
(4244, 1274, 3, 15581, 1),
(4244, 1274, 3, 15584, 1);
-- ⚠️ REMAP submission_id, review_round_id, file_id
```

### 10. `review_assignments` (2 rows)

```sql
INSERT INTO review_assignments (review_id, submission_id, reviewer_id,
  competing_interests, recommendation, date_assigned, date_notified,
  date_confirmed, date_completed, date_acknowledged, date_due,
  date_response_due, last_modified, reminder_was_automatic, declined,
  cancelled, reviewer_file_id, date_rated, date_reminded, quality,
  review_round_id, stage_id, review_method, round, step,
  review_form_id, unconsidered)
VALUES
-- Reviewer vitagrum (user 3531), Round 1: Recommended "Accept" (2)
(2157, 4244, 3531, NULL, 2,
 '2025-05-24 11:26:11', '2025-05-24 11:26:11', '2025-05-26 00:08:31',
 '2025-05-26 00:09:36', NULL, '2025-06-21 00:00:00', '2025-06-21 00:00:00',
 '2025-05-26 00:09:36', 0, 0, 0, NULL, NULL, NULL, NULL,
 1258, 3, 1, 1, 4, 13, 0),

-- Reviewer vitagrum (user 3531), Round 2: Recommended "Accept" (1)
(2179, 4244, 3531, NULL, 1,
 '2025-05-29 23:39:13', '2025-05-29 23:39:13', '2025-06-01 23:54:25',
 '2025-06-02 00:16:20', NULL, '2025-06-05 00:00:00', '2025-06-01 00:00:00',
 '2025-06-02 00:16:20', 0, 0, 0, NULL, NULL, NULL, NULL,
 1274, 3, 1, 2, 4, 13, 0);
-- ⚠️ REMAP: review_id, submission_id, reviewer_id, review_round_id, review_form_id
```

### 11. `review_files` (2 rows)

```sql
INSERT INTO review_files (review_id, file_id) VALUES
(2157, 15026),
(2179, 15199);
-- ⚠️ REMAP review_id, file_id
```

### 12. `review_form_responses` (14 rows)

```sql
INSERT INTO review_form_responses (review_form_element_id, review_id, response_type, response_value) VALUES
-- Reviewer Round 1 (review_id 2157)
(75, 2157, 'int', '2'),
(76, 2157, 'int', '2'),
(77, 2157, 'int', '1'),
(78, 2157, 'int', '3'),
(79, 2157, 'int', '2'),
(80, 2157, 'string', 'This paper is good and can be accepted. This is a test review.'),
(81, 2157, 'string', ''),
-- Reviewer Round 2 (review_id 2179)
(75, 2179, 'int', '2'),
(76, 2179, 'int', '2'),
(77, 2179, 'int', '2'),
(78, 2179, 'int', '2'),
(79, 2179, 'int', '2'),
(80, 2179, 'string', 'This simulation paper is already good and can proceed for acceptance.'),
(81, 2179, 'string', '');
-- ⚠️ REMAP: review_form_element_id (must match target review_form), review_id
```

### 13. `edit_decisions` (9 rows)

```sql
INSERT INTO edit_decisions (edit_decision_id, submission_id, review_round_id,
  stage_id, round, editor_id, decision, date_decided) VALUES
(4774, 4244, 0,    1, 0, 3064, 8,  '2025-05-23 10:28:23'),  -- Send to Review
(4794, 4244, 1258, 3, 1, 3064, 3,  '2025-05-28 10:34:42'),  -- Revisions Required
(4815, 4244, 1258, 3, 1, 3064, 16, '2025-05-29 23:37:22'),  -- New Review Round
(4866, 4244, 1274, 3, 2, 3064, 2,  '2025-06-04 10:46:40'),  -- Accept
(4868, 4244, 1274, 3, 2, 3064, 2,  '2025-06-05 02:05:19'),  -- Accept (again)
(4869, 4244, 1274, 3, 2, 3064, 1,  '2025-06-05 03:46:11'),  -- Accept (final)
(4955, 4244, 0,    1, 0, 3531, 9,  '2025-06-23 01:49:22'),  -- Recommendation
(4982, 4244, 0,    4, 0, 3064, 7,  '2025-06-27 09:20:41'),  -- Send to Production
(4983, 4244, 1274, 3, 2, 3064, 4,  '2025-06-27 09:42:27');  -- Decline
-- ⚠️ REMAP: edit_decision_id, submission_id, review_round_id, editor_id
```

### 14. `stage_assignments` (3 rows)

```sql
INSERT INTO stage_assignments (stage_assignment_id, submission_id, user_group_id,
  user_id, date_assigned, recommend_only, can_change_metadata) VALUES
(6666, 4244, 456, 3482, '2025-05-15 01:16:58', 0, 0),  -- Author
(6838, 4244, 447, 3064, '2025-05-23 10:22:49', 0, 1),  -- Editor (section)
(8412, 4244, 445, 3064, '2025-06-27 09:22:46', 0, 1);  -- Editor (production)
-- ⚠️ REMAP: stage_assignment_id, submission_id, user_group_id, user_id
```

### 15. `queries` (4 rows)

```sql
INSERT INTO queries (query_id, assoc_type, assoc_id, stage_id, seq,
  date_posted, date_modified, closed) VALUES
(3847, 1048585, 4244, 1, 1, NULL, NULL, 0),  -- Submission stage discussion
(3928, 1048585, 4244, 3, 2, NULL, NULL, 0),  -- Review stage discussion
(3929, 1048585, 4244, 3, 3, NULL, NULL, 0),  -- Review stage discussion
(4101, 1048585, 4244, 5, 4, NULL, NULL, 0);  -- Production stage discussion
-- ⚠️ REMAP: query_id, assoc_id (= submission_id)
```

### 16. `query_participants` (6 rows)

```sql
INSERT INTO query_participants (query_id, user_id) VALUES
(3847, 3064),
(3928, 3064),
(3928, 3482),
(3929, 3064),
(3929, 3482),
(4101, 3064);
-- ⚠️ REMAP: query_id, user_id
```

### 17. `controlled_vocabs` (5 rows, all empty)

```sql
INSERT INTO controlled_vocabs (controlled_vocab_id, symbolic, assoc_type, assoc_id) VALUES
(21229, 'submissionKeyword',    1048588, 4245),
(21230, 'submissionSubject',    1048588, 4245),
(21231, 'submissionDiscipline', 1048588, 4245),
(21232, 'submissionLanguage',   1048588, 4245),
(21233, 'submissionAgency',     1048588, 4245);
-- ⚠️ REMAP: controlled_vocab_id, assoc_id (= publication_id)
-- Note: assoc_type 1048588 = ASSOC_TYPE_PUBLICATION
-- No entries (keywords are empty)
```

---

## Optional: Logs & Notifications (Can Skip)

| Table                   | Rows | Notes              |
| ----------------------- | ---- | ------------------ |
| `event_log`             | 45   | Audit trail events |
| `event_log_settings`    | 176  | Event details      |
| `email_log`             | 12   | Email history      |
| `email_log_users`       | 12   | Email recipients   |
| `notifications`         | 6    | User notifications |
| `notification_settings` | 0    | No settings        |

These are historical logs. You can skip them for a functional migration — the submission will work fine without them. But if you want full history, include them.

---

## Empty Tables (No Data for This Submission)

| Table                            | Status                                           |
| -------------------------------- | ------------------------------------------------ |
| `submission_settings`            | Empty                                            |
| `publication_galleys`            | ⚠️ **No galleys!** (no final PDF for readers)    |
| `publication_galley_settings`    | Empty                                            |
| `citations`                      | Empty (no references)                            |
| `publication_categories`         | Empty                                            |
| `submission_comments`            | Empty                                            |
| `submission_artwork_files`       | Empty                                            |
| `submission_supplementary_files` | Empty                                            |
| `library_files`                  | Empty                                            |
| `notes`                          | Empty (discussion threads exist but no messages) |

---

## ⚠️ CRITICAL: What You MUST Remap

When inserting into the target database, these IDs will be **different**:

| Source ID Type           | Source Value  | Must Remap To         | Notes                                             |
| ------------------------ | ------------- | --------------------- | ------------------------------------------------- |
| `submission_id`          | 4244          | New auto-increment    | Central ID everything references                  |
| `publication_id`         | 4245          | New auto-increment    | Update `submissions.current_publication_id` after |
| `author_id`              | 12735         | New auto-increment    | Update `publications.primary_contact_id` after    |
| `context_id` (journal)   | 27            | Target journal ID     |                                                   |
| `section_id`             | 36            | Target section ID     | Must exist in target                              |
| `issue_id`               | 415           | Target issue ID       | In `publication_settings`                         |
| `user_group_id`          | 445, 447, 456 | Target user_group_ids | Match by role name                                |
| `user_id` 3482           | agatha_rama   | Target user_id        | Match by email                                    |
| `user_id` 3064           | prasetiyono   | Target user_id        | Match by email                                    |
| `user_id` 3531           | vitagrum      | Target user_id        | Match by email                                    |
| `user_id` 3594           | rahmaadista   | Target user_id        | Match by email                                    |
| `genre_id`               | 317           | Target genre_id       | Match by entry_key                                |
| `review_form_id`         | 13            | Target review_form_id | Match by name                                     |
| `review_form_element_id` | 75-81         | Target element IDs    | Match by seq/form                                 |
| `review_round_id`        | 1258, 1274    | New auto-increment    |                                                   |
| `review_id`              | 2157, 2179    | New auto-increment    |                                                   |
| `edit_decision_id`       | Various       | New auto-increment    |                                                   |
| All `file_id` values     | 14741-16760   | New auto-increment    | Also remap `source_file_id`                       |
| `stage_assignment_id`    | Various       | New auto-increment    |                                                   |
| `query_id`               | 3847-4101     | New auto-increment    |                                                   |
| `controlled_vocab_id`    | 21229-21233   | New auto-increment    |                                                   |

---

## ⚠️ Don't Forget: Physical Files!

The actual PDF/DOCX files are stored on disk, NOT in the database!

```
Source filesystem path (typical OJS layout):
  files/journals/27/articles/4244/submission/...     (file_stage 2)
  files/journals/27/articles/4244/submission/review/ (file_stage 4)
  files/journals/27/articles/4244/submission/proof/  (file_stage 15)
  files/journals/27/articles/4244/submission/copyedit/ (file_stage 6)
  files/journals/27/articles/4244/submission/productionReady/ (file_stage 9, 11)

Copy these to the target server with the new submission_id path.
```

---

## Summary: Row Count

| Table                    | Rows          | Critical?      |
| ------------------------ | ------------- | -------------- |
| submissions              | 1             | ✅ Essential   |
| publications             | 1             | ✅ Essential   |
| publication_settings     | 9             | ✅ Essential   |
| authors                  | 1             | ✅ Essential   |
| author_settings          | 4             | ✅ Essential   |
| submission_files         | 21            | ✅ Essential   |
| submission_file_settings | 13            | ✅ Essential   |
| review_rounds            | 2             | ✅ Essential   |
| review_round_files       | 5             | ✅ Essential   |
| review_assignments       | 2             | ✅ Essential   |
| review_files             | 2             | ✅ Essential   |
| review_form_responses    | 14            | ✅ Essential   |
| edit_decisions           | 9             | ✅ Essential   |
| stage_assignments        | 3             | ✅ Essential   |
| queries                  | 4             | ⚡ Recommended |
| query_participants       | 6             | ⚡ Recommended |
| controlled_vocabs        | 5             | ⚡ Recommended |
| event_log                | 45            | 📋 Optional    |
| event_log_settings       | 176           | 📋 Optional    |
| email_log                | 12            | 📋 Optional    |
| email_log_users          | 12            | 📋 Optional    |
| notifications            | 6             | 📋 Optional    |
| metrics                  | 1             | 📋 Optional    |
| **TOTAL**                | **~349 rows** |                |

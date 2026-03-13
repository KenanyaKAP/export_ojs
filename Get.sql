-- Step 1
SELECT * FROM submissions WHERE submission_id = 4710\G

-- Step 2
SELECT * FROM publications WHERE submission_id = 4710\G

-- Step 3
SELECT * FROM publication_settings WHERE publication_id = 4716\G

-- Step 4
SELECT * FROM authors WHERE publication_id = 4716\G
SELECT * FROM author_settings WHERE author_id IN
  (SELECT author_id FROM authors WHERE publication_id = 4716)\G

-- Step 5
SELECT 'SUBMITTER' AS role, user_id FROM stage_assignments WHERE submission_id = 4710
UNION
SELECT 'REVIEWER', reviewer_id FROM review_assignments WHERE submission_id = 4710
UNION
SELECT 'EDITOR', editor_id FROM edit_decisions WHERE submission_id = 4710
UNION
SELECT 'FILE_UPLOADER', uploader_user_id FROM submission_files WHERE submission_id = 4710;

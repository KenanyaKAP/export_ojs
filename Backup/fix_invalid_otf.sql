-- ============================================================================
-- COMPREHENSIVE FIX: Invalid UTF-8 Characters in OJS Database
-- ============================================================================
-- Converts ALL Windows-1252 bytes (0x80-0x9F) to proper UTF-8 equivalents
-- across ALL affected tables found by full database scan.
--
-- Affected tables (18 total):
--   publication_settings, author_settings, citations,
--   user_settings (13899), email_log (234), email_templates_default_data (146),
--   notes (72), review_form_responses (54), submission_search_keyword_list (48),
--   submission_file_settings (10), submission_comments (3), rt_searches (3),
--   submission_files (2), controlled_vocab_entry_settings (1),
--   journal_settings (1), plugin_settings (1), static_page_settings (1)
-- ============================================================================

SET NAMES utf8mb4;

-- ============================================================================
-- HELPER: Windows-1252 to Unicode mapping (applied per table.column)
-- 0x80 -> U+20AC (Euro sign)
-- 0x82 -> U+201A (Single low-9 quotation mark)
-- 0x83 -> U+0192 (Latin small f with hook)
-- 0x84 -> U+201E (Double low-9 quotation mark)
-- 0x85 -> U+2026 (Horizontal ellipsis)
-- 0x86 -> U+2020 (Dagger)
-- 0x87 -> U+2021 (Double dagger)
-- 0x88 -> U+02C6 (Modifier letter circumflex accent)
-- 0x89 -> U+2030 (Per mille sign)
-- 0x8A -> U+0160 (Latin capital S with caron)
-- 0x8B -> U+2039 (Single left-pointing angle quotation mark)
-- 0x8C -> U+0152 (Latin capital ligature OE)
-- 0x8D -> (remove - undefined)
-- 0x8E -> U+017D (Latin capital Z with caron)
-- 0x8F -> (remove - undefined)
-- 0x90 -> (remove - undefined)
-- 0x91 -> U+2018 (Left single quotation mark)
-- 0x92 -> U+2019 (Right single quotation mark)
-- 0x93 -> U+201C (Left double quotation mark)
-- 0x94 -> U+201D (Right double quotation mark)
-- 0x95 -> U+2022 (Bullet)
-- 0x96 -> U+2013 (En dash)
-- 0x97 -> U+2014 (Em dash)
-- 0x98 -> U+02DC (Small tilde)
-- 0x99 -> U+2122 (Trade mark sign)
-- 0x9A -> U+0161 (Latin small s with caron)
-- 0x9B -> U+203A (Single right-pointing angle quotation mark)
-- 0x9C -> U+0153 (Latin small ligature oe)
-- 0x9D -> (remove - undefined)
-- 0x9E -> U+017E (Latin small z with caron)
-- 0x9F -> U+0178 (Latin capital Y with diaeresis)
-- ============================================================================

-- -------------------------------------------------------
-- 1. publication_settings.setting_value
-- -------------------------------------------------------
UPDATE publication_settings SET setting_value = REPLACE(setting_value, CHAR(0x80 USING binary), CHAR(0x20AC USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x80 USING binary), '%');
UPDATE publication_settings SET setting_value = REPLACE(setting_value, CHAR(0x82 USING binary), CHAR(0x201A USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x82 USING binary), '%');
UPDATE publication_settings SET setting_value = REPLACE(setting_value, CHAR(0x83 USING binary), CHAR(0x0192 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x83 USING binary), '%');
UPDATE publication_settings SET setting_value = REPLACE(setting_value, CHAR(0x84 USING binary), CHAR(0x201E USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x84 USING binary), '%');
UPDATE publication_settings SET setting_value = REPLACE(setting_value, CHAR(0x85 USING binary), CHAR(0x2026 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x85 USING binary), '%');
UPDATE publication_settings SET setting_value = REPLACE(setting_value, CHAR(0x86 USING binary), CHAR(0x2020 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x86 USING binary), '%');
UPDATE publication_settings SET setting_value = REPLACE(setting_value, CHAR(0x87 USING binary), CHAR(0x2021 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x87 USING binary), '%');
UPDATE publication_settings SET setting_value = REPLACE(setting_value, CHAR(0x88 USING binary), CHAR(0x02C6 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x88 USING binary), '%');
UPDATE publication_settings SET setting_value = REPLACE(setting_value, CHAR(0x89 USING binary), CHAR(0x2030 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x89 USING binary), '%');
UPDATE publication_settings SET setting_value = REPLACE(setting_value, CHAR(0x8A USING binary), CHAR(0x0160 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x8A USING binary), '%');
UPDATE publication_settings SET setting_value = REPLACE(setting_value, CHAR(0x8B USING binary), CHAR(0x2039 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x8B USING binary), '%');
UPDATE publication_settings SET setting_value = REPLACE(setting_value, CHAR(0x8C USING binary), CHAR(0x0152 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x8C USING binary), '%');
UPDATE publication_settings SET setting_value = REPLACE(setting_value, CHAR(0x8D USING binary), '') WHERE setting_value LIKE CONCAT('%', CHAR(0x8D USING binary), '%');
UPDATE publication_settings SET setting_value = REPLACE(setting_value, CHAR(0x8E USING binary), CHAR(0x017D USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x8E USING binary), '%');
UPDATE publication_settings SET setting_value = REPLACE(setting_value, CHAR(0x8F USING binary), '') WHERE setting_value LIKE CONCAT('%', CHAR(0x8F USING binary), '%');
UPDATE publication_settings SET setting_value = REPLACE(setting_value, CHAR(0x90 USING binary), '') WHERE setting_value LIKE CONCAT('%', CHAR(0x90 USING binary), '%');
UPDATE publication_settings SET setting_value = REPLACE(setting_value, CHAR(0x91 USING binary), CHAR(0x2018 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x91 USING binary), '%');
UPDATE publication_settings SET setting_value = REPLACE(setting_value, CHAR(0x92 USING binary), CHAR(0x2019 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x92 USING binary), '%');
UPDATE publication_settings SET setting_value = REPLACE(setting_value, CHAR(0x93 USING binary), CHAR(0x201C USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x93 USING binary), '%');
UPDATE publication_settings SET setting_value = REPLACE(setting_value, CHAR(0x94 USING binary), CHAR(0x201D USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x94 USING binary), '%');
UPDATE publication_settings SET setting_value = REPLACE(setting_value, CHAR(0x95 USING binary), CHAR(0x2022 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x95 USING binary), '%');
UPDATE publication_settings SET setting_value = REPLACE(setting_value, CHAR(0x96 USING binary), CHAR(0x2013 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x96 USING binary), '%');
UPDATE publication_settings SET setting_value = REPLACE(setting_value, CHAR(0x97 USING binary), CHAR(0x2014 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x97 USING binary), '%');
UPDATE publication_settings SET setting_value = REPLACE(setting_value, CHAR(0x98 USING binary), CHAR(0x02DC USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x98 USING binary), '%');
UPDATE publication_settings SET setting_value = REPLACE(setting_value, CHAR(0x99 USING binary), CHAR(0x2122 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x99 USING binary), '%');
UPDATE publication_settings SET setting_value = REPLACE(setting_value, CHAR(0x9A USING binary), CHAR(0x0161 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x9A USING binary), '%');
UPDATE publication_settings SET setting_value = REPLACE(setting_value, CHAR(0x9B USING binary), CHAR(0x203A USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x9B USING binary), '%');
UPDATE publication_settings SET setting_value = REPLACE(setting_value, CHAR(0x9C USING binary), CHAR(0x0153 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x9C USING binary), '%');
UPDATE publication_settings SET setting_value = REPLACE(setting_value, CHAR(0x9D USING binary), '') WHERE setting_value LIKE CONCAT('%', CHAR(0x9D USING binary), '%');
UPDATE publication_settings SET setting_value = REPLACE(setting_value, CHAR(0x9E USING binary), CHAR(0x017E USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x9E USING binary), '%');
UPDATE publication_settings SET setting_value = REPLACE(setting_value, CHAR(0x9F USING binary), CHAR(0x0178 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x9F USING binary), '%');

-- -------------------------------------------------------
-- 2. author_settings.setting_value
-- -------------------------------------------------------
UPDATE author_settings SET setting_value = REPLACE(setting_value, CHAR(0x80 USING binary), CHAR(0x20AC USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x80 USING binary), '%');
UPDATE author_settings SET setting_value = REPLACE(setting_value, CHAR(0x82 USING binary), CHAR(0x201A USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x82 USING binary), '%');
UPDATE author_settings SET setting_value = REPLACE(setting_value, CHAR(0x83 USING binary), CHAR(0x0192 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x83 USING binary), '%');
UPDATE author_settings SET setting_value = REPLACE(setting_value, CHAR(0x84 USING binary), CHAR(0x201E USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x84 USING binary), '%');
UPDATE author_settings SET setting_value = REPLACE(setting_value, CHAR(0x85 USING binary), CHAR(0x2026 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x85 USING binary), '%');
UPDATE author_settings SET setting_value = REPLACE(setting_value, CHAR(0x86 USING binary), CHAR(0x2020 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x86 USING binary), '%');
UPDATE author_settings SET setting_value = REPLACE(setting_value, CHAR(0x87 USING binary), CHAR(0x2021 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x87 USING binary), '%');
UPDATE author_settings SET setting_value = REPLACE(setting_value, CHAR(0x88 USING binary), CHAR(0x02C6 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x88 USING binary), '%');
UPDATE author_settings SET setting_value = REPLACE(setting_value, CHAR(0x89 USING binary), CHAR(0x2030 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x89 USING binary), '%');
UPDATE author_settings SET setting_value = REPLACE(setting_value, CHAR(0x8A USING binary), CHAR(0x0160 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x8A USING binary), '%');
UPDATE author_settings SET setting_value = REPLACE(setting_value, CHAR(0x8B USING binary), CHAR(0x2039 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x8B USING binary), '%');
UPDATE author_settings SET setting_value = REPLACE(setting_value, CHAR(0x8C USING binary), CHAR(0x0152 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x8C USING binary), '%');
UPDATE author_settings SET setting_value = REPLACE(setting_value, CHAR(0x8D USING binary), '') WHERE setting_value LIKE CONCAT('%', CHAR(0x8D USING binary), '%');
UPDATE author_settings SET setting_value = REPLACE(setting_value, CHAR(0x8E USING binary), CHAR(0x017D USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x8E USING binary), '%');
UPDATE author_settings SET setting_value = REPLACE(setting_value, CHAR(0x8F USING binary), '') WHERE setting_value LIKE CONCAT('%', CHAR(0x8F USING binary), '%');
UPDATE author_settings SET setting_value = REPLACE(setting_value, CHAR(0x90 USING binary), '') WHERE setting_value LIKE CONCAT('%', CHAR(0x90 USING binary), '%');
UPDATE author_settings SET setting_value = REPLACE(setting_value, CHAR(0x91 USING binary), CHAR(0x2018 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x91 USING binary), '%');
UPDATE author_settings SET setting_value = REPLACE(setting_value, CHAR(0x92 USING binary), CHAR(0x2019 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x92 USING binary), '%');
UPDATE author_settings SET setting_value = REPLACE(setting_value, CHAR(0x93 USING binary), CHAR(0x201C USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x93 USING binary), '%');
UPDATE author_settings SET setting_value = REPLACE(setting_value, CHAR(0x94 USING binary), CHAR(0x201D USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x94 USING binary), '%');
UPDATE author_settings SET setting_value = REPLACE(setting_value, CHAR(0x95 USING binary), CHAR(0x2022 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x95 USING binary), '%');
UPDATE author_settings SET setting_value = REPLACE(setting_value, CHAR(0x96 USING binary), CHAR(0x2013 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x96 USING binary), '%');
UPDATE author_settings SET setting_value = REPLACE(setting_value, CHAR(0x97 USING binary), CHAR(0x2014 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x97 USING binary), '%');
UPDATE author_settings SET setting_value = REPLACE(setting_value, CHAR(0x98 USING binary), CHAR(0x02DC USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x98 USING binary), '%');
UPDATE author_settings SET setting_value = REPLACE(setting_value, CHAR(0x99 USING binary), CHAR(0x2122 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x99 USING binary), '%');
UPDATE author_settings SET setting_value = REPLACE(setting_value, CHAR(0x9A USING binary), CHAR(0x0161 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x9A USING binary), '%');
UPDATE author_settings SET setting_value = REPLACE(setting_value, CHAR(0x9B USING binary), CHAR(0x203A USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x9B USING binary), '%');
UPDATE author_settings SET setting_value = REPLACE(setting_value, CHAR(0x9C USING binary), CHAR(0x0153 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x9C USING binary), '%');
UPDATE author_settings SET setting_value = REPLACE(setting_value, CHAR(0x9D USING binary), '') WHERE setting_value LIKE CONCAT('%', CHAR(0x9D USING binary), '%');
UPDATE author_settings SET setting_value = REPLACE(setting_value, CHAR(0x9E USING binary), CHAR(0x017E USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x9E USING binary), '%');
UPDATE author_settings SET setting_value = REPLACE(setting_value, CHAR(0x9F USING binary), CHAR(0x0178 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x9F USING binary), '%');

-- -------------------------------------------------------
-- 3. citations.raw_citation
-- -------------------------------------------------------
UPDATE citations SET raw_citation = REPLACE(raw_citation, CHAR(0x80 USING binary), CHAR(0x20AC USING utf8mb4)) WHERE raw_citation LIKE CONCAT('%', CHAR(0x80 USING binary), '%');
UPDATE citations SET raw_citation = REPLACE(raw_citation, CHAR(0x82 USING binary), CHAR(0x201A USING utf8mb4)) WHERE raw_citation LIKE CONCAT('%', CHAR(0x82 USING binary), '%');
UPDATE citations SET raw_citation = REPLACE(raw_citation, CHAR(0x83 USING binary), CHAR(0x0192 USING utf8mb4)) WHERE raw_citation LIKE CONCAT('%', CHAR(0x83 USING binary), '%');
UPDATE citations SET raw_citation = REPLACE(raw_citation, CHAR(0x84 USING binary), CHAR(0x201E USING utf8mb4)) WHERE raw_citation LIKE CONCAT('%', CHAR(0x84 USING binary), '%');
UPDATE citations SET raw_citation = REPLACE(raw_citation, CHAR(0x85 USING binary), CHAR(0x2026 USING utf8mb4)) WHERE raw_citation LIKE CONCAT('%', CHAR(0x85 USING binary), '%');
UPDATE citations SET raw_citation = REPLACE(raw_citation, CHAR(0x86 USING binary), CHAR(0x2020 USING utf8mb4)) WHERE raw_citation LIKE CONCAT('%', CHAR(0x86 USING binary), '%');
UPDATE citations SET raw_citation = REPLACE(raw_citation, CHAR(0x87 USING binary), CHAR(0x2021 USING utf8mb4)) WHERE raw_citation LIKE CONCAT('%', CHAR(0x87 USING binary), '%');
UPDATE citations SET raw_citation = REPLACE(raw_citation, CHAR(0x88 USING binary), CHAR(0x02C6 USING utf8mb4)) WHERE raw_citation LIKE CONCAT('%', CHAR(0x88 USING binary), '%');
UPDATE citations SET raw_citation = REPLACE(raw_citation, CHAR(0x89 USING binary), CHAR(0x2030 USING utf8mb4)) WHERE raw_citation LIKE CONCAT('%', CHAR(0x89 USING binary), '%');
UPDATE citations SET raw_citation = REPLACE(raw_citation, CHAR(0x8A USING binary), CHAR(0x0160 USING utf8mb4)) WHERE raw_citation LIKE CONCAT('%', CHAR(0x8A USING binary), '%');
UPDATE citations SET raw_citation = REPLACE(raw_citation, CHAR(0x8B USING binary), CHAR(0x2039 USING utf8mb4)) WHERE raw_citation LIKE CONCAT('%', CHAR(0x8B USING binary), '%');
UPDATE citations SET raw_citation = REPLACE(raw_citation, CHAR(0x8C USING binary), CHAR(0x0152 USING utf8mb4)) WHERE raw_citation LIKE CONCAT('%', CHAR(0x8C USING binary), '%');
UPDATE citations SET raw_citation = REPLACE(raw_citation, CHAR(0x8D USING binary), '') WHERE raw_citation LIKE CONCAT('%', CHAR(0x8D USING binary), '%');
UPDATE citations SET raw_citation = REPLACE(raw_citation, CHAR(0x8E USING binary), CHAR(0x017D USING utf8mb4)) WHERE raw_citation LIKE CONCAT('%', CHAR(0x8E USING binary), '%');
UPDATE citations SET raw_citation = REPLACE(raw_citation, CHAR(0x8F USING binary), '') WHERE raw_citation LIKE CONCAT('%', CHAR(0x8F USING binary), '%');
UPDATE citations SET raw_citation = REPLACE(raw_citation, CHAR(0x90 USING binary), '') WHERE raw_citation LIKE CONCAT('%', CHAR(0x90 USING binary), '%');
UPDATE citations SET raw_citation = REPLACE(raw_citation, CHAR(0x91 USING binary), CHAR(0x2018 USING utf8mb4)) WHERE raw_citation LIKE CONCAT('%', CHAR(0x91 USING binary), '%');
UPDATE citations SET raw_citation = REPLACE(raw_citation, CHAR(0x92 USING binary), CHAR(0x2019 USING utf8mb4)) WHERE raw_citation LIKE CONCAT('%', CHAR(0x92 USING binary), '%');
UPDATE citations SET raw_citation = REPLACE(raw_citation, CHAR(0x93 USING binary), CHAR(0x201C USING utf8mb4)) WHERE raw_citation LIKE CONCAT('%', CHAR(0x93 USING binary), '%');
UPDATE citations SET raw_citation = REPLACE(raw_citation, CHAR(0x94 USING binary), CHAR(0x201D USING utf8mb4)) WHERE raw_citation LIKE CONCAT('%', CHAR(0x94 USING binary), '%');
UPDATE citations SET raw_citation = REPLACE(raw_citation, CHAR(0x95 USING binary), CHAR(0x2022 USING utf8mb4)) WHERE raw_citation LIKE CONCAT('%', CHAR(0x95 USING binary), '%');
UPDATE citations SET raw_citation = REPLACE(raw_citation, CHAR(0x96 USING binary), CHAR(0x2013 USING utf8mb4)) WHERE raw_citation LIKE CONCAT('%', CHAR(0x96 USING binary), '%');
UPDATE citations SET raw_citation = REPLACE(raw_citation, CHAR(0x97 USING binary), CHAR(0x2014 USING utf8mb4)) WHERE raw_citation LIKE CONCAT('%', CHAR(0x97 USING binary), '%');
UPDATE citations SET raw_citation = REPLACE(raw_citation, CHAR(0x98 USING binary), CHAR(0x02DC USING utf8mb4)) WHERE raw_citation LIKE CONCAT('%', CHAR(0x98 USING binary), '%');
UPDATE citations SET raw_citation = REPLACE(raw_citation, CHAR(0x99 USING binary), CHAR(0x2122 USING utf8mb4)) WHERE raw_citation LIKE CONCAT('%', CHAR(0x99 USING binary), '%');
UPDATE citations SET raw_citation = REPLACE(raw_citation, CHAR(0x9A USING binary), CHAR(0x0161 USING utf8mb4)) WHERE raw_citation LIKE CONCAT('%', CHAR(0x9A USING binary), '%');
UPDATE citations SET raw_citation = REPLACE(raw_citation, CHAR(0x9B USING binary), CHAR(0x203A USING utf8mb4)) WHERE raw_citation LIKE CONCAT('%', CHAR(0x9B USING binary), '%');
UPDATE citations SET raw_citation = REPLACE(raw_citation, CHAR(0x9C USING binary), CHAR(0x0153 USING utf8mb4)) WHERE raw_citation LIKE CONCAT('%', CHAR(0x9C USING binary), '%');
UPDATE citations SET raw_citation = REPLACE(raw_citation, CHAR(0x9D USING binary), '') WHERE raw_citation LIKE CONCAT('%', CHAR(0x9D USING binary), '%');
UPDATE citations SET raw_citation = REPLACE(raw_citation, CHAR(0x9E USING binary), CHAR(0x017E USING utf8mb4)) WHERE raw_citation LIKE CONCAT('%', CHAR(0x9E USING binary), '%');
UPDATE citations SET raw_citation = REPLACE(raw_citation, CHAR(0x9F USING binary), CHAR(0x0178 USING utf8mb4)) WHERE raw_citation LIKE CONCAT('%', CHAR(0x9F USING binary), '%');

-- -------------------------------------------------------
-- 4. user_settings.setting_value (13899 rows - biggest offender!)
-- -------------------------------------------------------
UPDATE user_settings SET setting_value = REPLACE(setting_value, CHAR(0x80 USING binary), CHAR(0x20AC USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x80 USING binary), '%');
UPDATE user_settings SET setting_value = REPLACE(setting_value, CHAR(0x82 USING binary), CHAR(0x201A USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x82 USING binary), '%');
UPDATE user_settings SET setting_value = REPLACE(setting_value, CHAR(0x83 USING binary), CHAR(0x0192 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x83 USING binary), '%');
UPDATE user_settings SET setting_value = REPLACE(setting_value, CHAR(0x84 USING binary), CHAR(0x201E USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x84 USING binary), '%');
UPDATE user_settings SET setting_value = REPLACE(setting_value, CHAR(0x85 USING binary), CHAR(0x2026 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x85 USING binary), '%');
UPDATE user_settings SET setting_value = REPLACE(setting_value, CHAR(0x86 USING binary), CHAR(0x2020 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x86 USING binary), '%');
UPDATE user_settings SET setting_value = REPLACE(setting_value, CHAR(0x87 USING binary), CHAR(0x2021 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x87 USING binary), '%');
UPDATE user_settings SET setting_value = REPLACE(setting_value, CHAR(0x88 USING binary), CHAR(0x02C6 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x88 USING binary), '%');
UPDATE user_settings SET setting_value = REPLACE(setting_value, CHAR(0x89 USING binary), CHAR(0x2030 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x89 USING binary), '%');
UPDATE user_settings SET setting_value = REPLACE(setting_value, CHAR(0x8A USING binary), CHAR(0x0160 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x8A USING binary), '%');
UPDATE user_settings SET setting_value = REPLACE(setting_value, CHAR(0x8B USING binary), CHAR(0x2039 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x8B USING binary), '%');
UPDATE user_settings SET setting_value = REPLACE(setting_value, CHAR(0x8C USING binary), CHAR(0x0152 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x8C USING binary), '%');
UPDATE user_settings SET setting_value = REPLACE(setting_value, CHAR(0x8D USING binary), '') WHERE setting_value LIKE CONCAT('%', CHAR(0x8D USING binary), '%');
UPDATE user_settings SET setting_value = REPLACE(setting_value, CHAR(0x8E USING binary), CHAR(0x017D USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x8E USING binary), '%');
UPDATE user_settings SET setting_value = REPLACE(setting_value, CHAR(0x8F USING binary), '') WHERE setting_value LIKE CONCAT('%', CHAR(0x8F USING binary), '%');
UPDATE user_settings SET setting_value = REPLACE(setting_value, CHAR(0x90 USING binary), '') WHERE setting_value LIKE CONCAT('%', CHAR(0x90 USING binary), '%');
UPDATE user_settings SET setting_value = REPLACE(setting_value, CHAR(0x91 USING binary), CHAR(0x2018 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x91 USING binary), '%');
UPDATE user_settings SET setting_value = REPLACE(setting_value, CHAR(0x92 USING binary), CHAR(0x2019 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x92 USING binary), '%');
UPDATE user_settings SET setting_value = REPLACE(setting_value, CHAR(0x93 USING binary), CHAR(0x201C USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x93 USING binary), '%');
UPDATE user_settings SET setting_value = REPLACE(setting_value, CHAR(0x94 USING binary), CHAR(0x201D USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x94 USING binary), '%');
UPDATE user_settings SET setting_value = REPLACE(setting_value, CHAR(0x95 USING binary), CHAR(0x2022 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x95 USING binary), '%');
UPDATE user_settings SET setting_value = REPLACE(setting_value, CHAR(0x96 USING binary), CHAR(0x2013 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x96 USING binary), '%');
UPDATE user_settings SET setting_value = REPLACE(setting_value, CHAR(0x97 USING binary), CHAR(0x2014 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x97 USING binary), '%');
UPDATE user_settings SET setting_value = REPLACE(setting_value, CHAR(0x98 USING binary), CHAR(0x02DC USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x98 USING binary), '%');
UPDATE user_settings SET setting_value = REPLACE(setting_value, CHAR(0x99 USING binary), CHAR(0x2122 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x99 USING binary), '%');
UPDATE user_settings SET setting_value = REPLACE(setting_value, CHAR(0x9A USING binary), CHAR(0x0161 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x9A USING binary), '%');
UPDATE user_settings SET setting_value = REPLACE(setting_value, CHAR(0x9B USING binary), CHAR(0x203A USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x9B USING binary), '%');
UPDATE user_settings SET setting_value = REPLACE(setting_value, CHAR(0x9C USING binary), CHAR(0x0153 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x9C USING binary), '%');
UPDATE user_settings SET setting_value = REPLACE(setting_value, CHAR(0x9D USING binary), '') WHERE setting_value LIKE CONCAT('%', CHAR(0x9D USING binary), '%');
UPDATE user_settings SET setting_value = REPLACE(setting_value, CHAR(0x9E USING binary), CHAR(0x017E USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x9E USING binary), '%');
UPDATE user_settings SET setting_value = REPLACE(setting_value, CHAR(0x9F USING binary), CHAR(0x0178 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x9F USING binary), '%');

-- -------------------------------------------------------
-- 5. email_log.subject (3 rows)
-- -------------------------------------------------------
UPDATE email_log SET subject = REPLACE(subject, CHAR(0x80 USING binary), CHAR(0x20AC USING utf8mb4)) WHERE subject LIKE CONCAT('%', CHAR(0x80 USING binary), '%');
UPDATE email_log SET subject = REPLACE(subject, CHAR(0x82 USING binary), CHAR(0x201A USING utf8mb4)) WHERE subject LIKE CONCAT('%', CHAR(0x82 USING binary), '%');
UPDATE email_log SET subject = REPLACE(subject, CHAR(0x83 USING binary), CHAR(0x0192 USING utf8mb4)) WHERE subject LIKE CONCAT('%', CHAR(0x83 USING binary), '%');
UPDATE email_log SET subject = REPLACE(subject, CHAR(0x84 USING binary), CHAR(0x201E USING utf8mb4)) WHERE subject LIKE CONCAT('%', CHAR(0x84 USING binary), '%');
UPDATE email_log SET subject = REPLACE(subject, CHAR(0x85 USING binary), CHAR(0x2026 USING utf8mb4)) WHERE subject LIKE CONCAT('%', CHAR(0x85 USING binary), '%');
UPDATE email_log SET subject = REPLACE(subject, CHAR(0x86 USING binary), CHAR(0x2020 USING utf8mb4)) WHERE subject LIKE CONCAT('%', CHAR(0x86 USING binary), '%');
UPDATE email_log SET subject = REPLACE(subject, CHAR(0x87 USING binary), CHAR(0x2021 USING utf8mb4)) WHERE subject LIKE CONCAT('%', CHAR(0x87 USING binary), '%');
UPDATE email_log SET subject = REPLACE(subject, CHAR(0x88 USING binary), CHAR(0x02C6 USING utf8mb4)) WHERE subject LIKE CONCAT('%', CHAR(0x88 USING binary), '%');
UPDATE email_log SET subject = REPLACE(subject, CHAR(0x89 USING binary), CHAR(0x2030 USING utf8mb4)) WHERE subject LIKE CONCAT('%', CHAR(0x89 USING binary), '%');
UPDATE email_log SET subject = REPLACE(subject, CHAR(0x8A USING binary), CHAR(0x0160 USING utf8mb4)) WHERE subject LIKE CONCAT('%', CHAR(0x8A USING binary), '%');
UPDATE email_log SET subject = REPLACE(subject, CHAR(0x8B USING binary), CHAR(0x2039 USING utf8mb4)) WHERE subject LIKE CONCAT('%', CHAR(0x8B USING binary), '%');
UPDATE email_log SET subject = REPLACE(subject, CHAR(0x8C USING binary), CHAR(0x0152 USING utf8mb4)) WHERE subject LIKE CONCAT('%', CHAR(0x8C USING binary), '%');
UPDATE email_log SET subject = REPLACE(subject, CHAR(0x8D USING binary), '') WHERE subject LIKE CONCAT('%', CHAR(0x8D USING binary), '%');
UPDATE email_log SET subject = REPLACE(subject, CHAR(0x8E USING binary), CHAR(0x017D USING utf8mb4)) WHERE subject LIKE CONCAT('%', CHAR(0x8E USING binary), '%');
UPDATE email_log SET subject = REPLACE(subject, CHAR(0x8F USING binary), '') WHERE subject LIKE CONCAT('%', CHAR(0x8F USING binary), '%');
UPDATE email_log SET subject = REPLACE(subject, CHAR(0x90 USING binary), '') WHERE subject LIKE CONCAT('%', CHAR(0x90 USING binary), '%');
UPDATE email_log SET subject = REPLACE(subject, CHAR(0x91 USING binary), CHAR(0x2018 USING utf8mb4)) WHERE subject LIKE CONCAT('%', CHAR(0x91 USING binary), '%');
UPDATE email_log SET subject = REPLACE(subject, CHAR(0x92 USING binary), CHAR(0x2019 USING utf8mb4)) WHERE subject LIKE CONCAT('%', CHAR(0x92 USING binary), '%');
UPDATE email_log SET subject = REPLACE(subject, CHAR(0x93 USING binary), CHAR(0x201C USING utf8mb4)) WHERE subject LIKE CONCAT('%', CHAR(0x93 USING binary), '%');
UPDATE email_log SET subject = REPLACE(subject, CHAR(0x94 USING binary), CHAR(0x201D USING utf8mb4)) WHERE subject LIKE CONCAT('%', CHAR(0x94 USING binary), '%');
UPDATE email_log SET subject = REPLACE(subject, CHAR(0x95 USING binary), CHAR(0x2022 USING utf8mb4)) WHERE subject LIKE CONCAT('%', CHAR(0x95 USING binary), '%');
UPDATE email_log SET subject = REPLACE(subject, CHAR(0x96 USING binary), CHAR(0x2013 USING utf8mb4)) WHERE subject LIKE CONCAT('%', CHAR(0x96 USING binary), '%');
UPDATE email_log SET subject = REPLACE(subject, CHAR(0x97 USING binary), CHAR(0x2014 USING utf8mb4)) WHERE subject LIKE CONCAT('%', CHAR(0x97 USING binary), '%');
UPDATE email_log SET subject = REPLACE(subject, CHAR(0x98 USING binary), CHAR(0x02DC USING utf8mb4)) WHERE subject LIKE CONCAT('%', CHAR(0x98 USING binary), '%');
UPDATE email_log SET subject = REPLACE(subject, CHAR(0x99 USING binary), CHAR(0x2122 USING utf8mb4)) WHERE subject LIKE CONCAT('%', CHAR(0x99 USING binary), '%');
UPDATE email_log SET subject = REPLACE(subject, CHAR(0x9A USING binary), CHAR(0x0161 USING utf8mb4)) WHERE subject LIKE CONCAT('%', CHAR(0x9A USING binary), '%');
UPDATE email_log SET subject = REPLACE(subject, CHAR(0x9B USING binary), CHAR(0x203A USING utf8mb4)) WHERE subject LIKE CONCAT('%', CHAR(0x9B USING binary), '%');
UPDATE email_log SET subject = REPLACE(subject, CHAR(0x9C USING binary), CHAR(0x0153 USING utf8mb4)) WHERE subject LIKE CONCAT('%', CHAR(0x9C USING binary), '%');
UPDATE email_log SET subject = REPLACE(subject, CHAR(0x9D USING binary), '') WHERE subject LIKE CONCAT('%', CHAR(0x9D USING binary), '%');
UPDATE email_log SET subject = REPLACE(subject, CHAR(0x9E USING binary), CHAR(0x017E USING utf8mb4)) WHERE subject LIKE CONCAT('%', CHAR(0x9E USING binary), '%');
UPDATE email_log SET subject = REPLACE(subject, CHAR(0x9F USING binary), CHAR(0x0178 USING utf8mb4)) WHERE subject LIKE CONCAT('%', CHAR(0x9F USING binary), '%');

-- -------------------------------------------------------
-- 6. email_log.body (231 rows)
-- -------------------------------------------------------
UPDATE email_log SET body = REPLACE(body, CHAR(0x80 USING binary), CHAR(0x20AC USING utf8mb4)) WHERE body LIKE CONCAT('%', CHAR(0x80 USING binary), '%');
UPDATE email_log SET body = REPLACE(body, CHAR(0x82 USING binary), CHAR(0x201A USING utf8mb4)) WHERE body LIKE CONCAT('%', CHAR(0x82 USING binary), '%');
UPDATE email_log SET body = REPLACE(body, CHAR(0x83 USING binary), CHAR(0x0192 USING utf8mb4)) WHERE body LIKE CONCAT('%', CHAR(0x83 USING binary), '%');
UPDATE email_log SET body = REPLACE(body, CHAR(0x84 USING binary), CHAR(0x201E USING utf8mb4)) WHERE body LIKE CONCAT('%', CHAR(0x84 USING binary), '%');
UPDATE email_log SET body = REPLACE(body, CHAR(0x85 USING binary), CHAR(0x2026 USING utf8mb4)) WHERE body LIKE CONCAT('%', CHAR(0x85 USING binary), '%');
UPDATE email_log SET body = REPLACE(body, CHAR(0x86 USING binary), CHAR(0x2020 USING utf8mb4)) WHERE body LIKE CONCAT('%', CHAR(0x86 USING binary), '%');
UPDATE email_log SET body = REPLACE(body, CHAR(0x87 USING binary), CHAR(0x2021 USING utf8mb4)) WHERE body LIKE CONCAT('%', CHAR(0x87 USING binary), '%');
UPDATE email_log SET body = REPLACE(body, CHAR(0x88 USING binary), CHAR(0x02C6 USING utf8mb4)) WHERE body LIKE CONCAT('%', CHAR(0x88 USING binary), '%');
UPDATE email_log SET body = REPLACE(body, CHAR(0x89 USING binary), CHAR(0x2030 USING utf8mb4)) WHERE body LIKE CONCAT('%', CHAR(0x89 USING binary), '%');
UPDATE email_log SET body = REPLACE(body, CHAR(0x8A USING binary), CHAR(0x0160 USING utf8mb4)) WHERE body LIKE CONCAT('%', CHAR(0x8A USING binary), '%');
UPDATE email_log SET body = REPLACE(body, CHAR(0x8B USING binary), CHAR(0x2039 USING utf8mb4)) WHERE body LIKE CONCAT('%', CHAR(0x8B USING binary), '%');
UPDATE email_log SET body = REPLACE(body, CHAR(0x8C USING binary), CHAR(0x0152 USING utf8mb4)) WHERE body LIKE CONCAT('%', CHAR(0x8C USING binary), '%');
UPDATE email_log SET body = REPLACE(body, CHAR(0x8D USING binary), '') WHERE body LIKE CONCAT('%', CHAR(0x8D USING binary), '%');
UPDATE email_log SET body = REPLACE(body, CHAR(0x8E USING binary), CHAR(0x017D USING utf8mb4)) WHERE body LIKE CONCAT('%', CHAR(0x8E USING binary), '%');
UPDATE email_log SET body = REPLACE(body, CHAR(0x8F USING binary), '') WHERE body LIKE CONCAT('%', CHAR(0x8F USING binary), '%');
UPDATE email_log SET body = REPLACE(body, CHAR(0x90 USING binary), '') WHERE body LIKE CONCAT('%', CHAR(0x90 USING binary), '%');
UPDATE email_log SET body = REPLACE(body, CHAR(0x91 USING binary), CHAR(0x2018 USING utf8mb4)) WHERE body LIKE CONCAT('%', CHAR(0x91 USING binary), '%');
UPDATE email_log SET body = REPLACE(body, CHAR(0x92 USING binary), CHAR(0x2019 USING utf8mb4)) WHERE body LIKE CONCAT('%', CHAR(0x92 USING binary), '%');
UPDATE email_log SET body = REPLACE(body, CHAR(0x93 USING binary), CHAR(0x201C USING utf8mb4)) WHERE body LIKE CONCAT('%', CHAR(0x93 USING binary), '%');
UPDATE email_log SET body = REPLACE(body, CHAR(0x94 USING binary), CHAR(0x201D USING utf8mb4)) WHERE body LIKE CONCAT('%', CHAR(0x94 USING binary), '%');
UPDATE email_log SET body = REPLACE(body, CHAR(0x95 USING binary), CHAR(0x2022 USING utf8mb4)) WHERE body LIKE CONCAT('%', CHAR(0x95 USING binary), '%');
UPDATE email_log SET body = REPLACE(body, CHAR(0x96 USING binary), CHAR(0x2013 USING utf8mb4)) WHERE body LIKE CONCAT('%', CHAR(0x96 USING binary), '%');
UPDATE email_log SET body = REPLACE(body, CHAR(0x97 USING binary), CHAR(0x2014 USING utf8mb4)) WHERE body LIKE CONCAT('%', CHAR(0x97 USING binary), '%');
UPDATE email_log SET body = REPLACE(body, CHAR(0x98 USING binary), CHAR(0x02DC USING utf8mb4)) WHERE body LIKE CONCAT('%', CHAR(0x98 USING binary), '%');
UPDATE email_log SET body = REPLACE(body, CHAR(0x99 USING binary), CHAR(0x2122 USING utf8mb4)) WHERE body LIKE CONCAT('%', CHAR(0x99 USING binary), '%');
UPDATE email_log SET body = REPLACE(body, CHAR(0x9A USING binary), CHAR(0x0161 USING utf8mb4)) WHERE body LIKE CONCAT('%', CHAR(0x9A USING binary), '%');
UPDATE email_log SET body = REPLACE(body, CHAR(0x9B USING binary), CHAR(0x203A USING utf8mb4)) WHERE body LIKE CONCAT('%', CHAR(0x9B USING binary), '%');
UPDATE email_log SET body = REPLACE(body, CHAR(0x9C USING binary), CHAR(0x0153 USING utf8mb4)) WHERE body LIKE CONCAT('%', CHAR(0x9C USING binary), '%');
UPDATE email_log SET body = REPLACE(body, CHAR(0x9D USING binary), '') WHERE body LIKE CONCAT('%', CHAR(0x9D USING binary), '%');
UPDATE email_log SET body = REPLACE(body, CHAR(0x9E USING binary), CHAR(0x017E USING utf8mb4)) WHERE body LIKE CONCAT('%', CHAR(0x9E USING binary), '%');
UPDATE email_log SET body = REPLACE(body, CHAR(0x9F USING binary), CHAR(0x0178 USING utf8mb4)) WHERE body LIKE CONCAT('%', CHAR(0x9F USING binary), '%');

-- -------------------------------------------------------
-- 7. email_templates_default_data (subject, body, description)
-- -------------------------------------------------------
UPDATE email_templates_default_data SET subject = REPLACE(subject, CHAR(0x80 USING binary), CHAR(0x20AC USING utf8mb4)) WHERE subject LIKE CONCAT('%', CHAR(0x80 USING binary), '%');
UPDATE email_templates_default_data SET subject = REPLACE(subject, CHAR(0x85 USING binary), CHAR(0x2026 USING utf8mb4)) WHERE subject LIKE CONCAT('%', CHAR(0x85 USING binary), '%');
UPDATE email_templates_default_data SET subject = REPLACE(subject, CHAR(0x91 USING binary), CHAR(0x2018 USING utf8mb4)) WHERE subject LIKE CONCAT('%', CHAR(0x91 USING binary), '%');
UPDATE email_templates_default_data SET subject = REPLACE(subject, CHAR(0x92 USING binary), CHAR(0x2019 USING utf8mb4)) WHERE subject LIKE CONCAT('%', CHAR(0x92 USING binary), '%');
UPDATE email_templates_default_data SET subject = REPLACE(subject, CHAR(0x93 USING binary), CHAR(0x201C USING utf8mb4)) WHERE subject LIKE CONCAT('%', CHAR(0x93 USING binary), '%');
UPDATE email_templates_default_data SET subject = REPLACE(subject, CHAR(0x94 USING binary), CHAR(0x201D USING utf8mb4)) WHERE subject LIKE CONCAT('%', CHAR(0x94 USING binary), '%');
UPDATE email_templates_default_data SET subject = REPLACE(subject, CHAR(0x95 USING binary), CHAR(0x2022 USING utf8mb4)) WHERE subject LIKE CONCAT('%', CHAR(0x95 USING binary), '%');
UPDATE email_templates_default_data SET subject = REPLACE(subject, CHAR(0x96 USING binary), CHAR(0x2013 USING utf8mb4)) WHERE subject LIKE CONCAT('%', CHAR(0x96 USING binary), '%');
UPDATE email_templates_default_data SET subject = REPLACE(subject, CHAR(0x97 USING binary), CHAR(0x2014 USING utf8mb4)) WHERE subject LIKE CONCAT('%', CHAR(0x97 USING binary), '%');

UPDATE email_templates_default_data SET body = REPLACE(body, CHAR(0x80 USING binary), CHAR(0x20AC USING utf8mb4)) WHERE body LIKE CONCAT('%', CHAR(0x80 USING binary), '%');
UPDATE email_templates_default_data SET body = REPLACE(body, CHAR(0x85 USING binary), CHAR(0x2026 USING utf8mb4)) WHERE body LIKE CONCAT('%', CHAR(0x85 USING binary), '%');
UPDATE email_templates_default_data SET body = REPLACE(body, CHAR(0x91 USING binary), CHAR(0x2018 USING utf8mb4)) WHERE body LIKE CONCAT('%', CHAR(0x91 USING binary), '%');
UPDATE email_templates_default_data SET body = REPLACE(body, CHAR(0x92 USING binary), CHAR(0x2019 USING utf8mb4)) WHERE body LIKE CONCAT('%', CHAR(0x92 USING binary), '%');
UPDATE email_templates_default_data SET body = REPLACE(body, CHAR(0x93 USING binary), CHAR(0x201C USING utf8mb4)) WHERE body LIKE CONCAT('%', CHAR(0x93 USING binary), '%');
UPDATE email_templates_default_data SET body = REPLACE(body, CHAR(0x94 USING binary), CHAR(0x201D USING utf8mb4)) WHERE body LIKE CONCAT('%', CHAR(0x94 USING binary), '%');
UPDATE email_templates_default_data SET body = REPLACE(body, CHAR(0x95 USING binary), CHAR(0x2022 USING utf8mb4)) WHERE body LIKE CONCAT('%', CHAR(0x95 USING binary), '%');
UPDATE email_templates_default_data SET body = REPLACE(body, CHAR(0x96 USING binary), CHAR(0x2013 USING utf8mb4)) WHERE body LIKE CONCAT('%', CHAR(0x96 USING binary), '%');
UPDATE email_templates_default_data SET body = REPLACE(body, CHAR(0x97 USING binary), CHAR(0x2014 USING utf8mb4)) WHERE body LIKE CONCAT('%', CHAR(0x97 USING binary), '%');

UPDATE email_templates_default_data SET description = REPLACE(description, CHAR(0x80 USING binary), CHAR(0x20AC USING utf8mb4)) WHERE description LIKE CONCAT('%', CHAR(0x80 USING binary), '%');
UPDATE email_templates_default_data SET description = REPLACE(description, CHAR(0x85 USING binary), CHAR(0x2026 USING utf8mb4)) WHERE description LIKE CONCAT('%', CHAR(0x85 USING binary), '%');
UPDATE email_templates_default_data SET description = REPLACE(description, CHAR(0x91 USING binary), CHAR(0x2018 USING utf8mb4)) WHERE description LIKE CONCAT('%', CHAR(0x91 USING binary), '%');
UPDATE email_templates_default_data SET description = REPLACE(description, CHAR(0x92 USING binary), CHAR(0x2019 USING utf8mb4)) WHERE description LIKE CONCAT('%', CHAR(0x92 USING binary), '%');
UPDATE email_templates_default_data SET description = REPLACE(description, CHAR(0x93 USING binary), CHAR(0x201C USING utf8mb4)) WHERE description LIKE CONCAT('%', CHAR(0x93 USING binary), '%');
UPDATE email_templates_default_data SET description = REPLACE(description, CHAR(0x94 USING binary), CHAR(0x201D USING utf8mb4)) WHERE description LIKE CONCAT('%', CHAR(0x94 USING binary), '%');
UPDATE email_templates_default_data SET description = REPLACE(description, CHAR(0x95 USING binary), CHAR(0x2022 USING utf8mb4)) WHERE description LIKE CONCAT('%', CHAR(0x95 USING binary), '%');
UPDATE email_templates_default_data SET description = REPLACE(description, CHAR(0x96 USING binary), CHAR(0x2013 USING utf8mb4)) WHERE description LIKE CONCAT('%', CHAR(0x96 USING binary), '%');
UPDATE email_templates_default_data SET description = REPLACE(description, CHAR(0x97 USING binary), CHAR(0x2014 USING utf8mb4)) WHERE description LIKE CONCAT('%', CHAR(0x97 USING binary), '%');

-- -------------------------------------------------------
-- 8. notes.title and notes.contents
-- -------------------------------------------------------
UPDATE notes SET title = REPLACE(title, CHAR(0x80 USING binary), CHAR(0x20AC USING utf8mb4)) WHERE title LIKE CONCAT('%', CHAR(0x80 USING binary), '%');
UPDATE notes SET title = REPLACE(title, CHAR(0x85 USING binary), CHAR(0x2026 USING utf8mb4)) WHERE title LIKE CONCAT('%', CHAR(0x85 USING binary), '%');
UPDATE notes SET title = REPLACE(title, CHAR(0x91 USING binary), CHAR(0x2018 USING utf8mb4)) WHERE title LIKE CONCAT('%', CHAR(0x91 USING binary), '%');
UPDATE notes SET title = REPLACE(title, CHAR(0x92 USING binary), CHAR(0x2019 USING utf8mb4)) WHERE title LIKE CONCAT('%', CHAR(0x92 USING binary), '%');
UPDATE notes SET title = REPLACE(title, CHAR(0x93 USING binary), CHAR(0x201C USING utf8mb4)) WHERE title LIKE CONCAT('%', CHAR(0x93 USING binary), '%');
UPDATE notes SET title = REPLACE(title, CHAR(0x94 USING binary), CHAR(0x201D USING utf8mb4)) WHERE title LIKE CONCAT('%', CHAR(0x94 USING binary), '%');
UPDATE notes SET title = REPLACE(title, CHAR(0x95 USING binary), CHAR(0x2022 USING utf8mb4)) WHERE title LIKE CONCAT('%', CHAR(0x95 USING binary), '%');
UPDATE notes SET title = REPLACE(title, CHAR(0x96 USING binary), CHAR(0x2013 USING utf8mb4)) WHERE title LIKE CONCAT('%', CHAR(0x96 USING binary), '%');
UPDATE notes SET title = REPLACE(title, CHAR(0x97 USING binary), CHAR(0x2014 USING utf8mb4)) WHERE title LIKE CONCAT('%', CHAR(0x97 USING binary), '%');

UPDATE notes SET contents = REPLACE(contents, CHAR(0x80 USING binary), CHAR(0x20AC USING utf8mb4)) WHERE contents LIKE CONCAT('%', CHAR(0x80 USING binary), '%');
UPDATE notes SET contents = REPLACE(contents, CHAR(0x82 USING binary), CHAR(0x201A USING utf8mb4)) WHERE contents LIKE CONCAT('%', CHAR(0x82 USING binary), '%');
UPDATE notes SET contents = REPLACE(contents, CHAR(0x83 USING binary), CHAR(0x0192 USING utf8mb4)) WHERE contents LIKE CONCAT('%', CHAR(0x83 USING binary), '%');
UPDATE notes SET contents = REPLACE(contents, CHAR(0x84 USING binary), CHAR(0x201E USING utf8mb4)) WHERE contents LIKE CONCAT('%', CHAR(0x84 USING binary), '%');
UPDATE notes SET contents = REPLACE(contents, CHAR(0x85 USING binary), CHAR(0x2026 USING utf8mb4)) WHERE contents LIKE CONCAT('%', CHAR(0x85 USING binary), '%');
UPDATE notes SET contents = REPLACE(contents, CHAR(0x86 USING binary), CHAR(0x2020 USING utf8mb4)) WHERE contents LIKE CONCAT('%', CHAR(0x86 USING binary), '%');
UPDATE notes SET contents = REPLACE(contents, CHAR(0x87 USING binary), CHAR(0x2021 USING utf8mb4)) WHERE contents LIKE CONCAT('%', CHAR(0x87 USING binary), '%');
UPDATE notes SET contents = REPLACE(contents, CHAR(0x88 USING binary), CHAR(0x02C6 USING utf8mb4)) WHERE contents LIKE CONCAT('%', CHAR(0x88 USING binary), '%');
UPDATE notes SET contents = REPLACE(contents, CHAR(0x89 USING binary), CHAR(0x2030 USING utf8mb4)) WHERE contents LIKE CONCAT('%', CHAR(0x89 USING binary), '%');
UPDATE notes SET contents = REPLACE(contents, CHAR(0x8A USING binary), CHAR(0x0160 USING utf8mb4)) WHERE contents LIKE CONCAT('%', CHAR(0x8A USING binary), '%');
UPDATE notes SET contents = REPLACE(contents, CHAR(0x8B USING binary), CHAR(0x2039 USING utf8mb4)) WHERE contents LIKE CONCAT('%', CHAR(0x8B USING binary), '%');
UPDATE notes SET contents = REPLACE(contents, CHAR(0x8C USING binary), CHAR(0x0152 USING utf8mb4)) WHERE contents LIKE CONCAT('%', CHAR(0x8C USING binary), '%');
UPDATE notes SET contents = REPLACE(contents, CHAR(0x8D USING binary), '') WHERE contents LIKE CONCAT('%', CHAR(0x8D USING binary), '%');
UPDATE notes SET contents = REPLACE(contents, CHAR(0x8E USING binary), CHAR(0x017D USING utf8mb4)) WHERE contents LIKE CONCAT('%', CHAR(0x8E USING binary), '%');
UPDATE notes SET contents = REPLACE(contents, CHAR(0x8F USING binary), '') WHERE contents LIKE CONCAT('%', CHAR(0x8F USING binary), '%');
UPDATE notes SET contents = REPLACE(contents, CHAR(0x90 USING binary), '') WHERE contents LIKE CONCAT('%', CHAR(0x90 USING binary), '%');
UPDATE notes SET contents = REPLACE(contents, CHAR(0x91 USING binary), CHAR(0x2018 USING utf8mb4)) WHERE contents LIKE CONCAT('%', CHAR(0x91 USING binary), '%');
UPDATE notes SET contents = REPLACE(contents, CHAR(0x92 USING binary), CHAR(0x2019 USING utf8mb4)) WHERE contents LIKE CONCAT('%', CHAR(0x92 USING binary), '%');
UPDATE notes SET contents = REPLACE(contents, CHAR(0x93 USING binary), CHAR(0x201C USING utf8mb4)) WHERE contents LIKE CONCAT('%', CHAR(0x93 USING binary), '%');
UPDATE notes SET contents = REPLACE(contents, CHAR(0x94 USING binary), CHAR(0x201D USING utf8mb4)) WHERE contents LIKE CONCAT('%', CHAR(0x94 USING binary), '%');
UPDATE notes SET contents = REPLACE(contents, CHAR(0x95 USING binary), CHAR(0x2022 USING utf8mb4)) WHERE contents LIKE CONCAT('%', CHAR(0x95 USING binary), '%');
UPDATE notes SET contents = REPLACE(contents, CHAR(0x96 USING binary), CHAR(0x2013 USING utf8mb4)) WHERE contents LIKE CONCAT('%', CHAR(0x96 USING binary), '%');
UPDATE notes SET contents = REPLACE(contents, CHAR(0x97 USING binary), CHAR(0x2014 USING utf8mb4)) WHERE contents LIKE CONCAT('%', CHAR(0x97 USING binary), '%');
UPDATE notes SET contents = REPLACE(contents, CHAR(0x98 USING binary), CHAR(0x02DC USING utf8mb4)) WHERE contents LIKE CONCAT('%', CHAR(0x98 USING binary), '%');
UPDATE notes SET contents = REPLACE(contents, CHAR(0x99 USING binary), CHAR(0x2122 USING utf8mb4)) WHERE contents LIKE CONCAT('%', CHAR(0x99 USING binary), '%');
UPDATE notes SET contents = REPLACE(contents, CHAR(0x9A USING binary), CHAR(0x0161 USING utf8mb4)) WHERE contents LIKE CONCAT('%', CHAR(0x9A USING binary), '%');
UPDATE notes SET contents = REPLACE(contents, CHAR(0x9B USING binary), CHAR(0x203A USING utf8mb4)) WHERE contents LIKE CONCAT('%', CHAR(0x9B USING binary), '%');
UPDATE notes SET contents = REPLACE(contents, CHAR(0x9C USING binary), CHAR(0x0153 USING utf8mb4)) WHERE contents LIKE CONCAT('%', CHAR(0x9C USING binary), '%');
UPDATE notes SET contents = REPLACE(contents, CHAR(0x9D USING binary), '') WHERE contents LIKE CONCAT('%', CHAR(0x9D USING binary), '%');
UPDATE notes SET contents = REPLACE(contents, CHAR(0x9E USING binary), CHAR(0x017E USING utf8mb4)) WHERE contents LIKE CONCAT('%', CHAR(0x9E USING binary), '%');
UPDATE notes SET contents = REPLACE(contents, CHAR(0x9F USING binary), CHAR(0x0178 USING utf8mb4)) WHERE contents LIKE CONCAT('%', CHAR(0x9F USING binary), '%');

-- -------------------------------------------------------
-- 9. controlled_vocab_entry_settings.setting_value (1 row)
-- -------------------------------------------------------
UPDATE controlled_vocab_entry_settings SET setting_value = REPLACE(setting_value, CHAR(0x80 USING binary), CHAR(0x20AC USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x80 USING binary), '%');
UPDATE controlled_vocab_entry_settings SET setting_value = REPLACE(setting_value, CHAR(0x85 USING binary), CHAR(0x2026 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x85 USING binary), '%');
UPDATE controlled_vocab_entry_settings SET setting_value = REPLACE(setting_value, CHAR(0x91 USING binary), CHAR(0x2018 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x91 USING binary), '%');
UPDATE controlled_vocab_entry_settings SET setting_value = REPLACE(setting_value, CHAR(0x92 USING binary), CHAR(0x2019 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x92 USING binary), '%');
UPDATE controlled_vocab_entry_settings SET setting_value = REPLACE(setting_value, CHAR(0x93 USING binary), CHAR(0x201C USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x93 USING binary), '%');
UPDATE controlled_vocab_entry_settings SET setting_value = REPLACE(setting_value, CHAR(0x94 USING binary), CHAR(0x201D USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x94 USING binary), '%');
UPDATE controlled_vocab_entry_settings SET setting_value = REPLACE(setting_value, CHAR(0x95 USING binary), CHAR(0x2022 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x95 USING binary), '%');
UPDATE controlled_vocab_entry_settings SET setting_value = REPLACE(setting_value, CHAR(0x96 USING binary), CHAR(0x2013 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x96 USING binary), '%');
UPDATE controlled_vocab_entry_settings SET setting_value = REPLACE(setting_value, CHAR(0x97 USING binary), CHAR(0x2014 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x97 USING binary), '%');

-- -------------------------------------------------------
-- 10. review_form_responses.response_value (54 rows)
-- -------------------------------------------------------
UPDATE review_form_responses SET response_value = REPLACE(response_value, CHAR(0x80 USING binary), CHAR(0x20AC USING utf8mb4)) WHERE response_value LIKE CONCAT('%', CHAR(0x80 USING binary), '%');
UPDATE review_form_responses SET response_value = REPLACE(response_value, CHAR(0x85 USING binary), CHAR(0x2026 USING utf8mb4)) WHERE response_value LIKE CONCAT('%', CHAR(0x85 USING binary), '%');
UPDATE review_form_responses SET response_value = REPLACE(response_value, CHAR(0x91 USING binary), CHAR(0x2018 USING utf8mb4)) WHERE response_value LIKE CONCAT('%', CHAR(0x91 USING binary), '%');
UPDATE review_form_responses SET response_value = REPLACE(response_value, CHAR(0x92 USING binary), CHAR(0x2019 USING utf8mb4)) WHERE response_value LIKE CONCAT('%', CHAR(0x92 USING binary), '%');
UPDATE review_form_responses SET response_value = REPLACE(response_value, CHAR(0x93 USING binary), CHAR(0x201C USING utf8mb4)) WHERE response_value LIKE CONCAT('%', CHAR(0x93 USING binary), '%');
UPDATE review_form_responses SET response_value = REPLACE(response_value, CHAR(0x94 USING binary), CHAR(0x201D USING utf8mb4)) WHERE response_value LIKE CONCAT('%', CHAR(0x94 USING binary), '%');
UPDATE review_form_responses SET response_value = REPLACE(response_value, CHAR(0x95 USING binary), CHAR(0x2022 USING utf8mb4)) WHERE response_value LIKE CONCAT('%', CHAR(0x95 USING binary), '%');
UPDATE review_form_responses SET response_value = REPLACE(response_value, CHAR(0x96 USING binary), CHAR(0x2013 USING utf8mb4)) WHERE response_value LIKE CONCAT('%', CHAR(0x96 USING binary), '%');
UPDATE review_form_responses SET response_value = REPLACE(response_value, CHAR(0x97 USING binary), CHAR(0x2014 USING utf8mb4)) WHERE response_value LIKE CONCAT('%', CHAR(0x97 USING binary), '%');

-- -------------------------------------------------------
-- 11. submission_search_keyword_list.keyword_text (48 rows)
-- -------------------------------------------------------
UPDATE submission_search_keyword_list SET keyword_text = REPLACE(keyword_text, CHAR(0x80 USING binary), CHAR(0x20AC USING utf8mb4)) WHERE keyword_text LIKE CONCAT('%', CHAR(0x80 USING binary), '%');
UPDATE submission_search_keyword_list SET keyword_text = REPLACE(keyword_text, CHAR(0x85 USING binary), CHAR(0x2026 USING utf8mb4)) WHERE keyword_text LIKE CONCAT('%', CHAR(0x85 USING binary), '%');
UPDATE submission_search_keyword_list SET keyword_text = REPLACE(keyword_text, CHAR(0x91 USING binary), CHAR(0x2018 USING utf8mb4)) WHERE keyword_text LIKE CONCAT('%', CHAR(0x91 USING binary), '%');
UPDATE submission_search_keyword_list SET keyword_text = REPLACE(keyword_text, CHAR(0x92 USING binary), CHAR(0x2019 USING utf8mb4)) WHERE keyword_text LIKE CONCAT('%', CHAR(0x92 USING binary), '%');
UPDATE submission_search_keyword_list SET keyword_text = REPLACE(keyword_text, CHAR(0x93 USING binary), CHAR(0x201C USING utf8mb4)) WHERE keyword_text LIKE CONCAT('%', CHAR(0x93 USING binary), '%');
UPDATE submission_search_keyword_list SET keyword_text = REPLACE(keyword_text, CHAR(0x94 USING binary), CHAR(0x201D USING utf8mb4)) WHERE keyword_text LIKE CONCAT('%', CHAR(0x94 USING binary), '%');
UPDATE submission_search_keyword_list SET keyword_text = REPLACE(keyword_text, CHAR(0x95 USING binary), CHAR(0x2022 USING utf8mb4)) WHERE keyword_text LIKE CONCAT('%', CHAR(0x95 USING binary), '%');
UPDATE submission_search_keyword_list SET keyword_text = REPLACE(keyword_text, CHAR(0x96 USING binary), CHAR(0x2013 USING utf8mb4)) WHERE keyword_text LIKE CONCAT('%', CHAR(0x96 USING binary), '%');
UPDATE submission_search_keyword_list SET keyword_text = REPLACE(keyword_text, CHAR(0x97 USING binary), CHAR(0x2014 USING utf8mb4)) WHERE keyword_text LIKE CONCAT('%', CHAR(0x97 USING binary), '%');

-- -------------------------------------------------------
-- 12. submission_file_settings.setting_value (10 rows)
-- -------------------------------------------------------
UPDATE submission_file_settings SET setting_value = REPLACE(setting_value, CHAR(0x80 USING binary), CHAR(0x20AC USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x80 USING binary), '%');
UPDATE submission_file_settings SET setting_value = REPLACE(setting_value, CHAR(0x85 USING binary), CHAR(0x2026 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x85 USING binary), '%');
UPDATE submission_file_settings SET setting_value = REPLACE(setting_value, CHAR(0x91 USING binary), CHAR(0x2018 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x91 USING binary), '%');
UPDATE submission_file_settings SET setting_value = REPLACE(setting_value, CHAR(0x92 USING binary), CHAR(0x2019 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x92 USING binary), '%');
UPDATE submission_file_settings SET setting_value = REPLACE(setting_value, CHAR(0x93 USING binary), CHAR(0x201C USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x93 USING binary), '%');
UPDATE submission_file_settings SET setting_value = REPLACE(setting_value, CHAR(0x94 USING binary), CHAR(0x201D USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x94 USING binary), '%');
UPDATE submission_file_settings SET setting_value = REPLACE(setting_value, CHAR(0x95 USING binary), CHAR(0x2022 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x95 USING binary), '%');
UPDATE submission_file_settings SET setting_value = REPLACE(setting_value, CHAR(0x96 USING binary), CHAR(0x2013 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x96 USING binary), '%');
UPDATE submission_file_settings SET setting_value = REPLACE(setting_value, CHAR(0x97 USING binary), CHAR(0x2014 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x97 USING binary), '%');

-- -------------------------------------------------------
-- 13. submission_comments.comments (3 rows)
-- -------------------------------------------------------
UPDATE submission_comments SET comments = REPLACE(comments, CHAR(0x80 USING binary), CHAR(0x20AC USING utf8mb4)) WHERE comments LIKE CONCAT('%', CHAR(0x80 USING binary), '%');
UPDATE submission_comments SET comments = REPLACE(comments, CHAR(0x85 USING binary), CHAR(0x2026 USING utf8mb4)) WHERE comments LIKE CONCAT('%', CHAR(0x85 USING binary), '%');
UPDATE submission_comments SET comments = REPLACE(comments, CHAR(0x91 USING binary), CHAR(0x2018 USING utf8mb4)) WHERE comments LIKE CONCAT('%', CHAR(0x91 USING binary), '%');
UPDATE submission_comments SET comments = REPLACE(comments, CHAR(0x92 USING binary), CHAR(0x2019 USING utf8mb4)) WHERE comments LIKE CONCAT('%', CHAR(0x92 USING binary), '%');
UPDATE submission_comments SET comments = REPLACE(comments, CHAR(0x93 USING binary), CHAR(0x201C USING utf8mb4)) WHERE comments LIKE CONCAT('%', CHAR(0x93 USING binary), '%');
UPDATE submission_comments SET comments = REPLACE(comments, CHAR(0x94 USING binary), CHAR(0x201D USING utf8mb4)) WHERE comments LIKE CONCAT('%', CHAR(0x94 USING binary), '%');
UPDATE submission_comments SET comments = REPLACE(comments, CHAR(0x95 USING binary), CHAR(0x2022 USING utf8mb4)) WHERE comments LIKE CONCAT('%', CHAR(0x95 USING binary), '%');
UPDATE submission_comments SET comments = REPLACE(comments, CHAR(0x96 USING binary), CHAR(0x2013 USING utf8mb4)) WHERE comments LIKE CONCAT('%', CHAR(0x96 USING binary), '%');
UPDATE submission_comments SET comments = REPLACE(comments, CHAR(0x97 USING binary), CHAR(0x2014 USING utf8mb4)) WHERE comments LIKE CONCAT('%', CHAR(0x97 USING binary), '%');

-- -------------------------------------------------------
-- 14. rt_searches.description (3 rows)
-- -------------------------------------------------------
UPDATE rt_searches SET description = REPLACE(description, CHAR(0x80 USING binary), CHAR(0x20AC USING utf8mb4)) WHERE description LIKE CONCAT('%', CHAR(0x80 USING binary), '%');
UPDATE rt_searches SET description = REPLACE(description, CHAR(0x85 USING binary), CHAR(0x2026 USING utf8mb4)) WHERE description LIKE CONCAT('%', CHAR(0x85 USING binary), '%');
UPDATE rt_searches SET description = REPLACE(description, CHAR(0x91 USING binary), CHAR(0x2018 USING utf8mb4)) WHERE description LIKE CONCAT('%', CHAR(0x91 USING binary), '%');
UPDATE rt_searches SET description = REPLACE(description, CHAR(0x92 USING binary), CHAR(0x2019 USING utf8mb4)) WHERE description LIKE CONCAT('%', CHAR(0x92 USING binary), '%');
UPDATE rt_searches SET description = REPLACE(description, CHAR(0x93 USING binary), CHAR(0x201C USING utf8mb4)) WHERE description LIKE CONCAT('%', CHAR(0x93 USING binary), '%');
UPDATE rt_searches SET description = REPLACE(description, CHAR(0x94 USING binary), CHAR(0x201D USING utf8mb4)) WHERE description LIKE CONCAT('%', CHAR(0x94 USING binary), '%');
UPDATE rt_searches SET description = REPLACE(description, CHAR(0x95 USING binary), CHAR(0x2022 USING utf8mb4)) WHERE description LIKE CONCAT('%', CHAR(0x95 USING binary), '%');
UPDATE rt_searches SET description = REPLACE(description, CHAR(0x96 USING binary), CHAR(0x2013 USING utf8mb4)) WHERE description LIKE CONCAT('%', CHAR(0x96 USING binary), '%');
UPDATE rt_searches SET description = REPLACE(description, CHAR(0x97 USING binary), CHAR(0x2014 USING utf8mb4)) WHERE description LIKE CONCAT('%', CHAR(0x97 USING binary), '%');

-- -------------------------------------------------------
-- 15. submission_files.original_file_name (2 rows)
-- -------------------------------------------------------
UPDATE submission_files SET original_file_name = REPLACE(original_file_name, CHAR(0x80 USING binary), CHAR(0x20AC USING utf8mb4)) WHERE original_file_name LIKE CONCAT('%', CHAR(0x80 USING binary), '%');
UPDATE submission_files SET original_file_name = REPLACE(original_file_name, CHAR(0x85 USING binary), CHAR(0x2026 USING utf8mb4)) WHERE original_file_name LIKE CONCAT('%', CHAR(0x85 USING binary), '%');
UPDATE submission_files SET original_file_name = REPLACE(original_file_name, CHAR(0x91 USING binary), CHAR(0x2018 USING utf8mb4)) WHERE original_file_name LIKE CONCAT('%', CHAR(0x91 USING binary), '%');
UPDATE submission_files SET original_file_name = REPLACE(original_file_name, CHAR(0x92 USING binary), CHAR(0x2019 USING utf8mb4)) WHERE original_file_name LIKE CONCAT('%', CHAR(0x92 USING binary), '%');
UPDATE submission_files SET original_file_name = REPLACE(original_file_name, CHAR(0x93 USING binary), CHAR(0x201C USING utf8mb4)) WHERE original_file_name LIKE CONCAT('%', CHAR(0x93 USING binary), '%');
UPDATE submission_files SET original_file_name = REPLACE(original_file_name, CHAR(0x94 USING binary), CHAR(0x201D USING utf8mb4)) WHERE original_file_name LIKE CONCAT('%', CHAR(0x94 USING binary), '%');
UPDATE submission_files SET original_file_name = REPLACE(original_file_name, CHAR(0x95 USING binary), CHAR(0x2022 USING utf8mb4)) WHERE original_file_name LIKE CONCAT('%', CHAR(0x95 USING binary), '%');
UPDATE submission_files SET original_file_name = REPLACE(original_file_name, CHAR(0x96 USING binary), CHAR(0x2013 USING utf8mb4)) WHERE original_file_name LIKE CONCAT('%', CHAR(0x96 USING binary), '%');
UPDATE submission_files SET original_file_name = REPLACE(original_file_name, CHAR(0x97 USING binary), CHAR(0x2014 USING utf8mb4)) WHERE original_file_name LIKE CONCAT('%', CHAR(0x97 USING binary), '%');

-- -------------------------------------------------------
-- 16. journal_settings.setting_value (1 row)
-- -------------------------------------------------------
UPDATE journal_settings SET setting_value = REPLACE(setting_value, CHAR(0x80 USING binary), CHAR(0x20AC USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x80 USING binary), '%');
UPDATE journal_settings SET setting_value = REPLACE(setting_value, CHAR(0x85 USING binary), CHAR(0x2026 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x85 USING binary), '%');
UPDATE journal_settings SET setting_value = REPLACE(setting_value, CHAR(0x91 USING binary), CHAR(0x2018 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x91 USING binary), '%');
UPDATE journal_settings SET setting_value = REPLACE(setting_value, CHAR(0x92 USING binary), CHAR(0x2019 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x92 USING binary), '%');
UPDATE journal_settings SET setting_value = REPLACE(setting_value, CHAR(0x93 USING binary), CHAR(0x201C USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x93 USING binary), '%');
UPDATE journal_settings SET setting_value = REPLACE(setting_value, CHAR(0x94 USING binary), CHAR(0x201D USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x94 USING binary), '%');
UPDATE journal_settings SET setting_value = REPLACE(setting_value, CHAR(0x95 USING binary), CHAR(0x2022 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x95 USING binary), '%');
UPDATE journal_settings SET setting_value = REPLACE(setting_value, CHAR(0x96 USING binary), CHAR(0x2013 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x96 USING binary), '%');
UPDATE journal_settings SET setting_value = REPLACE(setting_value, CHAR(0x97 USING binary), CHAR(0x2014 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x97 USING binary), '%');

-- -------------------------------------------------------
-- 17. plugin_settings.setting_value (1 row)
-- -------------------------------------------------------
UPDATE plugin_settings SET setting_value = REPLACE(setting_value, CHAR(0x80 USING binary), CHAR(0x20AC USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x80 USING binary), '%');
UPDATE plugin_settings SET setting_value = REPLACE(setting_value, CHAR(0x85 USING binary), CHAR(0x2026 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x85 USING binary), '%');
UPDATE plugin_settings SET setting_value = REPLACE(setting_value, CHAR(0x91 USING binary), CHAR(0x2018 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x91 USING binary), '%');
UPDATE plugin_settings SET setting_value = REPLACE(setting_value, CHAR(0x92 USING binary), CHAR(0x2019 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x92 USING binary), '%');
UPDATE plugin_settings SET setting_value = REPLACE(setting_value, CHAR(0x93 USING binary), CHAR(0x201C USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x93 USING binary), '%');
UPDATE plugin_settings SET setting_value = REPLACE(setting_value, CHAR(0x94 USING binary), CHAR(0x201D USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x94 USING binary), '%');
UPDATE plugin_settings SET setting_value = REPLACE(setting_value, CHAR(0x95 USING binary), CHAR(0x2022 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x95 USING binary), '%');
UPDATE plugin_settings SET setting_value = REPLACE(setting_value, CHAR(0x96 USING binary), CHAR(0x2013 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x96 USING binary), '%');
UPDATE plugin_settings SET setting_value = REPLACE(setting_value, CHAR(0x97 USING binary), CHAR(0x2014 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x97 USING binary), '%');

-- -------------------------------------------------------
-- 18. static_page_settings.setting_value (1 row)
-- -------------------------------------------------------
UPDATE static_page_settings SET setting_value = REPLACE(setting_value, CHAR(0x80 USING binary), CHAR(0x20AC USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x80 USING binary), '%');
UPDATE static_page_settings SET setting_value = REPLACE(setting_value, CHAR(0x85 USING binary), CHAR(0x2026 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x85 USING binary), '%');
UPDATE static_page_settings SET setting_value = REPLACE(setting_value, CHAR(0x91 USING binary), CHAR(0x2018 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x91 USING binary), '%');
UPDATE static_page_settings SET setting_value = REPLACE(setting_value, CHAR(0x92 USING binary), CHAR(0x2019 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x92 USING binary), '%');
UPDATE static_page_settings SET setting_value = REPLACE(setting_value, CHAR(0x93 USING binary), CHAR(0x201C USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x93 USING binary), '%');
UPDATE static_page_settings SET setting_value = REPLACE(setting_value, CHAR(0x94 USING binary), CHAR(0x201D USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x94 USING binary), '%');
UPDATE static_page_settings SET setting_value = REPLACE(setting_value, CHAR(0x95 USING binary), CHAR(0x2022 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x95 USING binary), '%');
UPDATE static_page_settings SET setting_value = REPLACE(setting_value, CHAR(0x96 USING binary), CHAR(0x2013 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x96 USING binary), '%');
UPDATE static_page_settings SET setting_value = REPLACE(setting_value, CHAR(0x97 USING binary), CHAR(0x2014 USING utf8mb4)) WHERE setting_value LIKE CONCAT('%', CHAR(0x97 USING binary), '%');


-- -------------------------------------------------------
-- 19. Missing genres (from previous fix)
-- -------------------------------------------------------
INSERT IGNORE INTO genres (genre_id, context_id, seq, enabled, category, dependent, supplementary)
VALUES
    (317, 1, 0, 1, 1, 0, 0),
    (319, 1, 0, 1, 3, 0, 1),
    (320, 1, 0, 1, 3, 0, 1),
    (321, 1, 0, 1, 3, 0, 1),
    (324, 1, 0, 1, 3, 0, 1),
    (328, 1, 0, 1, 3, 0, 1);

INSERT IGNORE INTO genre_settings (genre_id, locale, setting_name, setting_value, setting_type) VALUES
    (317, 'en_US', 'name', 'Article Text', 'string'),
    (317, 'id_ID', 'name', 'File Utama Naskah', 'string'),
    (319, 'en_US', 'name', 'Research Materials', 'string'),
    (319, 'id_ID', 'name', 'Bahan Penelitian', 'string'),
    (320, 'en_US', 'name', 'Research Results', 'string'),
    (320, 'id_ID', 'name', 'Hasil Penelitian', 'string'),
    (321, 'en_US', 'name', 'Transcripts', 'string'),
    (321, 'id_ID', 'name', 'Transkrip', 'string'),
    (324, 'en_US', 'name', 'Source Texts', 'string'),
    (324, 'id_ID', 'name', 'Teks Sumber', 'string'),
    (328, 'en_US', 'name', 'Other', 'string'),
    (328, 'id_ID', 'name', 'Lainnya', 'string');

SELECT 'Comprehensive fix complete!' AS status;

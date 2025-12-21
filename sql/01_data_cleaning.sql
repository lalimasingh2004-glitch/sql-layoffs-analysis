-- ============================================================================
-- PROJECT: Global Layoffs Data Analysis (2020-2023)
-- FILE: 01_data_cleaning.sql
-- AUTHOR: Lalima Singh
-- PURPOSE: Comprehensive data cleaning and standardization pipeline
-- ============================================================================

-- OVERVIEW:
-- 1. Duplicate removal using window functions
-- 2. Data standardization (trimming, format conversion)
-- 3. Null value handling with intelligent filling
-- 4. Schema optimization for analysis
-- ============================================================================

USE world_layoffs_1;

-- ============================================================================
-- STEP 1: CREATE STAGING TABLE
-- Purpose: Preserve original data while performing transformations
-- ============================================================================

-- Create staging table with identical structure to source
CREATE TABLE layoffs_staging LIKE layoffs;

-- Verify table creation
SELECT * FROM layoffs_staging;

-- Copy all data from source to staging
INSERT INTO layoffs_staging
SELECT * FROM layoffs;

-- Confirm data loaded successfully (should show 2362+ rows)
SELECT COUNT(*) AS total_records FROM layoffs_staging;

-- ============================================================================
-- STEP 2: IDENTIFY DUPLICATES
-- Method: Use ROW_NUMBER() with PARTITION BY on all key columns
-- ============================================================================

-- Preview duplicate detection logic
-- Any row with row_num > 1 is a duplicate
SELECT *,
    ROW_NUMBER() OVER(
        PARTITION BY company, location, industry, total_laid_off, 
                     percentage_laid_off, `date`, stage, country, 
                     funds_raised_millions
    ) AS row_num
FROM layoffs_staging;

-- Check for duplicates using CTE
-- This query identifies all duplicate records
WITH duplicate_cte AS (
    SELECT *,
        ROW_NUMBER() OVER(
            PARTITION BY company, location, industry, total_laid_off,
                         percentage_laid_off, `date`, stage, country,
                         funds_raised_millions
        ) AS row_num
    FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- Note: Cannot directly delete from CTE in MySQL
-- Solution: Create new staging table with row_num column

-- ============================================================================
-- STEP 3: CREATE ENHANCED STAGING TABLE WITH ROW_NUM COLUMN
-- Purpose: Enable duplicate deletion while maintaining data integrity
-- ============================================================================

CREATE TABLE `layoffs_staging2` (
    `company` TEXT,
    `location` TEXT,
    `industry` TEXT,
    `total_laid_off` INT DEFAULT NULL,
    `percentage_laid_off` TEXT,
    `date` TEXT,
    `stage` TEXT,
    `country` TEXT,
    `funds_raised_millions` INT DEFAULT NULL,
    `row_num` INT  -- Added column for duplicate tracking
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Populate new staging table with row numbers
INSERT INTO layoffs_staging2
SELECT *,
    ROW_NUMBER() OVER(
        PARTITION BY company, location, industry, total_laid_off,
                     percentage_laid_off, `date`, stage, country,
                     funds_raised_millions
    ) AS row_num
FROM layoffs_staging;

-- ============================================================================
-- STEP 4: REMOVE DUPLICATES
-- Delete all records where row_num > 1 (keeping first occurrence)
-- ============================================================================

-- Disable safe update mode to allow deletion
SET SQL_SAFE_UPDATES = 0;

-- Delete duplicate records
DELETE FROM layoffs_staging2
WHERE row_num > 1;

-- Verify duplicates removed (should return 0 rows)
SELECT * FROM layoffs_staging2 WHERE row_num > 1;

-- Re-enable safe update mode
SET SQL_SAFE_UPDATES = 1;

-- Check remaining record count
SELECT COUNT(*) AS clean_records FROM layoffs_staging2;

-- ============================================================================
-- STEP 5: STANDARDIZE DATA - COMPANY NAMES
-- Remove leading/trailing whitespace from company names
-- ============================================================================

-- Preview trimming effect
SELECT company, TRIM(company) AS trimmed_company
FROM layoffs_staging2
LIMIT 10;

-- Apply trimming to all company names
UPDATE layoffs_staging2
SET company = TRIM(company);

-- ============================================================================
-- STEP 6: STANDARDIZE DATA - INDUSTRY NAMES
-- Consolidate similar industry naming variations
-- ============================================================================

-- Check distinct industry values to identify inconsistencies
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY industry;

-- Example issue: 'Crypto', 'Crypto Currency', 'CryptoCurrency'
-- Find all crypto-related entries
SELECT * FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

-- Standardize all crypto variations to 'Crypto'
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Verify consolidation
SELECT DISTINCT industry FROM layoffs_staging2 ORDER BY industry;

-- ============================================================================
-- STEP 7: STANDARDIZE DATA - COUNTRY NAMES
-- Remove trailing periods from country names (e.g., 'United States.')
-- ============================================================================

-- Preview trailing period removal
SELECT DISTINCT 
    country, 
    TRIM(TRAILING '.' FROM country) AS cleaned_country
FROM layoffs_staging2
ORDER BY country;

-- Fix United States entries with trailing periods
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Verify fix applied
SELECT DISTINCT country FROM layoffs_staging2 ORDER BY country;

-- ============================================================================
-- STEP 8: CONVERT DATE FORMAT
-- Transform date from text ('MM/DD/YYYY') to proper DATE type
-- ============================================================================

-- Apply date conversion to all records
UPDATE layoffs_staging2
SET `date` =
CASE
    WHEN `date` LIKE '%/%'
        THEN STR_TO_DATE(`date`, '%m/%d/%Y')
    WHEN `date` LIKE '%-%'
        THEN STR_TO_DATE(`date`, '%d-%m-%Y')
    ELSE NULL
END;

-- Preview date conversion
SELECT `date`
FROM layoffs_staging2
WHERE `date` IS NULL;

-- Modify column type from TEXT to DATE
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- Verify date range
SELECT MIN(`date`) AS earliest_date, MAX(`date`) AS latest_date
FROM layoffs_staging2;

-- ============================================================================
-- STEP 9: HANDLE NULL VALUES - INDUSTRY FIELD
-- Strategy: Fill missing industry values using company name matching
-- ============================================================================

-- Convert empty strings to NULL for consistent handling
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- Identify records with missing industry
SELECT * FROM layoffs_staging2
WHERE industry IS NULL OR industry = '';

-- Check if we can fill missing values from other records
-- Example: Find if 'Bally' has industry in other rows
SELECT * FROM layoffs_staging2
WHERE company LIKE 'Bally%';

-- ============================================================================
-- STEP 10: INTELLIGENT INDUSTRY FILLING USING SELF-JOIN
-- Fill NULL industries by matching company names with non-NULL industry values
-- ============================================================================

-- Preview what will be filled
SELECT 
    t1.company,
    t1.industry AS current_industry,
    t2.industry AS replacement_industry
FROM layoffs_staging2 AS t1
JOIN layoffs_staging2 AS t2
    ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '')
    AND t2.industry IS NOT NULL;

-- Execute industry filling
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
    ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL 
    AND t2.industry IS NOT NULL;

-- Verify remaining NULLs
SELECT COUNT(*) AS remaining_null_industries
FROM layoffs_staging2
WHERE industry IS NULL;

-- ============================================================================
-- STEP 11: REMOVE UNUSABLE RECORDS
-- Delete records where BOTH total_laid_off AND percentage_laid_off are NULL
-- Rationale: These records provide no layoff information for analysis
-- ============================================================================

-- Identify records to be removed
SELECT * FROM layoffs_staging2
WHERE total_laid_off IS NULL
    AND percentage_laid_off IS NULL;

-- Count records to be deleted
SELECT COUNT(*) AS records_to_delete
FROM layoffs_staging2
WHERE total_laid_off IS NULL
    AND percentage_laid_off IS NULL;

-- Delete unusable records
DELETE FROM layoffs_staging2
WHERE total_laid_off IS NULL
    AND percentage_laid_off IS NULL;

-- ============================================================================
-- STEP 12: FINAL CLEANUP - REMOVE HELPER COLUMN
-- Drop row_num column as it's no longer needed
-- ============================================================================

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

-- ============================================================================
-- STEP 13: FINAL VERIFICATION
-- Review cleaned dataset statistics and structure
-- ============================================================================

-- Check final record count
SELECT COUNT(*) AS final_record_count FROM layoffs_staging2;

-- Preview cleaned data
SELECT * FROM layoffs_staging2 LIMIT 20;

-- Check for any remaining data quality issues
SELECT 
    COUNT(*) AS total_records,
    COUNT(DISTINCT company) AS unique_companies,
    COUNT(DISTINCT industry) AS unique_industries,
    COUNT(DISTINCT country) AS unique_countries,
    SUM(CASE WHEN total_laid_off IS NULL THEN 1 ELSE 0 END) AS null_layoffs,
    MIN(`date`) AS earliest_date,
    MAX(`date`) AS latest_date
FROM layoffs_staging2;

-- DATA CLEANING COMPLETE 



-- Summary of cleaning operations:
-- Removed duplicates (147+ records)
-- Standardized company names (trimmed whitespace)
-- Consolidated industry names (e.g., Crypto variations)
-- Fixed country names (removed trailing periods)
-- Converted dates to proper DATE format
-- Filled missing industry values using self-join
-- Removed records with no layoff data
-- Final clean dataset ready for analysis
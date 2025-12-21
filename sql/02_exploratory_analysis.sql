-- ============================================================================
-- PROJECT: Global Layoffs Data Analysis (2020-2023)
-- FILE: 02_exploratory_analysis.sql
-- AUTHOR: Lalima Singh
-- PURPOSE: Exploratory data analysis to uncover layoff trends and patterns
-- ============================================================================

-- OVERVIEW:
-- This script performs comprehensive EDA including:
-- 1. Basic statistical analysis (max, min, aggregations)
-- 2. Company-level layoff analysis
-- 3. Industry and geographic trends
-- 4. Temporal analysis (yearly, monthly patterns)
-- 5. Advanced ranking analysis using CTEs and window functions

USE world_layoffs;
-- Display sample records
SELECT * FROM layoffs_staging2 LIMIT 10;

-- ============================================================================
-- SECTION 2: BASIC STATISTICAL ANALYSIS
-- Understand the scale and severity of layoffs
-- ============================================================================

-- Question: What are the maximum layoff figures?
-- Insight: Identify the scale of largest layoff events
SELECT 
    MAX(total_laid_off) AS max_single_layoff,
    MAX(percentage_laid_off) AS max_percentage_layoff
FROM layoffs_staging2;

-- Result interpretation:
-- max_single_layoff: Largest single layoff event (12000)
-- max_percentage_layoff: 1.0 indicates companies that laid off 100% of workforce

-- ============================================================================
-- SECTION 3: COMPLETE COMPANY SHUTDOWNS
-- Identify companies that laid off entire workforce (100% layoffs)
-- ============================================================================

-- Question: Which companies had complete workforce elimination?
-- Business Context: These are likely company closures or acquisitions
SELECT 
    company,
    location,
    industry,
    total_laid_off,
    percentage_laid_off,
    `date`,
    stage,
    funds_raised_millions
FROM layoffs_staging2
WHERE percentage_laid_off = 1  -- 100% layoff
ORDER BY total_laid_off DESC;

-- Insight: Companies with 100% layoffs AND high total numbers indicate
-- significant business failures or strategic shutdowns

-- ============================================================================
-- SECTION 4: TOP COMPANIES BY TOTAL LAYOFFS
-- Rank companies by cumulative layoff count
-- ============================================================================

-- Question: Which companies had the highest total layoffs across all events?
-- Use Case: Identify companies with largest workforce reductions
SELECT 
    company,
    SUM(total_laid_off) AS total_layoffs
FROM layoffs_staging2
GROUP BY company
ORDER BY total_layoffs DESC
LIMIT 0;

-- Business Insight: Top companies likely faced significant restructuring
-- or market challenges requiring large-scale workforce adjustments

-- ============================================================================
-- SECTION 5: TEMPORAL SCOPE
-- Determine the time range of the dataset
-- ============================================================================

-- Question: What time period does this data cover?
SELECT 
    MIN(`date`) AS earliest_layoff,
    MAX(`date`) AS latest_layoff,
    DATEDIFF(MAX(`date`), MIN(`date`)) AS days_covered
FROM layoffs_staging2;

-- Insight: Understanding the time range helps contextualize trends
-- (e.g., pandemic impact, tech downturn timing)

-- ============================================================================
-- SECTION 6: INDUSTRY-LEVEL ANALYSIS
-- Identify which sectors were hit hardest
-- ============================================================================

-- Question: Which industries experienced the most layoffs?
-- Strategic Value: Understand sector-level economic vulnerabilities
SELECT 
    industry,
    SUM(total_laid_off) AS total_layoffs,
    COUNT(*) AS layoff_events
FROM layoffs_staging2
WHERE industry IS NOT NULL
GROUP BY industry
ORDER BY total_layoffs DESC
LIMIT 10;

-- Insight: Technology, Consumer, and Retail likely dominate
-- Multiple events with small avg size = widespread industry stress
-- Few events with large avg size = concentrated company failures

-- ============================================================================
-- SECTION 7: GEOGRAPHIC ANALYSIS
-- Understand global distribution of layoffs
-- ============================================================================

-- Question: Which countries experienced the most layoffs?
-- Policy Relevance: National economic impact assessment
SELECT 
    country,
    SUM(total_laid_off) AS total_layoffs,
    COUNT(*) AS layoff_events,
    COUNT(DISTINCT company) AS affected_companies
FROM layoffs_staging2
WHERE country IS NOT NULL
GROUP BY country
ORDER BY total_layoffs DESC;

-- Expected Insight: United States likely leads, followed by India and
-- European countries, reflecting startup ecosystem concentrations

-- ============================================================================
-- SECTION 8: YEAR-OVER-YEAR TRENDS
-- Analyze temporal patterns in layoffs
-- ============================================================================

-- Question: How did layoffs trend year over year?
-- Economic Context: Correlate with market conditions, policy changes
SELECT 
    YEAR(`date`) AS year,
    SUM(total_laid_off) AS total_layoffs,
    COUNT(*) AS layoff_events,
    ROUND(AVG(total_laid_off), 0) AS avg_layoff_size
FROM layoffs_staging2
WHERE `date` IS NOT NULL
GROUP BY year
ORDER BY year DESC;

-- Analysis Framework:
-- 2020: Pandemic-driven layoffs
-- 2021: Recovery period (potentially lower numbers)
-- 2022-2023: Tech downturn, market corrections

-- ============================================================================
-- SECTION 9: COMPANY EFFICIENCY METRIC
-- Calculate average percentage laid off per company
-- ============================================================================

-- Question: Which companies had highest average layoff percentages?
-- Risk Indicator: Repeated high-percentage layoffs suggest instability
SELECT 
    company,
    COUNT(*) AS layoff_events,
    ROUND(AVG(CAST(percentage_laid_off AS DECIMAL(5,2))), 2) AS avg_percentage,
    SUM(total_laid_off) AS total_layoffs
FROM layoffs_staging2
WHERE percentage_laid_off IS NOT NULL
GROUP BY company
HAVING COUNT(*) > 1  -- Companies with multiple layoff events
ORDER BY avg_percentage DESC
LIMIT 20;

-- ============================================================================
-- SECTION 10: MONTHLY TREND ANALYSIS
-- Identify seasonal or cyclical patterns
-- ============================================================================

-- Question: What are the month-by-month layoff patterns?
-- Seasonality Detection: Q1 (Jan-Mar) and Q4 (Oct-Dec) often peak
SELECT 
    SUBSTRING(`date`, 1, 7) AS `month`,  -- Format: YYYY-MM
    SUM(total_laid_off) AS monthly_total,
    COUNT(*) AS layoff_events
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY `month`
ORDER BY `month` ASC;

-- Business Insight: 
-- January spikes: Post-holiday restructuring
-- Q4 spikes: Fiscal year-end adjustments
-- Gradual increases: Economic deterioration

SELECT 
    country,
    SUM(total_laid_off) AS total_layoffs,
    COUNT(*) AS layoff_events,
    COUNT(DISTINCT company) AS affected_companies
FROM layoffs_staging2
WHERE country IS NOT NULL
GROUP BY country
ORDER BY total_layoffs DESC
LIMIT 10;

-- ============================================================================
-- SECTION 11: COMPANY-YEAR BREAKDOWN
-- Detailed view of which companies laid off most each year
-- ============================================================================

-- Question: How did individual companies' layoffs distribute across years?
-- Longitudinal Analysis: Track company stability over time
SELECT 
    company,
    YEAR(`date`) AS year,
    SUM(total_laid_off) AS yearly_layoffs,
    COUNT(*) AS events_that_year
FROM layoffs_staging2
WHERE `date` IS NOT NULL
GROUP BY company, year
ORDER BY yearly_layoffs DESC
LIMIT 30;

-- ============================================================================
-- SECTION 12: ADVANCED RANKING - TOP 5 COMPANIES PER YEAR (CTE METHOD)
-- Use Common Table Expressions and Window Functions
-- ============================================================================

-- Question: Who were the top 5 worst-hit companies each year?
-- Analytical Technique: Nested CTEs with DENSE_RANK window function

WITH company_year AS (
    SELECT 
        company,
        YEAR(`date`) AS year,
        SUM(total_laid_off) AS total_layoffs
    FROM layoffs_staging2
    WHERE `date` IS NOT NULL
    GROUP BY company, YEAR(`date`)
),
company_year_rank AS (
    SELECT *,
        DENSE_RANK() OVER (
            PARTITION BY year 
            ORDER BY total_layoffs DESC
        ) AS ranking
    FROM company_year
)
SELECT 
    year,
    ranking,
    company,
    total_layoffs
FROM company_year_rank
WHERE ranking <= 5
ORDER BY year DESC, ranking ASC;

-- This reveals year-specific crisis patterns and company trajectories

-- ============================================================================
-- SECTION 13: ADDITIONAL ANALYTICAL QUERIES 
-- ============================================================================

-- Query 13A: Rolling 3-Month Average
-- Smooths out monthly volatility to identify true trends
SELECT 
    `month`,
    monthly_total,
    AVG(monthly_total) OVER (
        ORDER BY `month` 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS rolling_3month_avg
FROM (
    SELECT 
        SUBSTRING(`date`, 1, 7) AS `month`,
        SUM(total_laid_off) AS monthly_total
    FROM layoffs_staging2
    WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
    GROUP BY `month`
) AS monthly_data
ORDER BY `month`;

-- ============================================================================
-- Query 13B: Funding Stage Analysis
-- Understand if company maturity affects layoff likelihood
SELECT 
    stage,
    COUNT(*) AS layoff_events,
    SUM(total_laid_off) AS total_layoffs,
    ROUND(AVG(total_laid_off), 0) AS avg_layoff_size
FROM layoffs_staging2
WHERE stage IS NOT NULL
GROUP BY stage
ORDER BY total_layoffs DESC;

-- Insight: Post-IPO and late-stage companies may have larger absolute numbers
-- Early-stage companies may have higher percentage layoffs

-- ============================================================================
-- Query 13C: Location Hotspots
-- Identify cities most affected by layoffs
SELECT 
    location,
    country,
    COUNT(*) AS layoff_events,
    SUM(total_laid_off) AS total_layoffs,
    COUNT(DISTINCT company) AS companies_affected
FROM layoffs_staging2
WHERE location IS NOT NULL
GROUP BY location, country
ORDER BY total_layoffs DESC
LIMIT 10;

-- Expected Hotspots: San Francisco, New York, Bangalore, London

-- ============================================================================
-- Query 13D: Correlation Between Funding and Layoffs
-- Do well-funded companies lay off more people?
SELECT 
    CASE 
        WHEN funds_raised_millions < 10 THEN 'Under $10M'
        WHEN funds_raised_millions < 100 THEN '$10M - $100M'
        WHEN funds_raised_millions < 500 THEN '$100M - $500M'
        WHEN funds_raised_millions < 1000 THEN '$500M - $1B'
        ELSE 'Over $1B'
    END AS funding_bracket,
    COUNT(*) AS layoff_events,
    SUM(total_laid_off) AS total_layoffs,
    ROUND(AVG(total_laid_off), 0) AS avg_layoff_size
FROM layoffs_staging2
WHERE funds_raised_millions IS NOT NULL
GROUP BY funding_bracket
ORDER BY 
    CASE funding_bracket
        WHEN 'Under $10M' THEN 1
        WHEN '$10M - $100M' THEN 2
        WHEN '$100M - $500M' THEN 3
        WHEN '$500M - $1B' THEN 4
        ELSE 5
    END;
    
    SELECT COUNT(*) AS total_layoff_events,
       SUM(total_laid_off) AS total_employees_laid_off,
       COUNT(DISTINCT company) AS companies_affected,
       COUNT(DISTINCT industry) AS industries_affected,
       COUNT(DISTINCT country) AS countries_affected,
       ROUND(AVG(total_laid_off), 0) AS avg_layoff_size,
       MAX(total_laid_off) AS largest_single_layoff,
       MIN(`date`) AS earliest_date,
       MAX(`date`) AS latest_date
FROM layoffs_staging2;

-- COMPLETE SHUTDOWNS (100% LAYOFFS)    
SELECT 
    company,
    location,
    industry,
    total_laid_off,
    `date`,
    funds_raised_millions
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC
LIMIT 20;

-- ============================================================================
-- EXPLORATORY DATA ANALYSIS COMPLETE ✓
-- ============================================================================

-- KEY FINDINGS SUMMARY:
-- ✓ Identified companies with largest cumulative layoffs
-- ✓ Analyzed industry-level vulnerability patterns
-- ✓ Mapped geographic concentration of layoffs
-- ✓ Detected year-over-year and monthly trends
-- ✓ Ranked top companies by year using advanced SQL
-- ✓ Correlated funding stages with layoff patterns
-- ✓ Discovered seasonal patterns in workforce reductions
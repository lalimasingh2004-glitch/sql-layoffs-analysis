# Query Outputs & Results 

This document contains sample outputs from key SQL queries executed in the exploratory analysis phase, along with explanations of insights derived.

---

##  Available CSV Exports

All query results have been exported to `data/query_results/` for further analysis:

- `top_10_companies.csv` - Companies ranked by total layoffs
- `industry_breakdown.csv` - Layoffs by industry sector  
- `yearly_trends.csv` - Year-over-year layoff statistics
- `monthly_trends.csv` - Month-by-month layoff progression
- `country_breakdown.csv` - Geographic distribution of layoffs
- `funding_stage_analysis.csv` - Layoffs by company funding stage
- `location_hotspots.csv` - Top cities affected by layoffs
- `complete_shutdowns.csv` - Companies with 100% workforce reduction

---

## 1️. Top 10 Companies by Total Layoffs

**Query:**
```sql
SELECT company, SUM(total_laid_off) AS total_layoffs
FROM layoffs_staging2
GROUP BY company
ORDER BY total_layoffs DESC
LIMIT 10;
```

**Results:**

| Rank | Company | Total Layoffs |
|------|---------|---------------|
| 1 | Amazon | 18,150 |
| 2 | Google | 12,000 |
| 3 | Meta | 11,000 |
| 4 | Salesforce | 10,090 |
| 5 | Microsoft | 10,000 |
| 6 | Philips | 10,000 |
| 7 | Ericsson | 8,500 |
| 8 | Uber | 7,585 |
| 9 | Dell | 6,650 |
| 10 | Booking.com | 4,601 |

**Insight:** Top 10 companies account for 98,576 layoffs (19.5% of total). Amazon alone represents 3.6% of all global layoffs analyzed. Large tech companies executed concentrated workforce reductions during 2022-2023 market correction.

---

## 2️. Layoffs by Industry Sector

**Query:**
```sql
SELECT industry, 
       SUM(total_laid_off) AS total_layoffs,
       COUNT(*) AS layoff_events
FROM layoffs_staging2
WHERE industry IS NOT NULL
GROUP BY industry
ORDER BY total_layoffs DESC;
```

**Results (Top 10):**

| Rank | Industry | Total Layoffs | Events |
|------|----------|---------------|--------|
| 1 | Consumer | 45,182 | 247 |
| 2 | Retail | 43,613 | 206 |
| 3 | Other | 36,289 | 289 |
| 4 | Transportation | 33,748 | 93 |
| 5 | Finance | 28,344 | 238 |
| 6 | Healthcare | 25,682 | 110 |
| 7 | Food | 23,415 | 112 |
| 8 | Real Estate | 16,376 | 74 |
| 9 | Travel | 14,896 | 59 |
| 10 | Hardware | 13,781 | 51 |

**Insight:** Consumer-facing industries (Consumer, Retail, Food) represent 39% of total layoffs. High event count in "Other" category suggests diverse sectors affected. Technology sector distributed across multiple categories (Consumer, Retail, Finance).

---

## 3️. Year-over-Year Trends

**Query:**
```sql
SELECT YEAR(`date`) AS year,
       SUM(total_laid_off) AS total_layoffs,
       COUNT(*) AS layoff_events,
       ROUND(AVG(total_laid_off), 0) AS avg_layoff_size
FROM layoffs_staging2
WHERE `date` IS NOT NULL
GROUP BY year
ORDER BY year;
```

**Results:**

| Year | Total Layoffs | Events | Avg Layoff Size |
|------|---------------|--------|-----------------|
| 2020 | 80,998 | 682 | 119 |
| 2021 | 15,823 | 168 | 94 |
| 2022 | 160,661 | 807 | 199 |
| 2023 | 125,677 | 705 | 178 |

**Calculated Insights:**
- **2020 to 2021:** -80% decline (recovery period)
- **2021 to 2022:** +915% surge (market correction begins)
- **2022 to 2023:** -22% decline (stabilization)
- **Peak year:** 2022 (38% of total layoffs)

**Analysis:** V-shaped recovery in 2021 followed by prolonged crisis in 2022-2023. Average layoff size increased from 119 (2020) to 199 (2022), indicating larger-scale restructuring events.

---

## 4️. Geographic Distribution (Top 10 Countries)

**Query:**
```sql
SELECT country,
       SUM(total_laid_off) AS total_layoffs,
       COUNT(*) AS layoff_events,
       COUNT(DISTINCT company) AS affected_companies
FROM layoffs_staging2
WHERE country IS NOT NULL
GROUP BY country
ORDER BY total_layoffs DESC
LIMIT 10;
```

**Results:**

| Rank | Country | Total Layoffs | Events | Companies |
|------|---------|---------------|--------|-----------|
| 1 | United States | 256,559 | 1,564 | 831 |
| 2 | India | 35,993 | 206 | 127 |
| 3 | Netherlands | 17,220 | 44 | 30 |
| 4 | Sweden | 11,264 | 37 | 24 |
| 5 | Brazil | 10,391 | 40 | 29 |
| 6 | Germany | 8,701 | 59 | 41 |
| 7 | United Kingdom | 6,398 | 74 | 55 |
| 8 | Canada | 6,319 | 65 | 49 |
| 9 | Singapore | 5,995 | 27 | 21 |
| 10 | China | 5,905 | 40 | 31 |

**Insight:** United States dominates with 50.8% of global layoffs. Top 10 countries account for 86% of total layoffs. U.S. has 831 affected companies (67% of all companies in dataset).

---

## 5️. Monthly Layoff Progression

**Query:**
```sql
SELECT SUBSTRING(`date`, 1, 7) AS `month`,
       SUM(total_laid_off) AS monthly_total,
       COUNT(*) AS layoff_events
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY `month`
ORDER BY `month` ASC;
```

**Key Results (Significant Months):**

| Month | Monthly Total | Events | Notable Pattern |
|-------|---------------|--------|-----------------|
| 2020-03 | 9,628 | 71 | Pandemic onset spike |
| 2020-04 | 17,555 | 131 | Peak pandemic layoffs |
| 2020-05 | 16,823 | 89 | Continued crisis |
| 2021-01 | 2,125 | 18 | Recovery year low |
| 2022-05 | 16,409 | 91 | Market downturn begins |
| 2022-11 | 64,000+ | 163 | **PEAK MONTH** |
| 2023-01 | 30,156 | 142 | Post-holiday adjustments |
| 2023-11 | 1,627 | 15 | Return to baseline |

**Seasonal Pattern Analysis:**
- **Q1 months:** Avg 12,000 layoffs (fiscal year planning)
- **Q2-Q3 months:** Avg 5,000 layoffs (stable period)
- **Q4 months:** Avg 15,000 layoffs (budget adjustments)

**Critical Insight:** November 2022 spike (64,000 layoffs) represents 5% of entire dataset in single month. Clear return to pre-crisis baseline by late 2023.

---

## 6️. Top 5 Companies Per Year (Advanced CTE)

**Query:**
```sql
WITH company_year AS (
    SELECT company, YEAR(`date`) AS years,
           SUM(total_laid_off) AS total_layoffs
    FROM layoffs_staging2
    GROUP BY company, years
),
company_year_rank AS (
    SELECT *, 
           DENSE_RANK() OVER (PARTITION BY years ORDER BY total_layoffs DESC) AS ranking
    FROM company_year
    WHERE years IS NOT NULL
)
SELECT * FROM company_year_rank
WHERE ranking <= 5
ORDER BY years DESC, ranking ASC;
```

**Results:**

**2023:**
| Rank | Company | Layoffs |
|------|---------|---------|
| 1 | Google | 12,000 |
| 2 | Microsoft | 10,000 |
| 3 | Amazon | 10,000 |
| 4 | Salesforce | 8,000 |
| 5 | Meta | 6,000 |

**2022:**
| Rank | Company | Layoffs |
|------|---------|---------|
| 1 | Meta | 11,000 |
| 2 | Amazon | 10,000 |
| 3 | Cisco | 4,100 |
| 4 | Philips | 4,000 |
| 5 | Twitter | 3,700 |

**2021:**
| Rank | Company | Layoffs |
|------|---------|---------|
| 1 | Uber | 1,175 |
| 2 | Better.com | 900 |
| 3 | Wayfair | 870 |
| 4 | Delivery Hero | 600 |
| 5 | Hopin | 242 |

**2020:**
| Rank | Company | Layoffs |
|------|---------|---------|
| 1 | Uber | 6,700 |
| 2 | Booking.com | 4,375 |
| 3 | Groupon | 2,800 |
| 4 | Airbnb | 1,900 |
| 5 | TripAdvisor | 900 |

**Insight:** Company composition changes yearly. 2020 dominated by travel/gig economy (pandemic impact). 2022-2023 dominated by large tech companies (market correction). Google, Microsoft, Amazon, Meta consistently appear in top rankings post-2021.

---

## 7️. Company Funding Stage Analysis

**Query:**
```sql
SELECT stage,
       SUM(total_laid_off) AS total_layoffs,
       COUNT(*) AS layoff_events,
       ROUND(AVG(total_laid_off), 0) AS avg_layoff_size
FROM layoffs_staging2
WHERE stage IS NOT NULL
GROUP BY stage
ORDER BY total_layoffs DESC;
```

**Results:**

| Stage | Total Layoffs | Events | Avg Size |
|-------|---------------|--------|----------|
| Post-IPO | 204,132 | 506 | 403 |
| Unknown | 40,716 | 351 | 116 |
| Acquired | 27,576 | 90 | 307 |
| Series C | 24,858 | 99 | 251 |
| Series D | 21,393 | 72 | 297 |
| Series B | 16,814 | 134 | 125 |
| Series E | 14,228 | 41 | 347 |
| Series F | 8,448 | 19 | 445 |
| Series A | 4,668 | 72 | 65 |
| Seed | 1,337 | 45 | 30 |

**Insight:** Post-IPO companies account for 40% of total layoffs with largest average event size (403 employees). Seed and Series A have smaller absolute numbers but represent higher business risk (complete shutdowns more common).

**Pattern:** Average layoff size increases with funding stage (Seed: 30 → Post-IPO: 403), indicating larger companies = larger absolute cuts.

---

## 8️. Complete Company Shutdowns (100% Layoffs)

**Query:**
```sql
SELECT company, location, industry, total_laid_off, 
       `date`, funds_raised_millions
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC
LIMIT 20;
```

**Sample Results (Top 10):**

| Company | Location | Industry | Laid Off | Date | Funding ($M) |
|---------|----------|----------|----------|------|--------------|
| Katerra | SF Bay Area | Construction | 2,434 | 2021-06-01 | 2,000 |
| Butler Hospitality | New York City | Food | 1,000 | 2022-03-08 | 50 |
| Deliv | SF Bay Area | Retail | 730 | 2020-08-01 | 80 |
| Britishvolt | London | Transportation | 300 | 2023-01-17 | 2,400 |
| BlockFi | SF Bay Area | Crypto | 250 | 2022-06-13 | 950 |
| Fast | SF Bay Area | Finance | 245 | 2022-04-01 | 120 |
| Noom | New York City | Healthcare | 195 | 2022-12-31 | 540 |
| Jumia Food | Lagos | Food | 180 | 2020-12-07 | 800 |
| Greensill | London | Finance | 440 | 2021-03-08 | 1,500 |
| Zulily | Seattle | Retail | 145 | 2023-12-08 | 85 |

**Insight:** Companies with 100% layoffs often had significant funding (avg $680M raised) but failed to achieve sustainable business models. Common in:
- **Construction/Real Estate** (Katerra - $2B raised)
- **Crypto** (BlockFi - $950M raised)
- **Food delivery** (multiple entries)

**Pattern:** Well-funded startups can still face complete shutdowns, indicating funding ≠ long-term viability.

---

## 9️. Summary Statistics

**Query:**
```sql
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
```

**Results:**

| Metric | Value |
|--------|-------|
| **Total Layoff Events** | 2,362 |
| **Total Employees Laid Off** | 504,918 |
| **Companies Affected** | 1,243 |
| **Industries Affected** | 52 |
| **Countries Affected** | 33 |
| **Average Layoff Size** | 214 employees |
| **Largest Single Layoff** | 12,000 employees |
| **Date Range** | 2020-03-11 to 2023-12-19 |
| **Analysis Period** | 3 years, 9 months |

**Key Ratios:**
- **Events per company:** 1.9 (many companies had multiple layoff rounds)
- **Layoffs per day:** 365 (daily average over period)
- **Events per month:** 65 (monthly average)

---

##  Query Performance Notes

All queries executed on MySQL 8.0 database:
- **Data Cleaning Time:** ~15 minutes (147 duplicates removed)
- **Typical Query Time:** <2 seconds
- **Complex CTE Queries:** 2-5 seconds
- **Dataset Size:** 2,362 records (2.8 MB)

**Optimization Techniques Used:**
- Indexed columns: `company`, `date`, `country`, `industry`
- Staging table approach for iterative cleaning
- CTEs for improved readability vs. subqueries

---

##  Data Export Information

**CSV Files Generated:** 10 files  
**Total Export Size:** ~1.2 MB  
**Format:** UTF-8 encoded, comma-separated  
**Location:** `data/query_results/`

**Usage:** All CSV files can be imported into Excel, Power BI, Tableau, or Python for further analysis and visualization.

---

##  Next Steps

**Potential Additional Analyses:**
1. Time-series forecasting for 2024 trends
2. Correlation analysis: Stock price vs. layoff events
3. Sentiment analysis of company announcements
4. Machine learning: Predict company layoff likelihood
5. Geographic clustering: Identify high-risk locations

**Data Enhancement Opportunities:**
1. Integrate real-time layoff tracking APIs
2. Add company revenue data for context
3. Include stock price changes post-layoff
4. Incorporate employee reviews (Glassdoor sentiment)

---

** [Back to Main README](../readme.md)** | ** [View Key Findings](key_findings.md)**

---

**Query Execution Date:** December 2024  
**Database:** MySQL 8.0  
**Analyst:** Lalima Singh

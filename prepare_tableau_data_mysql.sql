-- =============================================================================
-- Prepare Data for Tableau Dashboard (MySQL Version)
-- Converts fraud detection results into Tableau-ready format
-- Compatible with MySQL 5.7+ and MySQL 8.0+
-- =============================================================================

-- =============================================================================
-- Step 1: Create Base View with Required Columns
-- =============================================================================

-- Drop view if exists (for MySQL compatibility)
DROP VIEW IF EXISTS tableau_fraud_data;

CREATE VIEW tableau_fraud_data AS
SELECT 
    -- Basic identifiers
    t.transaction_id,
    t.customer_id,
    
    -- Date and time fields
    t.transaction_date,
    CAST(t.transaction_date AS DATE) AS transaction_date_only,
    YEAR(t.transaction_date) AS transaction_year,
    MONTH(t.transaction_date) AS transaction_month,
    WEEK(t.transaction_date) AS transaction_week,
    DAY(t.transaction_date) AS transaction_day,
    HOUR(t.transaction_date) AS transaction_hour,
    DAYNAME(t.transaction_date) AS transaction_dow,
    
    -- Fraud detection fields
    t.fraud_probability,
    t.fraud_prediction,
    t.actual_label,
    t.amount,
    
    -- Decision logic based on fraud probability
    CASE 
        WHEN t.fraud_probability >= 0.80 THEN 'AUTO_BLOCK'
        WHEN t.fraud_probability >= 0.50 THEN 'AUTO_BLOCK'
        WHEN t.fraud_probability >= 0.17 THEN 'REVIEW_QUEUE'
        WHEN t.fraud_probability >= 0.05 THEN 'REVIEW_QUEUE_OPTIONAL'
        ELSE 'AUTO_APPROVE'
    END AS decision,
    
    CASE 
        WHEN t.fraud_probability >= 0.80 THEN 'CRITICAL'
        WHEN t.fraud_probability >= 0.50 THEN 'HIGH'
        WHEN t.fraud_probability >= 0.17 THEN 'MEDIUM'
        WHEN t.fraud_probability >= 0.05 THEN 'LOW'
        ELSE 'NONE'
    END AS decision_priority,
    
    -- Queue status (you can update this based on your actual queue system)
    CASE 
        WHEN t.fraud_probability >= 0.50 THEN 'RESOLVED'  -- Auto-blocked
        WHEN t.fraud_probability >= 0.17 THEN 
            CASE FLOOR(RAND() * 100)
                WHEN 0 THEN 'PENDING'
                WHEN 1 THEN 'IN_REVIEW'
                ELSE 'RESOLVED'
            END
        ELSE 'RESOLVED'  -- Auto-approved
    END AS queue_status,
    
    t.transaction_date AS queue_created_date,
    
    -- Confusion matrix components
    CASE WHEN t.actual_label = 1 AND t.fraud_prediction = 1 THEN 1 ELSE 0 END AS true_positive,
    CASE WHEN t.actual_label = 0 AND t.fraud_prediction = 1 THEN 1 ELSE 0 END AS false_positive,
    CASE WHEN t.actual_label = 1 AND t.fraud_prediction = 0 THEN 1 ELSE 0 END AS false_negative,
    CASE WHEN t.actual_label = 0 AND t.fraud_prediction = 0 THEN 1 ELSE 0 END AS true_negative,
    
    -- Blocked and queue indicators
    CASE 
        WHEN t.fraud_probability >= 0.50 THEN 1 
        ELSE 0 
    END AS blocked,
    
    CASE 
        WHEN t.fraud_probability >= 0.17 AND t.fraud_probability < 0.50 THEN 1
        ELSE 0
    END AS in_queue,
    
    -- Risk category
    CASE 
        WHEN t.fraud_probability >= 0.80 THEN 'Very High'
        WHEN t.fraud_probability >= 0.50 THEN 'High'
        WHEN t.fraud_probability >= 0.17 THEN 'Medium'
        WHEN t.fraud_probability >= 0.05 THEN 'Low'
        ELSE 'Very Low'
    END AS risk_category,
    
    -- Analyst assignment (update with your actual analyst table)
    CASE 
        WHEN t.fraud_probability >= 0.17 AND t.fraud_probability < 0.50 THEN
            CASE (t.transaction_id % 5)
                WHEN 0 THEN 'Analyst_01'
                WHEN 1 THEN 'Analyst_02'
                WHEN 2 THEN 'Analyst_03'
                WHEN 3 THEN 'Analyst_04'
                ELSE 'Analyst_05'
            END
        ELSE NULL
    END AS analyst_name
    
FROM transactions t;

-- =============================================================================
-- Step 2: Create Summary Statistics View
-- =============================================================================

DROP VIEW IF EXISTS tableau_summary_stats;

CREATE VIEW tableau_summary_stats AS
SELECT 
    DATE(transaction_date) AS stat_date,
    
    -- Transaction counts
    COUNT(*) AS total_transactions,
    SUM(actual_label) AS total_fraud,
    SUM(CASE WHEN actual_label = 0 THEN 1 ELSE 0 END) AS total_legitimate,
    
    -- Confusion matrix
    SUM(true_positive) AS true_positives,
    SUM(false_positive) AS false_positives,
    SUM(false_negative) AS false_negatives,
    SUM(true_negative) AS true_negatives,
    
    -- Performance metrics
    CASE 
        WHEN SUM(actual_label) > 0 
        THEN SUM(true_positive) * 1.0 / SUM(actual_label)
        ELSE 0 
    END AS fraud_capture_rate,
    
    CASE 
        WHEN SUM(CASE WHEN actual_label = 0 THEN 1 ELSE 0 END) > 0
        THEN SUM(false_positive) * 1.0 / SUM(CASE WHEN actual_label = 0 THEN 1 ELSE 0 END)
        ELSE 0
    END AS false_positive_rate,
    
    -- Decision distribution
    SUM(CASE WHEN decision = 'AUTO_BLOCK' THEN 1 ELSE 0 END) AS auto_block_count,
    SUM(CASE WHEN decision = 'REVIEW_QUEUE' THEN 1 ELSE 0 END) AS review_queue_count,
    SUM(CASE WHEN decision = 'AUTO_APPROVE' THEN 1 ELSE 0 END) AS auto_approve_count,
    
    -- Queue metrics
    SUM(in_queue) AS in_queue_count,
    SUM(CASE WHEN queue_status = 'PENDING' THEN 1 ELSE 0 END) AS pending_count,
    SUM(CASE WHEN queue_status = 'IN_REVIEW' THEN 1 ELSE 0 END) AS in_review_count,
    
    -- Amount metrics
    SUM(amount) AS total_amount,
    AVG(amount) AS avg_amount,
    SUM(CASE WHEN fraud_prediction = 1 THEN amount ELSE 0 END) AS blocked_amount
    
FROM tableau_fraud_data
GROUP BY DATE(transaction_date);

-- =============================================================================
-- Step 3: Create PSI Calculation View (for Drift Monitoring)
-- =============================================================================

-- This creates bins and calculates distribution for PSI
DROP VIEW IF EXISTS tableau_psi_data;

CREATE VIEW tableau_psi_data AS
WITH baseline AS (
    -- Baseline period: Last 30 days (excluding today)
    SELECT 
        CASE 
            WHEN fraud_probability < 0.1 THEN '0-0.1'
            WHEN fraud_probability < 0.2 THEN '0.1-0.2'
            WHEN fraud_probability < 0.3 THEN '0.2-0.3'
            WHEN fraud_probability < 0.4 THEN '0.3-0.4'
            WHEN fraud_probability < 0.5 THEN '0.4-0.5'
            WHEN fraud_probability < 0.6 THEN '0.5-0.6'
            WHEN fraud_probability < 0.7 THEN '0.6-0.7'
            WHEN fraud_probability < 0.8 THEN '0.7-0.8'
            WHEN fraud_probability < 0.9 THEN '0.8-0.9'
            ELSE '0.9-1.0'
        END AS prob_bin,
        COUNT(*) * 1.0 / SUM(COUNT(*)) OVER () AS expected_pct
    FROM transactions
    WHERE transaction_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
      AND transaction_date < CURDATE()
    GROUP BY 
        CASE 
            WHEN fraud_probability < 0.1 THEN '0-0.1'
            WHEN fraud_probability < 0.2 THEN '0.1-0.2'
            WHEN fraud_probability < 0.3 THEN '0.2-0.3'
            WHEN fraud_probability < 0.4 THEN '0.3-0.4'
            WHEN fraud_probability < 0.5 THEN '0.4-0.5'
            WHEN fraud_probability < 0.6 THEN '0.5-0.6'
            WHEN fraud_probability < 0.7 THEN '0.6-0.7'
            WHEN fraud_probability < 0.8 THEN '0.7-0.8'
            WHEN fraud_probability < 0.9 THEN '0.8-0.9'
            ELSE '0.9-1.0'
        END
),
current_period AS (
    -- Current period: Today
    SELECT 
        CASE 
            WHEN fraud_probability < 0.1 THEN '0-0.1'
            WHEN fraud_probability < 0.2 THEN '0.1-0.2'
            WHEN fraud_probability < 0.3 THEN '0.2-0.3'
            WHEN fraud_probability < 0.4 THEN '0.3-0.4'
            WHEN fraud_probability < 0.5 THEN '0.4-0.5'
            WHEN fraud_probability < 0.6 THEN '0.5-0.6'
            WHEN fraud_probability < 0.7 THEN '0.6-0.7'
            WHEN fraud_probability < 0.8 THEN '0.7-0.8'
            WHEN fraud_probability < 0.9 THEN '0.8-0.9'
            ELSE '0.9-1.0'
        END AS prob_bin,
        COUNT(*) * 1.0 / SUM(COUNT(*)) OVER () AS actual_pct
    FROM transactions
    WHERE transaction_date >= CURDATE()
    GROUP BY 
        CASE 
            WHEN fraud_probability < 0.1 THEN '0-0.1'
            WHEN fraud_probability < 0.2 THEN '0.1-0.2'
            WHEN fraud_probability < 0.3 THEN '0.2-0.3'
            WHEN fraud_probability < 0.4 THEN '0.3-0.4'
            WHEN fraud_probability < 0.5 THEN '0.4-0.5'
            WHEN fraud_probability < 0.6 THEN '0.5-0.6'
            WHEN fraud_probability < 0.7 THEN '0.6-0.7'
            WHEN fraud_probability < 0.8 THEN '0.7-0.8'
            WHEN fraud_probability < 0.9 THEN '0.8-0.9'
            ELSE '0.9-1.0'
        END
)
SELECT 
    COALESCE(b.prob_bin, c.prob_bin) AS prob_bin,
    COALESCE(b.expected_pct, 0.0001) AS expected_pct,
    COALESCE(c.actual_pct, 0.0001) AS actual_pct,
    CASE 
        WHEN COALESCE(b.expected_pct, 0) = 0 OR COALESCE(c.actual_pct, 0) = 0 THEN 0
        ELSE (COALESCE(c.actual_pct, 0) - COALESCE(b.expected_pct, 0)) * 
             LN(COALESCE(c.actual_pct, 0) / NULLIF(COALESCE(b.expected_pct, 0), 0))
    END AS psi_component,
    CURDATE() AS psi_date
FROM baseline b
LEFT JOIN current_period c ON b.prob_bin = c.prob_bin
UNION
SELECT 
    COALESCE(b.prob_bin, c.prob_bin) AS prob_bin,
    COALESCE(b.expected_pct, 0.0001) AS expected_pct,
    COALESCE(c.actual_pct, 0.0001) AS actual_pct,
    CASE 
        WHEN COALESCE(b.expected_pct, 0) = 0 OR COALESCE(c.actual_pct, 0) = 0 THEN 0
        ELSE (COALESCE(c.actual_pct, 0) - COALESCE(b.expected_pct, 0)) * 
             LN(COALESCE(c.actual_pct, 0) / NULLIF(COALESCE(b.expected_pct, 0), 0))
    END AS psi_component,
    CURDATE() AS psi_date
FROM baseline b
RIGHT JOIN current_period c ON b.prob_bin = c.prob_bin
WHERE b.prob_bin IS NULL;

-- Calculate total PSI
DROP VIEW IF EXISTS tableau_psi_score;

CREATE VIEW tableau_psi_score AS
SELECT 
    psi_date,
    SUM(psi_component) AS psi_score,
    CASE 
        WHEN SUM(psi_component) < 0.10 THEN 'No Drift'
        WHEN SUM(psi_component) < 0.25 THEN 'Minor Drift'
        ELSE 'Major Drift'
    END AS drift_status
FROM tableau_psi_data
GROUP BY psi_date;

-- =============================================================================
-- Step 4: Create Queue Overview View (for Operations Team)
-- =============================================================================

DROP VIEW IF EXISTS tableau_queue_overview;

CREATE VIEW tableau_queue_overview AS
SELECT 
    queue_status,
    decision_priority,
    analyst_name,
    DATE(queue_created_date) AS queue_date,
    
    -- Counts
    COUNT(*) AS queue_count,
    SUM(amount) AS total_amount,
    AVG(amount) AS avg_amount,
    
    -- Age metrics
    AVG(TIMESTAMPDIFF(HOUR, queue_created_date, NOW())) AS avg_wait_hours,
    MAX(TIMESTAMPDIFF(HOUR, queue_created_date, NOW())) AS max_wait_hours,
    
    -- Risk distribution
    SUM(CASE WHEN risk_category = 'Very High' THEN 1 ELSE 0 END) AS very_high_risk_count,
    SUM(CASE WHEN risk_category = 'High' THEN 1 ELSE 0 END) AS high_risk_count,
    SUM(CASE WHEN risk_category = 'Medium' THEN 1 ELSE 0 END) AS medium_risk_count,
    SUM(CASE WHEN risk_category = 'Low' THEN 1 ELSE 0 END) AS low_risk_count
    
FROM tableau_fraud_data
WHERE in_queue = 1
GROUP BY 
    queue_status,
    decision_priority,
    analyst_name,
    DATE(queue_created_date);

-- =============================================================================
-- Step 5: Create Feature-Level PSI View
-- =============================================================================

-- Example: Calculate PSI for Amount feature
DROP VIEW IF EXISTS tableau_feature_psi;

CREATE VIEW tableau_feature_psi AS
WITH baseline_amount AS (
    SELECT 
        CASE 
            WHEN amount < 50 THEN '0-50'
            WHEN amount < 100 THEN '50-100'
            WHEN amount < 500 THEN '100-500'
            WHEN amount < 1000 THEN '500-1000'
            ELSE '1000+'
        END AS amount_bin,
        COUNT(*) * 1.0 / SUM(COUNT(*)) OVER () AS expected_pct
    FROM transactions
    WHERE transaction_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
      AND transaction_date < CURDATE()
    GROUP BY 
        CASE 
            WHEN amount < 50 THEN '0-50'
            WHEN amount < 100 THEN '50-100'
            WHEN amount < 500 THEN '100-500'
            WHEN amount < 1000 THEN '500-1000'
            ELSE '1000+'
        END
),
current_amount AS (
    SELECT 
        CASE 
            WHEN amount < 50 THEN '0-50'
            WHEN amount < 100 THEN '50-100'
            WHEN amount < 500 THEN '100-500'
            WHEN amount < 1000 THEN '500-1000'
            ELSE '1000+'
        END AS amount_bin,
        COUNT(*) * 1.0 / SUM(COUNT(*)) OVER () AS actual_pct
    FROM transactions
    WHERE transaction_date >= CURDATE()
    GROUP BY 
        CASE 
            WHEN amount < 50 THEN '0-50'
            WHEN amount < 100 THEN '50-100'
            WHEN amount < 500 THEN '100-500'
            WHEN amount < 1000 THEN '500-1000'
            ELSE '1000+'
        END
)
SELECT 
    'Amount' AS feature_name,
    COALESCE(b.amount_bin, c.amount_bin) AS bin_value,
    COALESCE(b.expected_pct, 0.0001) AS expected_pct,
    COALESCE(c.actual_pct, 0.0001) AS actual_pct,
    CASE 
        WHEN COALESCE(b.expected_pct, 0) = 0 OR COALESCE(c.actual_pct, 0) = 0 THEN 0
        ELSE (COALESCE(c.actual_pct, 0) - COALESCE(b.expected_pct, 0)) * 
             LN(COALESCE(c.actual_pct, 0) / NULLIF(COALESCE(b.expected_pct, 0), 0))
    END AS psi_component,
    CURDATE() AS psi_date
FROM baseline_amount b
LEFT JOIN current_amount c ON b.amount_bin = c.amount_bin
UNION
SELECT 
    'Amount' AS feature_name,
    COALESCE(b.amount_bin, c.amount_bin) AS bin_value,
    COALESCE(b.expected_pct, 0.0001) AS expected_pct,
    COALESCE(c.actual_pct, 0.0001) AS actual_pct,
    CASE 
        WHEN COALESCE(b.expected_pct, 0) = 0 OR COALESCE(c.actual_pct, 0) = 0 THEN 0
        ELSE (COALESCE(c.actual_pct, 0) - COALESCE(b.expected_pct, 0)) * 
             LN(COALESCE(c.actual_pct, 0) / NULLIF(COALESCE(b.expected_pct, 0), 0))
    END AS psi_component,
    CURDATE() AS psi_date
FROM baseline_amount b
RIGHT JOIN current_amount c ON b.amount_bin = c.amount_bin
WHERE b.amount_bin IS NULL;

-- Aggregate feature PSI scores
DROP VIEW IF EXISTS tableau_feature_psi_scores;

CREATE VIEW tableau_feature_psi_scores AS
SELECT 
    feature_name,
    psi_date,
    SUM(psi_component) AS feature_psi_score,
    CASE 
        WHEN SUM(psi_component) < 0.10 THEN 'Stable'
        WHEN SUM(psi_component) < 0.25 THEN 'Minor Drift'
        ELSE 'Major Drift'
    END AS drift_status
FROM tableau_feature_psi
GROUP BY feature_name, psi_date;

-- =============================================================================
-- Step 6: Usage Instructions
-- =============================================================================

-- After running these scripts, you'll have the following views:
-- 1. tableau_fraud_data - Main data view for Tableau
-- 2. tableau_summary_stats - Daily summary statistics
-- 3. tableau_psi_data - PSI component data
-- 4. tableau_psi_score - Overall PSI score
-- 5. tableau_queue_overview - Queue metrics for ops team
-- 6. tableau_feature_psi - Feature-level PSI
-- 7. tableau_feature_psi_scores - Aggregated feature PSI

-- In Tableau, connect to your MySQL database and use these views:
-- - Main dashboard: Use tableau_fraud_data
-- - Summary metrics: Use tableau_summary_stats
-- - Drift monitoring: Use tableau_psi_score and tableau_feature_psi_scores
-- - Queue overview: Use tableau_queue_overview





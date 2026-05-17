/*         Cohort Retention Analysis
       Tool: PostgreSQL / DBeaver
Description: Cohort analysis tracking user retention over 6 months,
             comparing promo vs organic acquisition quality.
             Raw date fields require cleaning due to inconsistent
             formats and delimiters across both source tables. */

-- Step 1: Parse and standardise date components from users table
-- Removes time component, strips whitespace, replaces all delimiters with '-'
-- then splits into day, month, year parts for later reconstruction
WITH data_parted_u AS
(
        SELECT user_id,
               promo_signup_flag,
               split_part(regexp_replace(trim(split_part("signup_datetime", ' ', 1)), '\D', '-', 'g'), '-', 1) day_,
               split_part(regexp_replace(trim(split_part("signup_datetime", ' ', 1)), '\D', '-', 'g'), '-', 2) month_,
               split_part(regexp_replace(trim(split_part("signup_datetime", ' ', 1)), '\D', '-', 'g'), '-', 3) year_
        FROM cohort_users_raw
),

-- Step 2: Apply the same date parsing logic to the events table
date_parted_e AS
(
        SELECT user_id,
               event_id,
               event_type,
               split_part(regexp_replace(trim(split_part("event_datetime", ' ', 1)), '\D', '-', 'g'), '-', 1) day_,
               split_part(regexp_replace(trim(split_part("event_datetime", ' ', 1)), '\D', '-', 'g'), '-', 2) month_,
               split_part(regexp_replace(trim(split_part("event_datetime", ' ', 1)), '\D', '-', 'g'), '-', 3) year_
        FROM cohort_events_raw
),

-- Step 3: Reconstruct clean dates in both tables
-- Handles 2-digit years (e.g. '25' → '2025') using CASE
-- Joins users and events on user_id to align signup and event dates
proper_date_u_e AS
(
        SELECT event_id,
               user_id,
               promo_signup_flag,
               event_type,
               to_date(concat(u.day_,   '-',
                              u.month_, '-',
                              CASE WHEN length(u.year_) = 2
                              THEN concat('20', u.year_)
                              ELSE u.year_
                              END), 'DD-MM-YYYY') signup_date,
               to_date(concat(e.day_,   '-',
                              e.month_, '-',
                              CASE WHEN length(e.year_) = 2
                              THEN concat('20', e.year_)
                              ELSE e.year_
                              END), 'DD-MM-YYYY') event_date
        FROM data_parted_u u
        JOIN date_parted_e e USING (user_id)
),

-- Step 4: Build cohort structure
-- cohort_month = month of user registration
-- month_offset = months since registration (0 = registration month)
-- Filters out: test events, NULL dates, NULL event types,
--              and activity outside Jan–Jun 2025 observation window
cohort_table AS
(
        SELECT user_id,
               promo_signup_flag,
               date_trunc('MONTH', signup_date)::date cohort_month,
               EXTRACT(MONTH FROM AGE(date_trunc('MONTH', event_date), date_trunc('MONTH', signup_date))) AS month_offset
        FROM proper_date_u_e
        WHERE event_type <> 'test_event' AND
              signup_date IS NOT NULL    AND
              event_date  IS NOT NULL    AND
              event_type  IS NOT NULL    AND
              event_date BETWEEN '2025-01-01' AND '2025-06-30'
)

-- Final output: unique active users per cohort month and offset,
-- segmented by promo vs organic acquisition
SELECT promo_signup_flag,
       cohort_month,
       month_offset,
       count(DISTINCT user_id) AS users_total
FROM cohort_table
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3;
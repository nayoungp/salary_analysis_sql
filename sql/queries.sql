-- 1. Which departments have the highest and lowest total salary costs?
SELECT
    d.department_name,
    SUM(e.salary) AS total_salary
FROM employees e
JOIN company_departments d ON e.department_id = d.id
GROUP BY d.department_name
ORDER BY total_salary DESC;


-- 2. What is the average salary per department?
SELECT
    d.department_name,
    ROUND(AVG(e.salary), 2) AS average_salary
FROM employees e
JOIN company_departments d ON e.department_id = d.id
GROUP BY d.department_name
ORDER BY average_salary DESC;


-- 3. What is the average salary per region?
SELECT
    r.region_name,
    c.country_name,
    ROUND(AVG(e.salary), 2) AS average_salary
FROM employees e
JOIN company_regions r ON e.region_id = r.id
JOIN company_regions c ON e.region_id = c.id
GROUP BY r.region_name, c.country_name
ORDER BY average_salary DESC;


-- 4. Which departments have the most employees?
SELECT
    d.department_name,
    COUNT(e.id) AS employee_count
FROM employees e
JOIN company_departments d ON e.department_id = d.id
GROUP BY d.department_name
ORDER BY employee_count DESC;


-- 5. Which regions spend the most on total salary?
SELECT
    r.region_name,
    SUM(e.salary) AS total_salary
FROM employees e
JOIN company_regions r ON e.region_id = r.id
GROUP BY r.region_name
ORDER BY total_salary DESC;


-- 6. Which job titles have the highest average salaries?
SELECT
    job_title,
    ROUND(AVG(salary), 2) AS avg_salary,
    COUNT(*) AS employee_count
FROM employees
GROUP BY job_title
ORDER BY avg_salary DESC;


-- 7. Salary distribution by job title across regions
SELECT
    job_title,
    r.region_name,
    ROUND(AVG(e.salary), 2) AS avg_salary,
    MIN(e.salary) AS min_salary,
    MAX(e.salary) AS max_salary,
    COUNT(*) AS employee_count
FROM employees e
JOIN company_regions r ON e.region_id = r.id
GROUP BY job_title, r.region_name
ORDER BY job_title, avg_salary DESC;


-- 8. Total salary by division
SELECT
    d.division_name,
    ROUND(SUM(e.salary), 2) AS total_salary
FROM employees e
JOIN company_departments d ON e.department_id = d.id
GROUP BY d.division_name
ORDER BY total_salary DESC;


-- 9. Employees grouped by region and department
SELECT
    r.region_name,
    d.department_name,
    COUNT(e.id) AS employee_count,
    ROUND(AVG(e.salary), 2) AS avg_salary
FROM employees e
JOIN company_regions r ON e.region_id = r.id
JOIN company_departments d ON e.department_id = d.id
GROUP BY r.region_name, d.department_name
ORDER BY employee_count DESC;


-- 10. Find job titles with wide salary variance (standard deviation)
SELECT
    job_title,
    ROUND(AVG(salary), 2) AS avg_salary,
    ROUND(STDDEV(salary), 2) AS salary_stddev,
    COUNT(*) AS employee_count
FROM employees
GROUP BY job_title
HAVING COUNT(*) > 2
ORDER BY salary_stddev DESC;

--11. 부서별 급여 순위와 백분위수
SELECT 
    e.job_title,
    e.salary,
    d.department_name,
    ROW_NUMBER() OVER (PARTITION BY d.department_name ORDER BY e.salary DESC) as salary_rank,
    PERCENT_RANK() OVER (PARTITION BY d.department_name ORDER BY e.salary) as salary_percentile,
    AVG(e.salary) OVER (PARTITION BY d.department_name) as dept_avg_salary,
    e.salary - AVG(e.salary) OVER (PARTITION BY d.department_name) as salary_diff_from_avg
FROM employees e
JOIN company_departments d ON e.department_id = d.id;

--12. 급여 구간별 직원 분포 분석
WITH salary_brackets AS (
    SELECT 
    
        CASE 
            WHEN salary < 50000 THEN 'Low (< 50K)'
            WHEN salary < 80000 THEN 'Medium (50K-80K)'
            WHEN salary < 100000 THEN 'High (80K-100K)'
            ELSE 'Premium (100K+)'
        END as salary_bracket,
        COUNT(*) as employee_count
    FROM employees
    GROUP BY 1
),
total_employees AS (
    SELECT COUNT(*) as total FROM employees
)
SELECT 
    sb.salary_bracket,
    sb.employee_count,
    ROUND(sb.employee_count * 100.0 / te.total, 2) as percentage
FROM salary_brackets sb
CROSS JOIN total_employees te
ORDER BY sb.employee_count DESC;

--13. Employee Salary by Tenure Bracket
WITH RECURSIVE tenure_brackets AS (
    SELECT 
        0 as years_min,
        2 as years_max,
        'New Hire (0-2 years)' as tenure_bracket,
        1 as bracket_level
    
    UNION ALL
    
    SELECT 
        years_max,
        years_max + 3,
        CASE 
            WHEN years_max = 2 THEN 'Junior (2-5 years)'
            WHEN years_max = 5 THEN 'Mid-level (5-8 years)'
            WHEN years_max = 8 THEN 'Senior (8-11 years)'
            WHEN years_max = 11 THEN 'Expert (11+ years)'
        END,
        bracket_level + 1
    FROM tenure_brackets
    WHERE bracket_level < 5
),
employee_tenure AS (
    SELECT 
        e.name,
        e.salary,
        e.job_title,
        EXTRACT(YEAR FROM AGE(CURRENT_DATE, e.start_date)) as years_of_service,
        tb.tenure_bracket,
        tb.bracket_level
    FROM employees e
    JOIN tenure_brackets tb ON 
        EXTRACT(YEAR FROM AGE(CURRENT_DATE, e.start_date)) >= tb.years_min 
        AND EXTRACT(YEAR FROM AGE(CURRENT_DATE, e.start_date)) < tb.years_max
)
SELECT 
    tenure_bracket,
    bracket_level,
    COUNT(*) as employee_count,
    ROUND(AVG(salary), 0) as avg_salary,
    ROUND(AVG(years_of_service), 1) as avg_years_service,
    MIN(years_of_service) as min_tenure,
    MAX(years_of_service) as max_tenure
FROM employee_tenure
GROUP BY tenure_bracket, bracket_level
ORDER BY bracket_level;

--14. Departmental Salary Distribution Statistics
SELECT 
    d.department_name,
    COUNT(*) as employee_count,
    ROUND(AVG(e.salary)::numeric, 0) as avg_salary,
    ROUND(STDDEV(e.salary)::numeric, 0) as salary_stddev,
    MIN(e.salary) as min_salary,
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY e.salary)::numeric, 0) as q1,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY e.salary)::numeric, 0) as median,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY e.salary)::numeric, 0) as q3,
    MAX(e.salary) as max_salary,
    ROUND((STDDEV(e.salary) / AVG(e.salary) * 100)::numeric, 2) as coefficient_of_variation
FROM employees e
JOIN company_departments d ON e.department_id = d.id
GROUP BY d.department_name
HAVING COUNT(*) >= 5
ORDER BY coefficient_of_variation DESC;


--15. Top 10% Earners by Department
SELECT 
    e.job_title,
    e.salary,
    d.department_name,
    r.region_name
FROM employees e
JOIN company_departments d ON e.department_id = d.id
JOIN company_regions r ON e.region_id = r.id
WHERE e.salary >= (
    SELECT PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY e2.salary)
    FROM employees e2
    WHERE e2.department_id = e.department_id
);

--16. 평균보다 더 많이 받는 직원만 필터링
WITH dept_avg_salary AS (
    SELECT department_id, AVG(salary) AS avg_salary
    FROM employees
    GROUP BY department_id
)
SELECT e.last_name, e.salary, d.avg_salary
FROM employees e
JOIN dept_avg_salary d ON e.department_id = d.department_id
WHERE e.salary > d.avg_salary;


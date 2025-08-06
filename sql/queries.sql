-- 1. Departments that have the highest & lowest total salary cost
SELECT
    d.department_name,
    SUM(e.salary) AS total_salary
FROM employees e
JOIN company_departments d ON e.department_id = d.id
GROUP BY d.department_name
ORDER BY total_salary DESC;


-- 2. Average salary per department
SELECT
    d.department_name,
    ROUND(AVG(e.salary), 2) AS average_salary
FROM employees e
JOIN company_departments d ON e.department_id = d.id
GROUP BY d.department_name
ORDER BY average_salary DESC;


-- 3. Average salary per region
SELECT
    r.region_name,
    c.country_name,
    ROUND(AVG(e.salary), 2) AS average_salary
FROM employees e
JOIN company_regions r ON e.region_id = r.id
JOIN company_regions c ON e.region_id = c.id
GROUP BY r.region_name, c.country_name
ORDER BY average_salary DESC;


-- 4. Departments that have the most employees
SELECT
    d.department_name,
    COUNT(e.id) AS employee_count
FROM employees e
JOIN company_departments d ON e.department_id = d.id
GROUP BY d.department_name
ORDER BY employee_count DESC;


-- 5. Regions where spend the most on total salary
SELECT
    r.region_name,
    SUM(e.salary) AS total_salary
FROM employees e
JOIN company_regions r ON e.region_id = r.id
GROUP BY r.region_name
ORDER BY total_salary DESC;


-- 6. job titles that have the highest average salaries
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

--11. Salary Ranking & Percentile by Department
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

--12. Salary bracket distribution
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
    GROUP BY salary_brackets
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


--13. Departmental Salary Distribution Statistics
SELECT 
    d.department_name,
    COUNT(*) as employee_count,
    ROUND(AVG(e.salary), 0) as avg_salary,
    ROUND(STDDEV(e.salary), 0) as salary_stddev,
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


--14. Top 10% Earners by Department
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

--15. employees who have higher salaries than avg_salary per department
WITH dept_avg_salary AS (
    SELECT department_id, AVG(salary) AS avg_salary
    FROM employees
    GROUP BY department_id
)
SELECT e.last_name, e.salary, d.avg_salary
FROM employees e
JOIN dept_avg_salary d ON e.department_id = d.department_id
WHERE e.salary > d.avg_salary;


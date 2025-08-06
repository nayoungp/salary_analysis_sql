# salary_analysis_sql
## Workforce Financial Analysis Across Departments and Regions
![Banner](./images/banner.jpg)

##### This project performs a workforce financial analysis using a mock SQL database that simulates employee salary and departmental data. The goal is to derive actionable insights from a financial analyst's perspective, identifying salary trends, cost optimizations, and organizational imbalances.

### Project Objective
Perform an in-depth financial analysis of employee salary distributions across departments and regions to uncover:
*   Salary optimization opportunities
*   Underperforming or overstaffed departments
*   Regional salary disparities
*   Executive and operational cost patterns

### Tables Overview:
- `employees`: Employee records including salary, department, job title, region, and start date.
- `company_departments`: Department metadata and divisions.
- `company_regions`: Region and country data.

### Methodology & Queries Used
All analysis was done using SQL (PostgreSQL syntax). Example queries include:
```
```sql
-- Total salary by department
SELECT d.department_name, SUM(e.salary) AS total_salary
FROM employees e
JOIN company_departments d ON e.department_id = d.id
GROUP BY d.department_name
ORDER BY total_salary DESC;
```


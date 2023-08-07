-- ¬ыберем данные, которые мы собираемс€ использовать

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1,2

-- ¬еро€тность летальных случаев от заражени€ ковидом в зависимости от страны
SELECT location, ROUND((MAX(total_deaths)/MAX(total_cases))*100, 2) AS death_per
FROM CovidDeaths
GROUP BY location
ORDER BY 2 DESC

-- ѕосчитаем отношение зараженных к общему количеству населени€ в каждой стране
SELECT location, ROUND((MAX(total_cases)/MAX(population))*100, 2) AS cases_per
FROM CovidDeaths
GROUP BY location
ORDER BY 2 DESC

--  оличество смертей от ковида в зависимости от страны
SELECT location, MAX(CAST(total_deaths AS int)) 
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, continent
ORDER BY 2 DESC

--  оличество смертей от ковида в зависимости от континента 
SELECT continent, MAX(CAST(total_deaths AS int)) 
FROM CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY 2 DESC

--  оличество смертей от ковида относительно количества населени€ в зависимости от континента
SELECT continent, MAX(CAST(total_deaths AS int)) 
FROM CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY 2 DESC

-- ћировые значени€ 
SELECT 
date, 
SUM(new_cases) AS total_cases,
SUM(CAST(new_deaths AS int)) AS total_deaths,
(SUM(CAST(new_deaths AS int))/SUM(new_cases))*100 AS death_per
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1

-- —оотношение вакцинированных и общего количества населени€ по странам

SELECT dea.location, 
MAX(CAST(vac.total_vaccinations AS int)) AS total_vaccinations, 
MAX(dea.population) AS population,
ROUND((MAX(CAST(vac.total_vaccinations AS int))/MAX(dea.population))*100, 2) AS vac_per
FROM CovidDeaths dea
JOIN 
CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
GROUP BY dea.location
ORDER BY 4 DESC

-- ƒругой вариант с оконной функцией

SELECT dea.location, 
dea.date,
dea.population AS population,
CAST(vac.new_vaccinations AS int) AS new_vaccinations, 
SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeople_vac
FROM CovidDeaths dea
JOIN 
CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 1,2

-- »спользование CTE

WITH pop_vac (location, date, population, new_vaccinations, rolling_people_vac) AS 

(SELECT dea.location, 
dea.date,
dea.population AS population,
CAST(vac.new_vaccinations AS int) AS new_vaccinations, 
SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vac
FROM CovidDeaths dea
JOIN 
CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL)

SELECT *, (rolling_people_vac/population)*100 AS people_vac_per FROM pop_vac
ORDER BY 1,2

-- »спользование TEMP TABLE

DROP TABLE IF EXISTS #popvac
CREATE TABLE #popvac (
location nvarchar(255),
date datetime,
population float,
new_vaccinations int,
rolling_people_vac int)

INSERT INTO #popvac
SELECT dea.location, 
dea.date,
dea.population AS population,
CAST(vac.new_vaccinations AS int) AS new_vaccinations, 
SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vac
FROM CovidDeaths dea
JOIN 
CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (rolling_people_vac/population)*100 AS people_vac_per FROM #popvac



SELECT *
FROM PortiProj..CovidDeaths
ORDER  by 3,4

SELECT *
FROM PortiProj..CovidVaccinations
ORDER  by 3,4

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortiProj..CovidDeaths
ORDER BY 1,2

-- total cases vs total deaths
-- shows likelihood of dying if you contract covid in your country
SELECT Location, date, total_cases, total_deaths, (total_cases/total_deaths)*100 AS DeathPercentage
FROM PortiProj..CovidDeaths
ORDER BY 1,2


-- total cases vs populations
-- shows what percentage of population got covid
SELECT location, date, population, total_cases, (total_cases/population)*100 AS percentagePopInfection
FROM PortiProj..CovidDeaths
ORDER BY 1,2

-- countries with highest infection rate compared to population
SELECT Location, Population, MAX(total_cases) AS HighestInfectCount, MAX((total_cases/population))*100 AS percentagePopInfection
FROM PortiProj..CovidDeaths
GROUP BY population, location
ORDER BY percentagePopInfection DESC


-- countries with highest death rate compared to population
SELECT Location, MAX(cast(total_deaths AS INT)) AS TotalDeathCount
FROM PortiProj..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- BREAK DOWN BY CONTINENT

-- Showing continents with highest death count per population
SELECT continent, MAX(cast(total_deaths AS INT)) AS TotalDeathCount
FROM PortiProj..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC


-- GLOBAL NUMBERS
-- death percentage per day
SELECT date, SUM(new_cases) AS total_cases,
SUM(CAST(new_deaths AS INT)) AS total_deaths,
(SUM(CAST(new_deaths AS INT))/SUM(new_cases))*100 AS DeathPercentage
FROM PortiProj..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

-- death percentage total
SELECT SUM(new_cases) AS total_cases,
SUM(CAST(new_deaths AS INT)) AS total_deaths,
(SUM(CAST(new_deaths AS INT))/SUM(new_cases))*100 AS DeathPercentage
FROM PortiProj..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- total population vs vaccinations with cte
WITH popVsVac (Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(INT, vac.new_vaccinations))
OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rollingPeopleVaccinated
FROM PortiProj..CovidDeaths dea
JOIN PortiProj..CovidVaccinations vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM popVsVac

-- total population vs vaccinations with TempTable
DROP TABLE IF EXISTS #PercentePopVAccinated
CREATE TABLE #PercentePopVAccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rollingPeopleVaccinated numeric
)

INSERT INTO #PercentePopVAccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(INT, vac.new_vaccinations))
OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rollingPeopleVaccinated
FROM PortiProj..CovidDeaths dea
JOIN PortiProj..CovidVaccinations vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentePopVAccinated

-- View to store data for later visualization
CREATE VIEW PercentePopVAccinated AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(INT, vac.new_vaccinations))
OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rollingPeopleVaccinated
FROM PortiProj..CovidDeaths dea
JOIN PortiProj..CovidVaccinations vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL


SELECT * FROM PercentePopVAccinated
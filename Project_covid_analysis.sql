SELECT location, date, total_cases, new_cases, total_deaths, population
FROM coviddeathstest
ORDER BY 1,2;

--looking at Total cases versus Total deaths

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM coviddeathstest
WHERE location like 'United States'
ORDER BY 1,2;

--looking at Total cases versus Population
--Shows what percentage of population got Covid

SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
FROM coviddeathstest
WHERE location like 'Brazil'
ORDER BY 1,2;

--Looking at Countries with Highest Infection Rate Compared to Population

SELECT location, population, MAX (total_cases) as HighestInfectionCount, MAX ((total_cases/population)*100) AS TotalPercentagePopulationInfected
FROM coviddeathstest
--WHERE location like 'Brazil'
GROUP BY location, population
ORDER BY 4 DESC;

--Showing Countries with Highest Death Count per Population

SELECT location, MAX (total_deaths) AS TotalDeathCount
FROM coviddeathstest
WHERE continent IS NULL
--WHERE location like 'Brazil'
GROUP BY location
ORDER BY TotalDeathCount DESC;

--Global Numbers

SELECT date, SUM (new_cases) AS SUM_new_cases, SUM (cast(new_deaths AS REAL)) AS SUM_new_deaths, SUM (cast(new_deaths AS REAL))/SUM (new_cases)*100 AS DeathPercentage
FROM coviddeathstest
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2;

SELECT SUM (new_cases) AS SUM_new_cases, SUM (cast(new_deaths AS REAL)) AS SUM_new_deaths, SUM (cast(new_deaths AS REAL))/SUM (new_cases)*100 AS DeathPercentage
FROM coviddeathstest
WHERE continent IS NOT NULL
ORDER BY 1,2;

--Joining the Tables

SELECT * FROM coviddeathstest dea
JOIN covidvaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date;
	
--Looking at Total Population vs Vaccination

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST (vac.new_vaccinations AS REAL)) OVER (PARTITION BY dea.location ORDER BY dea.location,
											  dea.date) AS RollingPeopleVaccinated
FROM coviddeathstest dea
JOIN covidvaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

--with CTE

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST (vac.new_vaccinations AS REAL)) OVER (PARTITION BY dea.location ORDER BY dea.location,
											  dea.date) AS RollingPeopleVaccinated
FROM coviddeathstest dea
JOIN covidvaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/Population)*100 
FROM PopvsVac;

--Creating new table
ALTER TABLE coviddeathstest
	ALTER COLUMN new_vaccinations TYPE REAL USING new_vaccinations::real;
	
DROP TABLE IF exists PercentPopulationVaccinated;
CREATE TABLE PercentPopulationVaccinated
(
	continent VARCHAR(255),
	location VARCHAR(255),
	date VARCHAR(255),
	population REAL,
	new_vaccinations REAL,
	rollingpeoplevaccinated REAL
);
INSERT INTO PercentPopulationVaccinated
(
SELECT dea.continent, dea.location, dea.date, dea.population, CAST (vac.new_vaccinations AS REAL),
SUM(CAST (vac.new_vaccinations AS REAL)) OVER (PARTITION BY dea.location ORDER BY dea.location,
											  dea.date) AS RollingPeopleVaccinated
FROM coviddeathstest dea
JOIN covidvaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
);
SELECT *, (RollingPeopleVaccinated/Population)*100 
FROM PercentPopulationVaccinated;

--Creating View for Store data

CREATE VIEW PercentagePopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST (vac.new_vaccinations AS REAL)) OVER (PARTITION BY dea.location ORDER BY dea.location,
											  dea.date) AS RollingPeopleVaccinated
FROM coviddeathstest dea
JOIN covidvaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT * FROM percentagepopulationvaccinated
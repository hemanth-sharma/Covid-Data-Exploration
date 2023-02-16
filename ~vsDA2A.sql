/*
Covid 19 Data Exploration 

*/

Select *
From CovidDatabase..covidDeaths_data$
--Where continent is not NULL
Order by 3, 4


-- Select the data

Select location, date, total_cases, new_cases, total_deaths, population
From CovidDatabase..covidDeaths_data$
Where continent is not NULL
Order by 1, 2


-- Total Cases vs Total Deaths 
-- Shows likelihood of dying if you contract covid in your country

Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From CovidDatabase..covidDeaths_data$
Where location = 'India' and continent is not NULL
Order by 1, 2


-- Total Cases vs Population 
-- Shows what percentage of the population is infected with Covid-19.

Select location, date, population, total_cases, (total_cases/population) * 100 AS CovidPercentageByPopulation
From CovidDatabase..covidDeaths_data$
--Where location = 'India' and continent is not NULL
Order by 1, 2


-- Countries with Highest Infection Rate compared to population 

Select location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population)*100) AS PercentPopulationInfected
From CovidDatabase..covidDeaths_data$
Group by location, Population
Order by PercentPopulationInfected DESC


-- Countries with Highest Death Count per population

Select location, population, MAX(cast(total_deaths as int)) AS TotalDeathCount
From CovidDatabase..covidDeaths_data$
Where continent is not NULL
Group by location, population
Order by 3 desc



-- Breaking things down by Continent
-- Showing continents with the highest death count per population

With ContinentsDeath_CTE (Continent, Location, TotalDeathByCountries)
AS(
	Select continent, location, MAX(cast(total_deaths as int)) 
	From CovidDatabase..covidDeaths_data$
	Where continent is not NULL
	Group by continent, location
)
Select Continent, Sum(TotalDeathByCountries) as TotalDeathByContinent
From ContinentsDeath_CTE
Group by Continent
Order by TotalDeathByContinent Desc


-- Showing Continent and Country with Maximum Death 

With MaxCountryCTE (Continent, Location, TotalDeathCount) AS (
    Select Continent, location, MAX(cast(total_deaths as int)) AS TotalDeathCount
    From CovidDatabase..covidDeaths_data$ t
    Where continent IS NOT NULL
    Group by continent, location
)
Select cte.Continent, cte.Location AS [Country With Higest Death], cte.TotalDeathCount as [Highest Death Count]
From MaxCountryCTE cte
Where cte.TotalDeathCount = (
    Select MAX(TotalDeathCount) 
    From MaxCountryCTE 
    Where Continent = cte.Continent
)
Order by 3 DESC



-- Total Global Numbers
Select MAX(total_cases), MAX(cast(total_deaths as int))
From CovidDatabase..covidDeaths_data$

-- Shows percentage of death over the years
Select date, SUM(new_cases) as TotalCases, 
SUM(cast(new_deaths as int)) as TotalDeath, 
(SUM(cast(new_deaths as int))/SUM(new_cases))*100 
AS TotalDeathPercentage
From CovidDatabase..covidDeaths_data$
Where continent IS NOT NULL
Group by date
Order by 1, 2





-- Covid Vaccinations Table

Select * 
From CovidDatabase..covidVacination_data$

-- JOIN both table
Select * 
From CovidDatabase..covidDeaths_data$ AS dea
JOIN CovidDatabase..covidVacination_data$ AS vac
ON dea.location = vac.location AND dea.date = vac.date





-- Total Population vs Vaccination
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS  CumulativeVaccinations
From CovidDatabase..covidDeaths_data$ AS dea
JOIN CovidDatabase..covidVacination_data$ AS vac
	ON dea.location = vac.location AND dea.date = vac.date
Where dea.continent IS NOT NULL
Order by 2, 3


--- Using CTE to perform Calculation on Partition By in above query
WITH PopVsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS  CumulativeVaccinations
FROM CovidDatabase..covidDeaths_data$ AS dea
JOIN CovidDatabase..covidVacination_data$ AS vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3
)
SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercentageOfRollingPopulation
FROM PopVsVac



--- Using Temp Table to do the above query
DROP Table if exists #PercentagePopulationVaccinated
CREATE Table #PercentagePopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT into #PercentagePopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS  CumulativeVaccinations
FROM CovidDatabase..covidDeaths_data$ AS dea
JOIN CovidDatabase..covidVacination_data$ AS vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3

SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercentageOfRollingPopulation
FROM #PercentagePopulationVaccinated




-- Creating View for storing data for visualization 

CREATE VIEW PercentPopulationVaccinated_view AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS  CumulativeVaccinations
FROM CovidDatabase..covidDeaths_data$ AS dea
JOIN CovidDatabase..covidVacination_data$ AS vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3


SELECT *
FROM PercentPopulationVaccinated_view


/*
Covid19 Data Exploration

Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

-- Select all and order by
Select *
From covidproject..covid_deaths
order by 3,4


Select *
From covidproject..covid_vaccinations
order by 3,4


-- Select some of the data that we are going to be using
 Select Location, date, total_cases, new_cases, total_deaths, population
 From covidproject..covid_deaths
 order by 1,2

 -- Looking at Total Cases vs Total Deaths
 -- Displays likelihood of dying if you contract covid in your country. 
 Select 
	Location, 
	date, 
	total_cases, 
	total_deaths,
	CASE 
		WHEN total_cases = 0 THEN 0
		ELSE (total_deaths/total_cases)*100 
	END AS DeathPercentage
 From covidproject..covid_deaths
 order by 1,2

 -- Looking at Total Cases vs Population
 -- Displays percentage of population got covid
 Select Location, date, total_cases, population,(total_cases/population)*100 as CasePercentage
 From covidproject..covid_deaths
 order by 1,2

 -- Display countries with highest infection rate compared to population
 Select Location, Population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
 From covidproject..covid_deaths
 Group by Location, Population
 order by PercentPopulationInfected desc

  -- Display countries with Highest Death Count per population
 Select Location, MAX(CAST(Total_deaths as int)) as TotalDeathCount
 From covidproject..covid_deaths
 WHERE continent is not NULL
 Group by Location
 order by TotalDeathCount desc

 -- Display deaths by continents
 Select 
	date, 
	SUM(COALESCE(new_cases,0)) as total_cases, 
	SUM(COALEScE(cast(new_deaths as int),0)) as total_deaths, 
	CASE
		WHEN SUM(COALESCE(new_cases,0)) = 0 THEN 0
		ELSE (SUM(COALESCE(cast(new_deaths as int),0))/SUM(COALESCE(New_Cases,0)))*100 
	END as deathpercentage 
 From 
	covidproject..covid_deaths
 WHERE 
	continent is not NULL
 Group by 
	date
 order by 
	date


-- Join covid vaccination table to covid deaths table
Select *
From covidproject..covid_deaths dea
Join covidproject..covid_vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date

-- Total Population vs Vaccinations (new vaccinations per day)
-- Displays percentage of population that received at least one vaccination. 
Select 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.Location order by dea.location, dea.Date) as rolling_vaccinations
From covidproject..covid_deaths dea
Join covidproject..covid_vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3


-- Use CTE to perform calculation on Partition By in previous query
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, rolling_vaccinations)
as
(
Select 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.Location order by dea.location, dea.Date) as rolling_vaccinations
From covidproject..covid_deaths dea
Join covidproject..covid_vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
Select *, (rolling_vaccinations/Population)* 100 as rollingperc
From PopvsVac

-- Use Temp Table to perform Calculation on Partition By 
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime, 
Population numeric, 
New_vaccinations numeric, 
Rolling_vaccinations numeric
)

Insert into #PercentPopulationVaccinated
Select 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.Location order by dea.location, dea.Date) as rolling_vaccinations
From covidproject..covid_deaths dea
Join covidproject..covid_vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

Select *, (rolling_vaccinations/population)*100
From #PercentPopulationVaccinated


-- Creating View to store data for later visualizations
Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as rolling_vaccinations
--, (RollingPeopleVaccinated/population)*100
From covidproject..covid_deaths dea
Join covidproject..covid_vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
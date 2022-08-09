--Show data from coviddeaths table ordered by location and date
Select 
	Location, 
	date, 
	total_cases, 
	new_cases, 
	total_deaths, 
	population
FROM CovidData..CovidDeaths$
ORDER BY 1,2;

-- Total cases vs total deaths
-- Shows likelihood of dying if diagnosed with Covid as a rolling percentage in column
-- Filtered location to united states using 'like' and % wildcards for demonstration
Select 
	Location, 
	date, 
	total_cases, 
	total_deaths, 
	(total_deaths/total_cases)*100 as death_percentage
FROM CovidData..CovidDeaths$
WHERE Location like '%states%'
ORDER BY 1,2;

-- Total cases vs population
-- Percentage of population that has been diagnosed with Covid as a rolling percentage in column
-- Filtered location to united states using 'like' and % wildcards for demonstration
Select 
	Location, 
	date, 
	total_cases, 
	population, 
	(total_cases/population)*100 as percent_diagnosed
FROM CovidData..CovidDeaths$
WHERE Location like '%states%'
	AND continent is NOT NULL
ORDER BY 1,2;

-- Countries with highest infection rate
-- Get max total cases, grouped by location then maximum total cases / population to find peak infection rate
-- Since total cases can only go up, taking max of these columns will give most current results
Select 
	Location, 
	MAX(total_cases) as peak_infection_count, 
	population, 
	MAX((total_cases/population))*100 as Infection_rate
FROM CovidData..CovidDeaths$
WHERE continent is NOT NULL
GROUP BY Location, population
ORDER BY Infection_rate desc;

-- Countries with highest death count per population
-- Calculated by taking total death count divided by population
-- Total deaths column was loaded as a 'nvarchar(255)' so this was cast as int for calculation
Select 
	Location, 
	MAX(cast(total_deaths as int)) as peak_death_count, 
	population, 
	MAX((total_deaths/population))*100 as Death_rate
FROM CovidData..CovidDeaths$
WHERE continent is NOT NULL
GROUP BY Location, population
ORDER BY Death_rate desc;

-- Global numbers
-- New cases and new deaths columns give single cases per day, so summing them will give totals
-- As with above, some columns were loaded as nvarchar(255) and needed to be cast as int
Select 
	SUM(new_cases) as total_cases, 
	SUM(CAST(new_deaths as int)) as total_deaths, 
	SUM(CAST(new_deaths as int))/SUM(new_cases)*100 as percent_deaths_per_case
FROM CovidData..CovidDeaths$
WHERE continent is NOT NULL

-- Join tables to compare location and population from coviddeaths table with people fully vaccinated from covidvaccinations table
-- Calculate percent fully vaccinated with the columns above
-- Group by location and sort by percent fully vaccincated
Select 
	deaths.location, 
	MAX(CAST(vacc.people_fully_vaccinated as BIGINT)) AS people_fully_vaccinated, 
	MAX(deaths.population) as population, 
	MAX(CAST(vacc.people_fully_vaccinated as BIGINT))/MAX(deaths.population)*100 AS percent_fully_vaccinated
FROM CovidData..CovidVaccinations$ as vacc
JOIN CovidData..CovidDeaths$ as deaths
	ON deaths.location = vacc.location
		and deaths.date = vacc.date
WHERE deaths.continent is not null
GROUP BY deaths.location
ORDER BY percent_fully_vaccinated DESC;

-- Join tables to assign new_vaccinations column to respective row in coviddeaths table
-- Show a rolling total of vaccinations using new vaccinations column, partitioned by location
Select 
	deaths.continent, 
	deaths.location, 
	deaths.date, 
	deaths.population, 
	vacc.new_vaccinations, 
	SUM(CONVERT(BIGINT, vacc.new_vaccinations)) OVER (Partition by deaths.location ORDER BY deaths.location, deaths.date) as rolling_vaccine_count
FROM CovidData..CovidDeaths$ as deaths
JOIN CovidData..CovidVaccinations$ as vacc
	on deaths.location = vacc.location
		and deaths.date = vacc.date
WHERE deaths.continent is not null
ORDER BY 1,2,3;

-- Using CTE for above example as well
-- Calculating rolling percent vaccinated using new vaccinations total and population
-- This data is not very useful as total of new vaccinations should be above fully vaccinated total since many vaccine options are 2 doses
-- Used this to show rolling total and calculations more than to analyze the data 
With pop_vs_vac (continent, location, date, population, new_vaccinations, rolling_vaccine_count) as
(
Select 
	deaths.continent, 
	deaths.location, 
	deaths.date, 
	deaths.population, 
	vacc.new_vaccinations, 
	SUM(CONVERT(BIGINT, vacc.new_vaccinations)) OVER (Partition by deaths.location ORDER BY deaths.location, deaths.date) as rolling_vaccine_count
FROM CovidData..CovidDeaths$ as deaths
JOIN CovidData..CovidVaccinations$ as vacc
	on deaths.location = vacc.location
		and deaths.date = vacc.date
WHERE deaths.continent is not null
)
Select 
	*, 
	(rolling_vaccine_count/population)*100 AS rolling_total_per_population
FROM pop_vs_vac


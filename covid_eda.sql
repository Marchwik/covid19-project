/*
First we need to create the tables we are going to be using. 
I am using one large excel file that I have split into two seperate files to make it easier to work on it. Excel file I am using is from the website https://ourworldindata.org/covid-deaths. 

Instead of using the most updated databse - records are updated daily - I am using a file with the lastest record of 22/02/2022 to make it more managable. 
Database found on Kaggle: https://www.kaggle.com/datasets/taranvee/covid-19-dataset-till-2222022/

I have divided the table into two smaller tables to make it easier to manipulate and control the data. 
covid_data is now covid_deaths and covid_vaccinations.
All three datafiles are uploaded to the project repository.
*/

CREATE DATABASE covid;

USE covid;

DROP TABLE IF EXISTS covid_deaths; 
CREATE TABLE covid_deaths (
	record_number int AUTO_INCREMENT NOT NULL,
	location varchar(32),
	iso_code varchar(8),
	continent varchar(13),
	date datetime,
	population bigint,
	total_cases integer,
	new_cases integer,
	new_cases_smoothed numeric(11,3),
	total_deaths integer,
	new_deaths integer,
	new_deaths_smoothed numeric(9,3),
	total_cases_per_million numeric(10,3),
	new_cases_per_million numeric(10,3),
	new_cases_smoothed_per_million numeric(9,3),
	total_deaths_per_million numeric(8,3),
	new_deaths_per_million numeric(7,3),
	new_deaths_smoothed_per_million numeric(7,3),
	reproduction_rate numeric(5,2),
	icu_patients integer,
	icu_patients_per_million numeric(7,3),
	hosp_patients integer,
	hosp_patients_per_million numeric(8,3),
	weekly_icu_admissions integer,
	weekly_icu_admissions_per_million numeric(7,3),
	weekly_hosp_admissions integer,
	weekly_hosp_admissions_per_million numeric(7,3),
	primary key(record_number)
);
 
DROP TABLE IF EXISTS covid_vaccinations; 
CREATE TABLE covid_vaccinations (
	record_number int AUTO_INCREMENT NOT NULL,
	location varchar(32),
	iso_code varchar(8),
	continent varchar(13),
	date datetime,
	new_tests integer,
	total_tests integer,
	total_tests_per_thousand numeric(9,3),
	new_tests_per_thousand numeric(7,3),
	new_tests_smoothed integer,
	new_tests_smoothed_per_thousand numeric(8,3),
	positive_rate numeric(6,4),
	tests_per_case numeric(8,1),
	tests_units varchar(15),
	total_vaccinations bigint,
	people_vaccinated bigint,
	people_fully_vaccinated bigint,
	total_boosters integer,
	new_vaccinations integer,
	new_vaccinations_smoothed integer,
	total_vaccinations_per_hundred numeric(6,2),
	people_vaccinated_per_hundred numeric(6,2),
	people_fully_vaccinated_per_hundred numeric(6,2),
	total_boosters_per_hundred numeric(5,2),
	new_vaccinations_smoothed_per_million integer,
	new_people_vaccinated_smoothed integer,
	new_people_vaccinated_smoothed_per_hundred numeric(6,3),
	stringency_index numeric(6,2),
	population_density numeric(9,3),
	median_age numeric(4,1),
	aged_65_older numeric(6,3),
	aged_70_older numeric(6,3),
	gdp_per_capita numeric(10,3),
	extreme_poverty numeric(4,1),
	cardiovasc_death_rate numeric(7,3),
	diabetes_prevalence numeric(5,2),
	female_smokers numeric(6,3),
	male_smokers numeric(6,3),
	handwashing_facilities numeric(7,3),
	hospital_beds_per_thousand numeric(6,3),
	life_expectancy numeric(5,2),
	human_development_index numeric(5,3),
	excess_mortality_cumulative_absolute numeric(9,1),
	excess_mortality_cumulative numeric(6,2),
	excess_mortality numeric(6,2),
	excess_mortality_cumulative_per_million numeric(15,9),
	primary key(record_number)
);

-- select the basic data we will be working with 

SELECT 
    location,
    date,
    total_cases,
    new_cases,
    total_deaths,
    population
FROM
    covid_deaths
ORDER BY 1 , 2;

-- we can see the date column includes time as '00:00:00' which makes it less readable. We will update its format from DATETIME to DATE.

ALTER TABLE covid_deaths
MODIFY date DATE;

-- looking at total cases v total deaths in each country and comparing the death percentage for each country

SELECT 
    location,
    MAX(total_cases) AS total_cases,
    MAX(total_deaths) AS total_deaths,
    CONCAT(ROUND(((MAX(total_deaths) / MAX(total_cases)) * 100),2),'%') AS death_percentage
FROM
    covid_deaths
WHERE
	continent IS NOT NULL
GROUP BY location
ORDER BY 4 DESC;

-- let's look at United Kingdom and compare UK to other Europeans countries
-- we will use the row number over window function to rank the data 
SELECT 
    location,
    MAX(total_cases) AS total_cases,
    MAX(total_deaths) AS total_deaths,
    CONCAT(ROUND(((MAX(total_deaths) / MAX(total_cases)) * 100),2),'%') AS death_percentage,
    ROW_NUMBER() OVER(ORDER BY CONCAT(ROUND(((MAX(total_deaths) / MAX(total_cases)) * 100),2),'%') DESC) AS ranked_data
FROM
    covid_deaths
WHERE continent = 'Europe'
GROUP BY location
ORDER BY 4 DESC;

-- UK was just in the middle, ranking as 21st country in Europe with most deaths per case. We will use this later in the EDA and in the Tableau visualisation

-- Now we'll check the total cases v population. It will show us what percentage of the country's population got Covid.

SELECT 
    location,
    population,
    MAX(total_cases) AS total_cases,
    ROUND((MAX(total_cases)/population) * 100, 2) AS infected_population_percentage,
    ROW_NUMBER() OVER(ORDER BY ROUND((MAX(total_cases)/population) * 100, 2) DESC) AS ranked_data
FROM
    covid_deaths
GROUP BY location, population
ORDER BY 5;

-- Countries with the highest death count per population

SELECT 
    location,
    MAX(total_deaths) AS total_deaths,
    population,
    ROUND(((MAX(total_deaths) / population) * 100), 2) AS death_percentage_per_population
FROM
    covid_deaths
WHERE
    continent IS NOT NULL
GROUP BY location , population
ORDER BY 4 DESC;

-- What day we had most new cases diagnosed in UK?

SELECT 
    location, date, new_cases
FROM
    covid_deaths
WHERE
    location = 'United Kingdom'
ORDER BY new_cases DESC
LIMIT 1;

-- What day we had most new cases diagnosed in each country in the world? We will use ROW_NUMBER OVER PARTITION function to rank each country

SELECT 
	location, 
    date, 
    new_cases, 
    ROW_NUMBER() OVER(ORDER BY new_cases DESC) as rank_data
FROM (
    SELECT location, date, new_cases, ROW_NUMBER() OVER (PARTITION BY location ORDER BY new_cases DESC) AS row_num
    FROM covid_deaths
    WHERE continent IS NOT NULL
) AS ranked_data
WHERE row_num = 1
ORDER BY 3 DESC;

-- What day we had most people die of COVID in UK?

SELECT 
    location, date, new_deaths
FROM
    covid_deaths
WHERE
    location = 'United Kingdom'
ORDER BY 3 DESC
LIMIT 1;


-- what day  we had most people die in each countr in the world?
SELECT location, date, new_deaths
FROM (
	SELECT location, date, new_deaths, ROW_NUMBER() OVER (PARTITION BY location ORDER BY new_deaths DESC) as row_num
	FROM covid_deaths
	WHERE continent IS NOT NULL
) as ranked_data
WHERE row_num = 1
ORDER BY 3 DESC;

-- let's break things down by continets 

SELECT 
    continent, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths
FROM
    covid_deaths
WHERE
    continent IS NOT NULL
GROUP BY continent
ORDER BY 2 DESC;


-- continents with deaths per population. Need to include the subquery as there is other values in 'location' than just countries / continents
SELECT 
    location,
    population,
    SUM(new_deaths) AS total_deaths,
    ROUND(((SUM(new_deaths) / population) * 100), 2) AS deaths_per_populations_percentage
FROM
    covid_deaths
WHERE
    continent IS NULL
        AND location IN (SELECT 
            continent
        FROM
            covid_deaths)
GROUP BY 1 , 2
ORDER BY 4 DESC;

-- global numbers

-- 20 days with highest number of new deaths globaly (and new registered cases on that day)

SELECT
date, SUM(new_cases), SUM(new_deaths)
FROM covid_deaths
GROUP BY 1
ORDER BY 3 DESC
LIMIT 20;

-- total global cases, deaths and death percentage

SELECT 
    location,
    population,
    SUM(new_cases),
    SUM(new_deaths),
    ROUND(((SUM(new_deaths) / SUM(new_cases)) * 100),
            2) AS death_percentage
FROM
    covid_deaths
WHERE
    location = 'World'
GROUP BY 1 , 2;


-- let's include the data from covid_vaccinations table now 

-- first, just like in the covid_deaths, let's update the format of the date column from DATETIME to DATE
ALTER TABLE covid_vaccinations
MODIFY date DATE;

-- let's look at each country population, vaccinations and the percentage of vaccinated population. 
-- sum of new vaccinations tells us the number of all given vaccinations, including first dose, second dose and boosters
-- max of people fully vaccinated gives us a number of people who have taken all required vaccinations to be considered fully vaccinated 

SELECT cd.location, cd.continent, cd.population, sum(cv.new_vaccinations), max(cv.people_fully_vaccinated) as people_fully_vaccinated, ROUND(((max(cv.people_fully_vaccinated) / population) * 100), 2) as vaccinated_population_percentage
FROM covid_deaths AS cd
JOIN covid_vaccinations cv
ON cd.location = cv.location AND cd.date = cv.date
-- WHERE cv.location = 'World'
GROUP BY 1,2 
ORDER BY 6 DESC;

-- using a CTE to check the rolling vaccinating population percentage in UK

WITH vac_pop(date, location, population, new_vaccinations, rolling_people_vaccinated)
as
(
SELECT cv.date, cv.location, cd.population, cv.new_vaccinations, SUM(cv.new_vaccinations) OVER (partition by cv.location ORDER BY cv.location, cv.date) as rolling_people_vaccinated 
FROM covid_vaccinations cv
JOIN covid_deaths cd
ON cd.location = cv.location AND cd.date = cv.date
WHERE cv.date > '2021-01-01'
)
SELECT * , ROUND((rolling_people_vaccinated/population *100),2) as fully_vaccinated_population_percentage
FROM vac_pop;


-- let's compare the data grouped by income
-- low income and lower middle income have more people and yet significantly less deaths and less vaccinations than high and upper income
-- this can tell us that our data from these groups are not full and we are missing crucial data so we will not be using this data in our visualisation

SELECT 
    cd.location,
    cd.population,
    SUM(cd.new_deaths) AS total_deaths,
    CONCAT(ROUND((SUM(cd.new_deaths) / cd.population) * 100, 2),'%') AS deaths_per_populations_percentage,
    MAX(cv.people_fully_vaccinated) fully_vaccinated_population,
    CONCAT(ROUND((MAX(cv.people_fully_vaccinated) / cd.population) * 100, 2),'%') AS fully_vaccinated_population_percentage
FROM
    covid_deaths cd
        JOIN
    covid_vaccinations cv ON cv.date = cd.date
        AND cv.location = cd.location
WHERE
    cd.location LIKE '%income%'
GROUP BY cd.location , cd.population
ORDER BY SUM(cd.new_deaths) DESC;


-- let's see how many tests have been taken in each country and how many positive cases there has been

SELECT 
    cv.location,
    MAX(cv.total_tests) AS total_tests,
    SUM(cd.new_cases) AS total_cases,
    ROUND((SUM(cd.new_cases) / MAX(cv.total_tests)) * 100, 2) cases_per_100_tests
FROM
    covid_vaccinations cv
        JOIN
    covid_deaths cd ON cd.location = cv.location
        AND cd.date = cv.date
-- WHERE cv.continent = 'Europe'
GROUP BY 1
ORDER BY 4 DESC;

-- simple queries to use in the tableau dashboard

select location, continent, max(people_vaccinated)
from covid_vaccinations
WHERE continent IS NOT NULL
GROUP BY location, continent;

select location, continent, population, sum(new_cases) as total_cases, sum(new_deaths) as total_deaths
from covid_deaths
WHERE continent IS NOT NULL
GROUP BY location, continent, population;

select cd.location, cd.continent, cd.date, cd.new_cases, cd.new_deaths, cv.new_vaccinations
FROM covid_deaths AS cd
JOIN covid_vaccinations cv
ON cd.location = cv.location AND cd.date = cv.date
WHERE cd.continent IS NOT NULL;


SELECT 
    location,
    population,
    SUM(new_cases) AS total_cases,
    SUM(new_deaths) AS total_deaths,
    ROUND(((SUM(new_deaths) / (SUM(new_cases))) * 100),
                    2) AS death_percentage
FROM
    covid_deaths
WHERE
    continent IS NULL
        AND location IN (
        SELECT continent
        FROM covid_deaths
        )
GROUP BY 1 , 2
ORDER BY 4 DESC;

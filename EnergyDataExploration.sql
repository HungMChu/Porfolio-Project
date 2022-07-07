/*
This is my short SQL data exploration project on the OurWorldInData Energy dataset.
I also created a Tableau Public dashboard using part of the data queried from the codes below.
The dashboard is available at the below URL:
https://public.tableau.com/views/ElectricityDashboard_16556440960280/Dashboard1?:language=en-US&:display_count=n&:origin=viz_share_link&:device=desktop

The dataset is publicly available at the below URL in .csv format:
https://github.com/owid/energy-data
I divided the dataset into 2 smaller datasets with the following columns:
- EnergyGeneration: iso_code, country, year, population, gdp, and all columns related to energy generation
- EnergyConsumption: iso_code, country, year, and all columns related to energy consumption

Additionally, mapping of countries to continents is taken from the below dataset:
https://www.kaggle.com/datasets/andradaolteanu/country-mapping-iso-continent-region
*/

-- 1. Electricity demand and GDP correlation in 2018
SELECT gen.country as Country,
  regions.region as Continent,
  gen.population as Population,
  cast(cons.electricity_demand as float) / gen.population * 1000000000 as ElecDemandPerCapita,
  gen.gdp / gen.population as GDPPerCapita
FROM continents2 as regions
INNER JOIN EnergyGeneration as gen
    ON regions.[alpha-3] = gen.iso_code
INNER JOIN EnergyConsumption as cons
    ON gen.iso_code = cons.iso_code
    AND gen.year = cons.year
WHERE LEN(gen.iso_code) = 3
    AND gen.year = 2018
    AND ISNULL(cast(cons.electricity_demand as float),0) <> 0
    AND ISNULL(cast(gen.gdp as float),0) <> 0
ORDER BY 1

-- 2. Amount of GHS emission per unit electricty generated in each country from 2001 to 2020 
SELECT country as Country, year as Year,
  greenhouse_gas_emissions / cast(electricity_generation as float)*1000 as EmissionPerUnitEnergy
FROM EnergyGeneration
WHERE LEN(iso_code) = 3
    AND year >= 2001
    AND year <= 2020
    AND ISNULL(cast(electricity_generation as float), 0) <> 0 
ORDER BY 1,2

-- 3. Top electricity export countries in terms of absolute amount in a certain yaer
CREATE PROCEDURE TopExporter
@year int
AS
SELECT TOP(10) gen.country as Country, 
  cast(gen.electricity_generation as float) - cast(con.electricity_demand as float) as ExportAmount
FROM EnergyGeneration as gen
INNER JOIN EnergyConsumption as con
    ON gen.country = con.country
    AND gen.year = con.year
WHERE LEN(gen.iso_code) = 3
    AND gen.year = @year
ORDER BY 2 DESC

EXEC TopExporter @year = 2020

--3.5. Number of countries in each continent that export at least equivalently 10% of its electricity demand
WITH export10 (Country, Continent, Year, GenDemandRatio)
AS (
SELECT gen.country, conti.region, gen.year,
  cast(gen.electricity_generation as numeric) / cast(cons.electricity_demand as numeric) 
FROM continents2 as conti
INNER JOIN EnergyGeneration as gen
    ON conti.[alpha-3] = gen.iso_code
INNER JOIN EnergyConsumption as cons
    ON gen.country = cons.country
    AND gen.year = cons.year
WHERE LEN(gen.iso_code) = 3
    AND gen.year >= 2001
    AND gen.year <= 2020
    AND ISNULL(cast(cons.electricity_demand as numeric), 0) <> 0 
)
SELECT Year, Continent, COUNT(Country) as NumberOfCountries
FROM export10
WHERE GenDemandRatio >= 1.1
GROUP BY Year, Continent
ORDER BY 1, 2

-- 4. Electricy generation from each category by continent in 2020
SELECT conti.region as Continent,
  SUM(cast(gen.coal_electricity as numeric) + cast(gen.gas_electricity as numeric) + cast(gen.oil_electricity as numeric)) as FossilFuelElec,
  SUM(cast(gen.nuclear_electricity as numeric)) as NuclearElec,
  SUM(cast(gen.renewables_electricity as numeric)) as RenewElec
FROM continents2 as conti
INNER JOIN EnergyGeneration as gen
    ON conti.[alpha-3] = gen.iso_code
WHERE LEN(gen.iso_code) = 3
    AND gen.year = 2020
GROUP BY conti.region
ORDER BY 1

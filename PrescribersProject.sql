---1a. Which prescriber had the highest total number of claims (totaled over all drugs)? 
------Report the npi and the total number of claims.
---*** npi: 1881634483 total: 99707
---1b. Repeat the above, but this time report the nppes_provider_first_name, 
------nppes_provider_last_org_name, specialty_description, and the total number of claims.
---*** BRUCE PENDLEY, Family Practice, 99707
SELECT npi, SUM(total_claim_count) AS tcc_sum
FROM prescription
GROUP BY npi
ORDER BY tcc_sum DESC
LIMIT 1;
----------
SELECT prescription.npi, 
	   nppes_provider_first_name, 
	   nppes_provider_last_org_name, 
	   specialty_description, 
	   SUM(total_claim_count) AS claim_count
FROM prescription
	LEFT JOIN prescriber
	USING (npi)
GROUP BY prescription.npi, nppes_provider_first_name, 
	   nppes_provider_last_org_name, 
	   specialty_description
ORDER BY claim_count DESC
LIMIT 1;
-------------------------------------------------------------------------------------------------------------
---2a. Which specialty had the most total number of claims (totaled over all drugs)?
---*** Family Practice, 9752347
---2b. Which specialty had the most total number of claims for opioids?
---*** nurse Practioner 900845
---2c. Challenge Question: Are there any specialties that appear in the prescriber table that have no 
----------------associated prescriptions in the prescription table?
---2d. Difficult Bonus: Do not attempt until you have solved all other problems! 
------For each specialty, report the percentage of total claims by that specialty which are for opioids. 
------Which specialties have a high percentage of opioids?

SELECT specialty_description, SUM(total_claim_count) AS sum_tot
FROM prescriber
	 LEFT JOIN prescription
	 USING (npi)
GROUP BY prescriber.specialty_description
ORDER BY sum_tot DESC NULLS LAST;
----------
SELECT specialty_description, SUM(total_claim_count) as total_opioid_claims
FROM prescriber
	 LEFT JOIN prescription
	 ON prescriber.npi = prescription.npi
	 INNER JOIN drug
	 ON prescription.drug_name = drug.drug_name
WHERE opioid_drug_flag ='Y'
GROUP BY specialty_description
ORDER BY total_opioid_claims DESC;
----------

---3a. Which drug (generic_name) had the highest total drug cost?
---*** "INSULIN GLARGINE,HUM.REC.ANLOG"	104264066.35
---3b. Which drug (generic_name) has the hightest total cost per day? 
---*** C1 esterase inhibitor
---Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.

SELECT generic_name, SUM(total_drug_cost) AS tot_drug_cost
FROM prescription
	LEFT JOIN drug
	on prescription.drug_name = drug.drug_name
GROUP BY generic_name
ORDER BY tot_drug_cost DESC;
----------
SELECT generic_name, ROUND(SUM(total_drug_cost)/SUM(total_day_supply), 2) AS cost_per_day
FROM prescription
	FULL JOIN drug
	USING(drug_name)
GROUP BY generic_name
ORDER BY cost_per_day DESC NULLS LAST;
---------------------------------------------------------------------------------
---4a. For each drug in the drug table, return the drug name 
--------and then a column named 'drug_type' which says 'opioid' for drugs which have 
-------opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', 
----------and says 'neither' for all other drugs.
---4b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) 
---------on opioids or on antibiotics. 
---*** opioids = $105,080,626.37
----Hint: Format the total costs as MONEY for easier comparision.
SELECT drug_name,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		 WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic' 
		 ELSE 'neither'
	END AS drug_type
FROM drug;
----------
SELECT 
	SUM(CASE WHEN opioid_drug_flag = 'Y' THEN total_drug_cost:: money END) AS opioid_cost,
	SUM(CASE WHEN antibiotic_drug_flag = 'Y' THEN total_drug_cost::money END) AS antibotic_cost 
FROM drug
LEFT JOIN prescription
	 ON drug.drug_name = prescription.drug_name;
--------------------------------------------------------------------------------------------
---5a. How many CBSAs are in Tennessee? Warning: The cbsa table contains information for all states, not just Tennessee.
---*** 10
---5b. Which cbsa has the largest combined population? Which has the smallest? 
-----------Report the CBSA name and total population.
---*** LARGEST: NASHVILLE DAVIDSON-MURFREESBORO-FRANKLIN, TN 1830410
---*** SMALLEST; MORRISTOWN, TN 116352
---5c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county 
-----------name and population.
---*** "SEVIER"	95523
SELECT COUNT(DISTINCT cbsa) 
FROM cbsa
WHERE cbsaname LIKE '%TN%';
----------
SELECT cbsaname, SUM(population) as total_pop
FROM population
	LEFT JOIN fips_county
	ON population.fipscounty = fips_county.fipscounty
	INNER JOIN cbsa
	ON  cbsa.fipscounty = fips_county.fipscounty
GROUP BY cbsaname
ORDER BY total_pop ASC;
----------
SELECT county, population
FROM fips_county as fc
	LEFT JOIN population
	USING(fipscounty)
	LEFT JOIN cbsa 
	USING (fipscounty)
	WHERE state = 'TN' AND cbsa IS null 
ORDER BY population DESC NULLS LAST;

---------------------------------------------------------------------------------------------
---6a. Find all rows in the prescription table where total_claims is at least 3000. 
------Report the drug_name and the total_claim_count.
---6b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
---6c. Add another column to you answer from the previous part which gives the prescriber first 
------and last name associated with each row.

SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >= 3000;
----------
SELECT drug_name, total_claim_count, opioid_drug_flag
FROM prescription
	LEFT JOIN drug
	USING (drug_name)
WHERE total_claim_count >= 3000;
-----------
SELECT drug_name, total_claim_count, opioid_drug_flag, nppes_provider_first_name, nppes_provider_last_org_name
FROM prescription
	LEFT JOIN drug
	USING (drug_name)
	INNER JOIN prescriber
	USING(npi)
WHERE total_claim_count >= 3000
ORDER BY total_claim_count;

-----------------------------------------------------------------------------------------------------
---The goal of this exercise is to generate a full list of all pain management specialists in Nashville 
--------and the number of claims they had for each opioid. 
---Hint: The results from all 3 parts will have 637 rows.
---a. First, create a list of all npi/drug_name combinations for pain management specialists 
----(specialty_description = 'Pain Managment') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), 
----where the drug is an opioid (opiod_drug_flag = 'Y'). Warning: Double-check your query before running it. 
----You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
----b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, 
---------whether or not the prescriber had any claims. 
---You should report the npi, the drug name, and the number of claims (total_claim_count).
---c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. 
------Hint - Google the COALESCE function.

SELECT npi, drug_name
FROM drug
	CROSS JOIN prescriber
WHERE nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
	AND specialty_description = 'Pain Management'
ORDER BY npi DESC;
--------
SELECT npi, drug_name, SUM(total_claim_count) AS total_claim
FROM drug
	CROSS JOIN prescriber
	FULL JOIN prescription USING(npi, drug_name)
WHERE nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
	AND specialty_description = 'Pain Management'
GROUP BY npi, drug_name
ORDER BY total_claim DESC NULLS LAST;
---------
SELECT npi, drug_name, COALESCE(SUM(total_claim_count), 0) AS total_claim
FROM drug
	CROSS JOIN prescriber
	FULL JOIN prescription USING(npi, drug_name)
WHERE nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
	AND specialty_description = 'Pain Management'
GROUP BY npi, drug_name
ORDER BY total_claim DESC NULLS LAST;







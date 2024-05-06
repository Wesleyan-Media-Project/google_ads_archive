# Wesleyan Media Project - google_ads_archive

Welcome! The purpose of this repository is to provide the scripts that replicate the workflow used by the Wesleyan Media Project to collect Google ads using BigQuery. The scripts in this repository are used to create tables in BigQuery, set up scheduled queries to import data, and analyze the data. The scripts provided here are intended to help journalists, academic researchers, and others interested in the democratic process to understand how to scrape and organize various ads from Google's political ads archive.

This repo is a part of the [Cross-platform Election Advertising Transparency Initiative (CREATIVE)](https://www.creativewmp.com/). CREATIVE has the goal of providing the public with analysis tools for more transparency of political ads across online platforms. In particular, CREATIVE provides cross-platform integration and standardization of political ads collected from Google and Facebook. CREATIVE is a joint project of the [Wesleyan Media Project (WMP)](https://mediaproject.wesleyan.edu/) and the [privacy-tech-lab](https://privacytechlab.org/) at [Wesleyan University](https://www.wesleyan.edu).

To analyze the different dimensions of political ad transparency we have developed an analysis pipeline. The scripts in this repo are part of the Data Collection Step in our pipeline.

![A picture of the repo pipeline with this repo highlighted](Creative_Pipelines.png)

## Table of Contents

- [2.Overview](#2-overview)
  - [Data in BigQuery](#data-in-bigquery)
- [3.Setup](#3-etup)
  - [Creating your own tables](#creating-your-own-tables)
  - [Setting up scheduled queries](#setting-up-scheduled-queries)
    - [Columns imported by the `add_g_advertiser_spend` query:](#columns-imported-by-the-add_g_advertiser_spend-query)
    - [Columns imported by the `daily_delta_g_creatives.sql` scheduled query:](#columns-imported-by-the-daily_delta_g_creativessql-scheduled-query)
  - [Creating the scheduled queries](#creating-the-scheduled-queries)
  - [Changing the run-times and configuration](#changing-the-run-times-and-configuration)
  - [Potential adjustments and issues](#potential-adjustments-and-issues)
    - [Adjustments](#adjustments)
    - [Issues](#issues)
      - [Issue 1: columns and data types](#issue-1-columns-and-data-types)
      - [Issue 2: changes of advertiser IDs](#issue-2-changes-of-advertiser-ids)
  - [Analyzing data in BigQuery](#analyzing-data-in-bigquery)
  - [Getting the ads' content](#getting-the-ads-content)
- [4. Thank You](#4-thank-you)

## 2.Overview

### Data in BigQuery

Both Facebook and Google started their archives of political ads about the same time - in May 2018. The approaches that the companies took are quite different. Facebook posts CSV files with summary statistics and has an API that outsiders can use to search for the ads. Google did not create an API and instead offers a web portal and summary reports.

These reports are available as CSV files and as a dataset hosted in the `bigquery-public-data` project in [BigQuery](https://cloud.google.com/bigquery) - a data warehouse in the Google Cloud Platform (GCP). Below is a screenshot of the tables in the dataset:

<img width="291" alt="Listing of tables available in the Google's political ads archive in BigQuery" src="https://github.com/Wesleyan-Media-Project/google_ads_archive/assets/17502191/c6d16686-f634-4b1b-a067-a8a1c80a6b89">

The following tables are of particular interest:

- `advertiser_declared_stats` - provides regulatory information on the advertiser.
- `advertiser_weekly_spend` - weekly updates on advertisers' spending. If an advertiser was not active in a specific week, there is no record for that week. The spends are reported in increments of $100.
- `advertiser_stats` - "lifetime" total stats for advertisers.
- `creative_stats` - "lifetime" total stats about the ads, one row per ad.

Even though, officially, the political ads archive is updated once a week, the tables in the dataset are updated more frequently: for instance, the `creative_stats` table is updated several times a day. We took advantage of this fact and implemented a solution that is based in Google BigQuery and collects periodic snapshots of the "lifetime" tables: the `advertiser_stats` and `creative_stats`.

## 3.Setup

### Creating your own tables

This section will guide you through the steps of creating the tables in BigQuery so you could replicate WMP's workflow.

Step 1: if you have not done it yet, register with Google Cloud Platform and create a project. The scripts in this repo expect that you have a project named `wmp-sandbox`. If you choose a different name, please don't forget to modify it in the scripts as well. For more details about creating a GCP project, please see the official documentation at this [link](https://cloud.google.com/resource-manager/docs/creating-managing-projects)

Step 2: Go to BigQuery page in GCP console. You can find the "BigQuery" card in the project dashboard, or you can search for it in the drop-down list of services. You can also try navigating directly by following this link: [https://console.cloud.google.com/bigquery](https://console.cloud.google.com/bigquery)

Step 3: Create a BigQuery dataset. In this repo, the scripts expect you to have a dataset named `my_ad_archive`. To create a dataset, locate your project in the EXPLORER tab in BigQuery console, click on the vertical ellipses next to the name of your project, and choose "Create Dataset". For more details, please see this [documentation page](https://cloud.google.com/bigquery/docs/datasets#create-dataset). Select the tab that describes the console-based workflow.

Step 4: Copy-paste the SQL statements from the file [create_tables.sql](https://github.com/Wesleyan-Media-Project/google_ads_archive/blob/main/create_tables.sql) into the code editor in BigQuery console. Run the statements. They will create two tables: `google_advertiser_agg_spend` and `google_creative_delta`.

The "...\_agg_spend" table will store the snapshots of the data from the `advertiser_spend` table from the source dataset. You will have snapshots of the cumulative spending of the advertisers. The `google_creative_delta` table will store snapshots of the metrics for the ads running on the Google platform.

Be careful: the statements from the file will perform "create or replace ..." operation: if the tables do not exist, they will be created, however, if the tables do exist, they will be overwritten and you will lose whatever data you already have in them.

Please read the "Potential adjustments and issues" section below for a discussion of how you might need to adjust the queries.

### Setting up scheduled queries

BigQuery has a functionality known as "scheduled queries" - the user can define a data import query and that query will run on a schedule. This functionality is similar to having crontab jobs running on a regular server. A nice feature is that, in case of failure, BigQuery will send an email notification. For technical details, please see this documentation [page](https://cloud.google.com/bigquery/docs/scheduling-queries)

We take a full snapshot of the `advertiser_stats` table once a day. For the `creative_stats` table, we query it every hour and keep only the new records. The queries are provided in the SQL script files in this repository: `add_g_advertiser_spend.sql` and `daily_delta_g_creatives.sql`

#### Columns imported by the `add_g_advertiser_spend` query

Below is the list of the columns imported from the advertiser spend table. We are assuming that you are based in the United States and are interested in the US advertisers. Because of this, we are importing only the column `spend_usd`, which reports the advertiser spend in US dollars. If you are operating in a different country, please make sure to replace the column `spend_usd` both in the definitional query (the `create_tables.sql`) and in the scheduled query.

```
advertiser_id, advertiser_name, public_ids_list, regions, elections, total_creatives,
    spend_usd
```

In addition to the columns from the source table, the scheduled query will insert columns `import_date` and `import_time`. They are generated from the parameters available during the execution of the query.

#### Columns imported by the `daily_delta_g_creatives.sql` scheduled query

```
    ad_id, ad_url, ad_type, regions,
    advertiser_id, advertiser_name, ad_campaigns_list,
    date_range_start, date_range_end, num_of_days,
    impressions,
    spend_usd,
    first_served_timestamp, last_served_timestamp,
    age_targeting,
    gender_targeting,
    geo_targeting_included, geo_targeting_excluded,
    spend_range_min_usd, spend_range_max_usd

```

As with the advertiser stats, we focus on the US elections. This is reflected in the choice of the columns: the underlying source table contains data for the currencies of the all countries where Google runs political ads (for instance, `spend_range_min_brl` and `spend_range_max_brl` for Brazil). We ignore these columns and keep only the `spend_range_min_usd` and `spend_range_max_usd`. We also keep the `spend_usd` column, even though it appears that Google itself is not using it: this column is always empty.

The `daily_delta_g_creatives` query inserts only those records from the underlying table which are new. This may mean a record for an entirely new ad, or a record for an ad that has changed. This is why the query has the "delta" in its name. This approach is similar to how we ingest Facebook ads where we store a record only if it is different from the one already in our system. See the "Exclusion of duplicate records" [section](https://github.com/Wesleyan-Media-Project/fb_ads_import#exclusion-of-duplicate-records) in the `fb_ads_import` repository.

The fields that may change are:

- `date_range_end` - end of the range of dates during which the ad was active
- `num_of_days` - number of days in the date range when the ad was active
- `impressions` - a bucket for the impressions number, for instance `1000-2000`
- `last_served_timestamp` - a timestamp (date plus time down to seconds) when the ad was served the last time
- `spend_range_min_usd` - the lower bound of the range for the USD spend on the ad
- `spend_range_max_usd` - the upper bound of the range for the USD spend on the ad

The "new" condition is implemented using the `SELECT ... EXCEPT DISTINCT ...` clause in the query. It will include those rows that are not present in the bottom part of the query following the EXCEPT clause.

Our own table contains the columns for the date and time of the data insertion. They are derived from the parameters `@run_date` and `@run_time` available from BigQuery.

### Creating the scheduled queries

As an illustration, let's walk through the process of creating a query that will import new ad records every hour.

Step 1: Open the SQL editor in the console. Paste the SQL statement from the file `daily_delta_g_creative.sql`.

Step 2: Click on the SCHEDULE -> Create new scheduled query menu items at the top of the editor pane. The screenshot below shows the location of the menu buttons.

<img width="678" alt="Screenshot of SQL code editor window and the SCHEDULE button" src="https://github.com/Wesleyan-Media-Project/google_ads_archive/assets/17502191/b08e5863-f839-47a3-9a54-297b541ca55e">

Step 3: Clicking on the "Create scheduled query" will open a pop-up tab on the right of the screen. Here you will need to enter the required parameters:

- Enter `import_creatives_delta` as the name. (Nothing in the scripts is linked to this name. It will only appear in the menu allowing you to modify or cancel query. You can change the name if you like.)
- Select "Hours" as repeat frequency, and then enter `1` into the "Repeats every" field that will appear. You can modify the settings as you like. For example, we run our query every hour.
- Leave the "destination table" fields empty. Our query contains an INSERT statement and it already "knows" the destination.
- Under "Notification settings", check the box for "Send notification emails". GCP/BigQuery will send an email to the email account associated with the owner of the project if the query fails.
- Click "SAVE" to save the query. BigQuery will launch the first import operation.

The process for the `add_g_advertiser_spend.sql` script is the same, except you will need to pick a different name.

### Changing the run-times and configuration

The console for managing the scheduled queries is accessed by clicking on the menu item in the left part of the screen (see the screenshot below).

<img width="240" alt="Screenshot of BigQuery menu ite4ms" src="https://github.com/Wesleyan-Media-Project/google_ads_archive/assets/17502191/8b00a362-c9e8-420c-a7d4-3953f0832950">

The menu will take you to a page that will allow you to see the history of the runs and also edit the configuration.

As an example, below is a screenshot of the "Scheduled queries" dashboard. You can see that the `import_creatives_delta` has successfully finished, while `add_g_advertiser_spend` was running.

<img width="1146" alt="Screenshot of the scheduled queries dashboard" src="https://github.com/Wesleyan-Media-Project/google_ads_archive/assets/17502191/dcd62034-8973-4898-b08c-8fb8c135d966">

### Potential adjustments and issues

### Adjustments

WMP focuses on the US-based activity and, because of this, the table creation scripts and the scheduled query scripts import only the columns associated with US dollars. The source tables contain columns for other currencies and countries as well. If you are interested in other countries, you need to modify the list of columns - replace `spend_range_min_usd` and `spend_range_max_usd` with the columns of your choice.

### Issues

### Issue 1: columns and data types

Our earlier iteration of the scripts would import all currency columns. We encountered two problems in this regard:

1. Some of the currency columns do not have an expected data type. For instance, in the `advertiser_spend` source table, there were issues with the Indian Rupee and Hungarian Forint columns. We had to use `SAFE_CAST(xxxx as STRING)` to import them as strings instead.
2. Changes in schema. Google may add new columns for currencies of countries that were added to the archive. This happened with New Zealand dollars and Brazilian Real. To avoid these problems, our script hard-coded the list of columns. If you choose to use `select * ...` statement to import multiple currency columns, you need to pay attention to the possible changes. Fortunately, the email notifications are very prompt and you will be aware of the problem within minutes after it happened.

### Issue 2: changes of advertiser IDs

The second issue does not affect the ability to import the data, but it does impact the ability to view the ad.

An ad record includes information about the advertiser, specifically the advertiser id and the full url for viewing the ad on the Ad Transparency website. In some situations Google would assign a new ID to an advertiser. (One possible scenario is when several advertisers merged.) When that happens, there would be more than one record for the same ad: the ad id would remain the same, but the advertiser information would be different.

As a result, **the `ad_url` field in the old ad record is not longer valid**: the ad urls include advertiser ID, and once the old ID is retired the url is no longer correct. If a user follows an old URL, they will land on apage that will say "ad no longer available" which is not the case.

### Analyzing data in BigQuery

Once you have your scheduled queries running, you can start analyzing the data directly in the browser. Here is an example query that will return data on 10 ads that had more than one record. This kind of data is useful in determining the cost per impression of an ad:

```
with a as (select ad_id, count(*) as N
  from wmp-sandbox.my_ad_archive.google_creative_delta
  where regions = 'US'
  group by ad_id
  having N > 1
  order BY N desc
  limit 10)
select ad_id, advertiser_name, ad_type, ad_url, impressions, spend_range_min_usd, spend_range_max_usd, import_time
from wmp-sandbox.my_ad_archive.google_creative_delta
inner join a using (ad_id)
order by ad_id, import_time;
```

The query below will return the latest impressions for 10 ads owned by `DCCC` - Democratic Congressional Campaign Committee:

```
with a as (select ad_id, max(import_time) as max_time
  from my_ad_archive.google_creative_delta
  where regions = 'US'
  and advertiser_name = 'DCCC'
  group by ad_id
  limit 10)
select x.ad_id, advertiser_name, ad_type, ad_url, impressions, spend_range_min_usd, spend_range_max_usd, import_time
from my_ad_archive.google_creative_delta as x
inner join a
on a.ad_id = x.ad_id
and a.max_time = x.import_time
order by ad_id, import_time;
```

You can also use the BigQuery connector in Google Sheets to work with the data. Read this [document](https://support.google.com/docs/answer/9702507?hl=en) for instructions.

### Getting the ads' content

In contrast to Facebook/Meta, Google's archive does not have the content of the ads, even when the ad consists only of text. The only content-related field is `ad_type` which takes the values `TEXT`, `IMAGE` or `VIDEO`. To retrieve the contents of the ads we, with the permission of the Google Political Ads Transparency team, scrape the ads and store them in a local database on a server maintained by WMP.

## 4. Thank You

<p align="center"><strong>We would like to thank our financial supporters!</strong></p><br>

<p align="center">This material is based upon work supported by the National Science Foundation under Grant Numbers 2235006, 2235007, and 2235008.</p>

<p align="center" style="display: flex; justify-content: center; align-items: center;">
  <a href="https://www.nsf.gov/awardsearch/showAward?AWD_ID=2235006">
    <img class="img-fluid" src="nsf.png" height="150px" alt="National Science Foundation Logo">
  </a>
</p>

<p align="center">The Cross-Platform Election Advertising Transparency Initiative (CREATIVE) is a joint infrastructure project of the Wesleyan Media Project and privacy-tech-lab at Wesleyan University in Connecticut.

<p align="center" style="display: flex; justify-content: center; align-items: center;">
  <a href="https://www.creativewmp.com/">
    <img class="img-fluid" src="CREATIVE_logo.png"  width="220px" alt="CREATIVE Logo">
  </a>
</p>

<p align="center" style="display: flex; justify-content: center; align-items: center;">
  <a href="https://mediaproject.wesleyan.edu/">
    <img src="wmp-logo.png" width="218px" height="100px" alt="Wesleyan Media Project logo">
  </a>
</p>

<p align="center" style="display: flex; justify-content: center; align-items: center;">
  <a href="https://privacytechlab.org/" style="margin-right: 20px;">
    <img src="./plt_logo.png" width="200px" alt="privacy-tech-lab logo">
  </a>
</p>

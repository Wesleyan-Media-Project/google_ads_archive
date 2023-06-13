# google_ads_archive

# How Wesleyan Media Project collects Google ads

## Data in BigQuery

Both Facebook and Google started their archives of political ads about the same time - in May 2018. The approaches that the companies took are quite different. Facebook posts CSV files with summary statistics and has an API that outsiders can use to search for the ads. Google did not create an API and isntead offers a web portal and summary reports.

These reports are available as CSV files and as a dataset hosted in the `bigquery-public-data` project in [BigQuery](https://cloud.google.com/bigquery) - a data warehouse in the Google Cloud Platform (GCP). Below is a screenshot of the tables in the dataset:

<img width="291" alt="Listing of tables available in the Google's political ads archive in BigQuery" src="https://github.com/Wesleyan-Media-Project/google_ads_archive/assets/17502191/c6d16686-f634-4b1b-a067-a8a1c80a6b89">

The following tables are of particular interest:
* `advertiser_declared_stats` - provides regulatory information on the advertiser.
* `advertiser_weekly_spend` - weekly updates on advertisers' spending. If an advertiser was not active in a specific week, there is no record for that week. The spends are reported in increments of $100.
* `advertiser_stats` - "lifetime" total stats for advertisers.
* `creative_stats` - "lifetime" total stats about the ads, one row per ad.

Even though, officially, the political ads archive is updated once a week, the tables in the dataset are updated more frequently: for instance, the `creative_stats` table is updated several times a day. We took advantage of this fact and implemented a solution that is based in Google BigQuery and collects periodic snapshots of the "lifetime" tables: the `advertiser_stats` and `creative_stats`.

## Data import through scheduled queries

BigQuery has a functionality known as "scheduled queries" - the user can define a data import query and that query will run on a schedule. This functionality is similar to having crontab jobs running on a regular server. A nice feature is that, in case of failure, BigQuery will send an email notification. For technical details, please see this documentation [page](https://cloud.google.com/bigquery/docs/scheduling-queries)

We take a full snapshot of the `advertiser_stats` table once a day (3 pm EST, 7 pm UTC). For the `creative_stats` table, we query it every hour and keep only the new records. The queries are provided in the SQL script files in this repository: `add_g_advertiser_spend.sql` and `daily_delta_g_creatives.sql`

### The cumulative stats of advertisers query:
```
insert into g_ads_targeting.my_advertiser_stats 
    select advertiser_id, advertiser_name, public_ids_list, regions, elections, 
        total_creatives, spend_usd, spend_eur, 
        SAFE_CAST(spend_inr AS STRING) as spend_inr, 
        spend_bgn, spend_hrk, spend_czk, spend_dkk, 
        SAFE_CAST(spend_huf AS STRING), 
        spend_pln, spend_ron, spend_sek, spend_gbp, spend_nzd, 
        CAST(@run_date as DATE) as import_date 
        from `bigquery-public-data.google_political_ads.advertiser_stats`;
```
In addition to the columns from the underlying table in the `google_political_ads` dataset, the query stores a field dervied from the the parameter `@run_date` which is available during execution of the query (see the documentation [section](https://cloud.google.com/bigquery/docs/scheduling-queries#available_parameters)).

### The creative stats delta query:

```
insert into `wmp-project.g_ads_targeting.creative_stats_delta` 
    with a as (select * from `bigquery-public-data.google_political_ads.creative_stats` 
        EXCEPT DISTINCT 
        select * EXCEPT(import_date, import_time) 
        from `wmp-laura.g_ads_targeting.creative_stats_delta`) 
    select a.* except (spend_range_min_brl, spend_range_max_brl), 
        CAST(@run_date as DATE) as import_date, CAST(@run_time as TIMESTAMP) as import_time, 
        a.spend_range_min_brl, spend_range_max_brl from a;
```

This query inserts only those records from the underlying table which are new. This may mean a record for an entirely new ad, or a record for an ad that has changed. The fields that may change are:
* `date_range_end` - end of the range of dates during which the ad was active
* `num_of_days` - number of days in the date range when the ad was active
* `impressions` - a bucket for the impressions number, for instance `1000-2000`
* `last_served_timestamp` - a timestamp (date plus time down to seconds) when the ad was served the last time
* `spend_range_min_...` - the lower bound of the range for the spend on the ad, for a specific currency
* `spend_range_max_...` - the upper bound of the range for the spend on the ad, for a specific currency

The last two items in the list represent several columns, one for each currency. For the ads that ran in the US, the columns are `spend_range_min_usd` and `spend_range_max_usd`. There are similar columns for other currencies. We did not want to impose prior judgment on which columns will matter, thus we import all columns for every record.

The "new" condition is implemented using the `SELECT ... EXCEPT DISTINCT ...` clause in the query. It will include those rows that are not present in the bottom part of the query following the EXCEPT clause. Our own table contains the columns for the date and time of the data insertion. They are derived from the parameters `@run_date` and `@run_time` available from BigQuery.

To make sure that the decision to insert a record is based only on the columns present in the `google_political_ads` dataset, we exclude the `import_date` and `import_time` from the comparison query. This is done using the statement `SELECT * EXCEPT(import_date, import_time)`




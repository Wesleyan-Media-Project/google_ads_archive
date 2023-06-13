# google_ads_archive

# How Wesleyan Media Project collects Google ads

Both Facebook and Google started their archives of political ads about the same time - in May 2018. The approaches that the companies took are quite different. Facebook posts CSV files with summary statistics and has an API that outsiders can use to search for the ads. Google did not create an API and isntead offers a web portal and summary reports.

These reports are available as CSV files and as a dataset hosted in the `bigquery-public-data` project in [BigQuery](https://cloud.google.com/bigquery) - a data warehouse in the Google Cloud Platform (GCP). Below is a screenshot of the tables in the dataset:

<img width="291" alt="Listing of tables available in the Google's political ads archive in BigQuery" src="https://github.com/Wesleyan-Media-Project/google_ads_archive/assets/17502191/c6d16686-f634-4b1b-a067-a8a1c80a6b89">

The following tables are of particular interest:
* `advertiser_declared_stats` - provides regulatory information on the advertiser.
* `advertiser_weekly_spend` - weekly updates on advertisers' spending. If an advertiser was not active in a specific week, there is no record for that week. The spends are reported in increments of $100.
* `advertiser_stats` - "lifetime" total stats for advertisers.
* `creative_stats` - "lifetime" total stats about the ads, one row per ad.

Even though, officially, the political ads archive is updated once a week, the tables in the dataset are updated more frequently: for instance, the `creative_stats` table is updated several times a day. We take advantage of this fact and implemented a solution that is based in Google BigQuery and collects periodic snapshots of the "lifetime" tables: the `advertiser_stats` and `creative_stats`.

## Data import through scheduled transfers





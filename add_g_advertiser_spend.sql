-- this is a scheduled query add_g_advertiser_spend
-- it runs once a day and inserts a snapshot of the whole archive
-- into the table that WMP owns
insert into wmp-sandbox.my_ad_archive.google_advertiser_agg_spend
    select advertiser_id, 
        advertiser_name, 
        public_ids_list, 
        regions, 
        elections, 
        total_creatives, 
        spend_usd,
        CAST(@run_date as DATE) as import_date,
        CAST(@run_time as TIMESTAMP) as import_time 
        from `bigquery-public-data.google_political_ads.advertiser_stats`;
    

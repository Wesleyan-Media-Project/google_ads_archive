-- this is a scheduled query add_g_advertiser_spend
-- it runs once a day and inserts a snapshot of the whole archive
-- into the table that WMP owns
insert into g_ads_targeting.my_advertiser_stats 
    select advertiser_id, advertiser_name, public_ids_list, regions, elections, 
        total_creatives, spend_usd, spend_eur, 
        SAFE_CAST(spend_inr AS STRING) as spend_inr, 
        spend_bgn, spend_hrk, spend_czk, spend_dkk, 
        SAFE_CAST(spend_huf AS STRING), 
        spend_pln, spend_ron, spend_sek, spend_gbp, spend_nzd, 
        CAST(@run_date as DATE) as import_date 
        from `bigquery-public-data.google_political_ads.advertiser_stats`;
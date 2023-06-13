insert into `wmp-project.g_ads_targeting.creative_stats_delta` 
    with a as (select * from `bigquery-public-data.google_political_ads.creative_stats` 
        EXCEPT DISTINCT 
        select * EXCEPT(import_date, import_time) 
        from `wmp-laura.g_ads_targeting.creative_stats_delta`) 
    select a.* except (spend_range_min_brl, spend_range_max_brl), 
        CAST(@run_date as DATE) as import_date, CAST(@run_time as TIMESTAMP) as import_time, 
        a.spend_range_min_brl, spend_range_max_brl from a;
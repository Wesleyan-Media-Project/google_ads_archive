-- query that will be saved as scheduled query "import_creatives_delta"
insert into `intro-sql-workshop.my_ad_archive.google_creative_delta` 
    with a as (select 
        ad_id, 
        ad_url, 
        ad_type, 
        regions, 
        advertiser_id, 
        advertiser_name, 
        ad_campaigns_list, 
        date_range_start, 
        date_range_end, 
        num_of_days, 
        impressions, 
        spend_usd, 
        first_served_timestamp, 
        last_served_timestamp, 
        age_targeting, 
        gender_targeting, 
        geo_targeting_included, 
        geo_targeting_excluded, 
        spend_range_min_usd, 
        spend_range_max_usd
     from `bigquery-public-data.google_political_ads.creative_stats` 
        EXCEPT DISTINCT 
        select 
            ad_id, 
            ad_url, 
            ad_type, 
            regions, 
            advertiser_id, 
            advertiser_name, 
            ad_campaigns_list, 
            date_range_start, 
            date_range_end, 
            num_of_days, 
            impressions, 
            spend_usd, 
            first_served_timestamp, 
            last_served_timestamp, 
            age_targeting, 
            gender_targeting, 
            geo_targeting_included, 
            geo_targeting_excluded, 
            spend_range_min_usd, 
            spend_range_max_usd

        from `intro-sql-workshop.my_ad_archive.google_creative_delta`) 
    select a.*,  
        CAST(@run_date as DATE) as import_date, CAST(@run_time as TIMESTAMP) as import_time, 
        from a;

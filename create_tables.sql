create or replace table wmp-sandbox.my_ad_archive.google_advertiser_agg_spend
(
    advertiser_id STRING, 
    advertiser_name STRING, 
    public_ids_list STRING, 
    regions STRING, 
    elections STRING, 
    total_creatives INT64, 
    spend_usd INT64,
    import_date DATE,
    import_time TIMESTAMP);

create or replace table wmp-sandbox.my_ad_archive.google_creative_delta
(
    ad_id STRING, 
    ad_url STRING, 
    ad_type STRING, 
    regions STRING, 
    advertiser_id STRING, 
    advertiser_name	STRING, 
    ad_campaigns_list STRING, 
    date_range_start DATE, 
    date_range_end DATE, 
    num_of_days INT64, 
    impressions STRING, 
    spend_usd STRING, 
    first_served_timestamp TIMESTAMP, 
    last_served_timestamp TIMESTAMP, 
    age_targeting STRING, 
    gender_targeting STRING, 
    geo_targeting_included STRING, 
    geo_targeting_excluded STRING, 
    spend_range_min_usd INT64, 
    spend_range_max_usd INT64,
    import_date DATE,
    import_time TIMESTAMP
);

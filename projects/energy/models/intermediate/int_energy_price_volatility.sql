-- ---------------------------------------------------------------------------
-- int_energy_price_volatility
--
-- Summarises daily commodity prices into annual volatility statistics. Average
-- price gives the year's level, while standard deviation captures the absolute
-- spread of observations around it.
--
-- The coefficient of variation divides that spread by the average, making
-- volatility comparable across commodities quoted at very different price
-- levels. NULLIF protects the ratio if a commodity's annual average is zero.
--
-- Grain: one row per calendar_year and commodity_code.
-- ---------------------------------------------------------------------------

{{ config(materialized='view') }}

with prices as (

    select * from {{ ref('int_energy_commodity_prices_unpivoted') }}

),

-- Aggregate observed prices only. The upstream UNPIVOT already removed days
-- with no quoted price, so sparse series such as gasoline are not treated as
-- zero-price observations.
annual_volatility as (

    select
        year(price_date) as calendar_year,
        commodity_code,
        commodity_name,
        commodity_group,
        price_unit,
        is_energy_complex,
        avg(price_usd) as average_price_usd,
        stddev(price_usd) as price_standard_deviation_usd,
        stddev(price_usd) / nullif(avg(price_usd), 0) as coefficient_of_variation

    from prices
    group by
        year(price_date),
        commodity_code,
        commodity_name,
        commodity_group,
        price_unit,
        is_energy_complex

)

select * from annual_volatility

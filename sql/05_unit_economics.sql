-- анализ unit-экономики по каналам привлечения
with
-- рассчитываем средний ltv по каждому каналу
avg_revenue as (
	select
		acquisition_channel,
		round(
			avg(subscription_length / 30.0 * 350),
			2
		) as ltv
	from subscriptions
	group by
		acquisition_channel
),
-- задаем стоимость привлечения пользователей (cac)
channel_costs as (
	select
		acquisition_channel,
		ltv,
		case
			when acquisition_channel = 'ads' then 500
			when acquisition_channel = 'organic' then 100
			when acquisition_channel = 'referral' then 200
		end as cac
	from avg_revenue
)
-- рассчитываем отношение ltv к cac
select
	acquisition_channel,
	ltv,
	cac,
	round(
		ltv / cac,
		2
	) as ltv_cac
from channel_costs
order by
	ltv_cac desc;
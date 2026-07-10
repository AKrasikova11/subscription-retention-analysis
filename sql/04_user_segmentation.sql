-- сегментация пользователей по уровню вовлеченности
with
-- рассчитываем активность каждого пользователя
user_activity as (
	select
		u.user_id,
		u.acquisition_channel,
		count(e.event_date) as views_count,
		count(distinct e.event_date) as active_days,
		s.subscription_length,
		-- рассчитываем условный ltv
		round(s.subscription_length / 30.0 * 350, 2) as ltv
	from users u
	left join events e
		on u.user_id = e.user_id
		and e.event_type = 'watch'
	left join subscriptions s
		on u.user_id = s.user_id
	group by
		u.user_id,
		u.acquisition_channel,
		s.subscription_length
),
-- сегментируем пользователей по количеству просмотров
segments as (
	select
		*,
		case
			when views_count <= 2 then 'early churn'
			when views_count <= 8 then 'normal'
			else 'loyal'
		end as segment
	from user_activity
),
-- рассчитываем показатели для каждого сегмента
segment_stats as (
	select
		acquisition_channel,
		segment,
		count(*) as users_count,
		round(avg(views_count), 2) as avg_views,
		round(avg(active_days), 2) as avg_active_days,
		round(avg(ltv), 2) as avg_ltv
	from segments
	group by
		acquisition_channel,
		segment
)
-- ранжируем сегменты по уровню вовлеченности
select
	*,
	dense_rank() over (
		partition by acquisition_channel
		order by avg_views desc
	) as engagement_rank
from segment_stats
order by
	acquisition_channel,
	engagement_rank;
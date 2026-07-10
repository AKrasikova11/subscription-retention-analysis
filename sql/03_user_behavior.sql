-- анализ поведения пользователей по каналам привлечения
with
-- рассчитываем активность каждого пользователя
user_activity as (
	select
		u.user_id,
		u.acquisition_channel,
		count(e.event_date) as views_count,
		count(distinct e.event_date) as active_days
	from users u
	left join events e
		on u.user_id = e.user_id
		and e.event_type = 'watch'
	group by
		u.user_id,
		u.acquisition_channel
)
-- рассчитываем показатели активности по каждому каналу
select
	acquisition_channel,
	count(*) as users_count,
	round(avg(views_count), 2) as avg_views,
	round(
		(
			percentile_cont(0.5)
			within group (order by views_count)
		)::numeric,
		2
	) as median_views,
	round(avg(active_days), 2) as avg_active_days,
	round(
		(stddev_samp(views_count))::numeric,
		2
	) as std_views,
	min(views_count) as min_views,
	max(views_count) as max_views
from user_activity
group by
	acquisition_channel
order by
	avg_views desc;
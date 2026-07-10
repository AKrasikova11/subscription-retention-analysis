-- расчет retention по каналам привлечения
with
-- рассчитываем дни жизни пользователя
user_activity as (
	select
		u.user_id,
		u.registration_date,
		u.acquisition_channel,
		date(e.event_date) - date(u.registration_date) as days_since_registration
	from users u
	join events e
		on u.user_id = e.user_id
		and e.event_type = 'watch'
	where date(e.event_date) >= date(u.registration_date)
		and date(e.event_date) - date(u.registration_date) <= 30
),
-- рассчитываем размер каждой когорты
cohorts as (

	select
		acquisition_channel,
		registration_date,
		count(distinct user_id) as cohort_size
	from users
	group by
		acquisition_channel,
		registration_date
),
-- рассчитываем количество активных пользователей
active_users as (

	select
		acquisition_channel,
		registration_date,
		days_since_registration,
		count(distinct user_id) as users_count
	from user_activity
	group by
		acquisition_channel,
		registration_date,
		days_since_registration
),
-- рассчитываем retention для каждой когорты
retention as (

	select
		a.acquisition_channel,
		a.registration_date,
		a.days_since_registration,
		round(
			100.0 * a.users_count / c.cohort_size,
			3
		) as retention
	from active_users a
	join cohorts c
		on a.acquisition_channel = c.acquisition_channel
		and a.registration_date = c.registration_date
)
-- рассчитываем средний retention по каналам привлечения
select
	acquisition_channel,
	days_since_registration,
	round(avg(retention), 2) as avg_retention
from retention
where days_since_registration in (0, 1, 3, 7, 14, 30)
group by
	acquisition_channel,
	days_since_registration
order by
	acquisition_channel,
	days_since_registration;
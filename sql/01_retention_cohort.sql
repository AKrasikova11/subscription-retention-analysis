-- расчет retention по когортам
with
-- рассчитываем дни жизни пользователя
user_activity as (
	select
		u.user_id,
		u.registration_date,
		date(e.event_date) - date(u.registration_date) as days_since_registration
	from users u
	join events e
		on u.user_id = e.user_id
		and e.event_type = 'watch'
	where date(e.event_date) >= date(u.registration_date)
		and date(e.event_date) - date(u.registration_date) <= 30

),
-- рассчитываем количество активных пользователей по дням жизни
active_users as (
	select
		registration_date,
		days_since_registration,
		count(distinct user_id) as users_count
	from user_activity
	group by
		registration_date,
		days_since_registration

),
-- рассчитываем размер каждой когорты
cohorts as (
	select
		registration_date,
		count(distinct user_id) as cohort_size
	from users
	group by
		registration_date

)
-- рассчитываем retention для каждой когорты
select
	a.registration_date,
	a.days_since_registration,
	round(
		100.0 * a.users_count / c.cohort_size,
		3
	) as retention
from active_users a
join cohorts c
	on a.registration_date = c.registration_date
order by
	a.registration_date,
	a.days_since_registration;
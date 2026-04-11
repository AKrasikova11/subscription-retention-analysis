-- расчет retention с сегментацией по каналам привлечения
with 
-- рассчитываем дни жизни пользователя + добавляем канал
cnt_days as (
	select
		u.user_id,
		u.registration_date, 
		u.acquisition_channel, 
		date(e.event_date) - date(u.registration_date) as days_since_registration
	from users u
	join events e
		on u.user_id = e.user_id
	where e.event_type = 'watch'
),
-- считаем размер когорты по каналу и дате регистрации
cohorts as (
	select 
		acquisition_channel, 
		registration_date, 
		count(distinct user_id) as cohort_size
	from users
	group by acquisition_channel, registration_date
),
-- считаем количество активных пользователей по дням
cnt_users as (
	select 
		acquisition_channel,
		registration_date,
		days_since_registration, 
		count(distinct user_id) as cnt_users
	from cnt_days
	where days_since_registration >= 0
	group by acquisition_channel, registration_date, days_since_registration
),
-- рассчитываем retention по каждой когорте и каналу
retention as (
	select 
		c.acquisition_channel, 
		cu.registration_date,
		cu.days_since_registration,
		round(100.0 * cu.cnt_users / c.cohort_size, 3) as retention
	from cnt_users cu
	join cohorts c
		on cu.acquisition_channel = c.acquisition_channel 
		and cu.registration_date = c.registration_date
	where cu.days_since_registration <= 30
)
-- агрегируем retention по каналам (усреднение по когортам)
select 
	acquisition_channel,
	days_since_registration,
	round(avg(retention), 2) as avg_retention
from retention
where days_since_registration in (0, 1, 3, 7, 14, 30)  -- ключевые дни
group by acquisition_channel, days_since_registration
order by acquisition_channel, days_since_registration;

-- расчет retention по когортам (без сегментации)
with 
-- считаем дни с момента регистрации до события
cnt_days as ( 
	select 
		u.user_id,
		u.registration_date,
		date(e.event_date) - date(u.registration_date) as days_since_registration
	from users u
	join events e
		on u.user_id = e.user_id
	where e.event_type = 'watch'
	  and date(e.event_date) - date(u.registration_date) >= 0  -- исключаем отрицательные значения
),
-- считаем количество уникальных пользователей по дню жизни
cnt_users as (
	select 
		registration_date, 
		days_since_registration, 
		count(distinct user_id) as users_count  
	from cnt_days 
	group by registration_date, days_since_registration
),
-- считаем размер каждой когорты (день регистрации)
cohorts as (
	select 
		registration_date, 
		count(distinct user_id) as cohort_size
	from users
	group by registration_date
)
-- финальный расчет retention
select 
	cu.registration_date, 
	cu.days_since_registration,
	round(100.0 * cu.users_count / c.cohort_size, 3) as retention
from cnt_users cu
join cohorts c
	on cu.registration_date = c.registration_date
where cu.days_since_registration <= 30  -- анализ первых 30 дней
order by cu.registration_date, cu.days_since_registration;

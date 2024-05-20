
--Вопрос_1 
--Какое количество менторов и менти взаимодействуют каждый месяц на нашей платформе? 
select count(distinct (mentor_id)) as cnt_mentor, count(distinct (mentee_id)) as cnt_mentee,
	to_char(session_date_time, 'YYYY-MM') as dt 
from sessions s
group by to_char(session_date_time, 'YYYY-MM')
order by to_char(session_date_time, 'YYYY-MM')


--Как меняется этот показатель из месяца в месяц?
select dt, cnt_mentor, cnt_mentee,
round((cnt_mentor - lag(cnt_mentor) over (order by dt))*1.0/lag(cnt_mentor) over (order by dt)*100,1) as dynam_cnt_mentor,
round((cnt_mentee - lag(cnt_mentee) over (order by dt))*1.0/lag(cnt_mentee) over (order by dt)*100,1) as dynam_cnt_mentee
from 
	(select dt, count(distinct(mentor_id)) as cnt_mentor, count(distinct(mentee_id)) as cnt_mentee
	from 
		(
		select mentor_id, mentee_id,
		to_char(session_date_time, 'YYYY-MM') as dt from sessions s) as temple
		group by dt
		) as temple_up
	
--Вопрос_2
-- Сколько на платформе менторов и менти, которые еще не приняли участие ни в одной встрече?
--	Учитывайте тех пользователей, кто ни разу не назначал себе встречи.
--	Почему они не принимают участие во встречах? 
--	Какие гипотезы можно проверить?

-- Сколько на платформе менти, которые еще не приняли участие ни в одной встрече?		
select count(cnt_mentee) as cnt_mentee_not
from (
	select t.user_id, count(s.session_id) as cnt_mentee
	from (
		select u.user_id , u."role" 
		from users u 
		where u."role" like 'mentee'
	) as t
left join sessions s 
on t.user_id = s.mentee_id
group by t.user_id
having count(s.session_id) = 0
order by cnt_mentee asc) as tm

--Гипотеза_1. Анализ менти, которые еще не приняли участие ни в одной встрече, по регионам
select tm.region_id, count(tm.user_id) as cnt_mentee_not, u.cnt_mentee_all, 
round(count(tm.user_id)*100.0/u.cnt_mentee_all,1) as part_mentee
from (
    select t.user_id, t.region_id, count(s.session_id) as cnt_mentee
    from (
        select * 
        from users u 
        where u."role" like 'mentee'
    ) as t
    left join sessions s 
    on t.user_id = s.mentee_id
    group by t.user_id, t.region_id
    having count(s.session_id) = 0
) as tm
join (
    select u.region_id, count(u.user_id) as cnt_mentee_all
    from users u 
    where u.role = 'mentee'
    group by u.region_id 
) as u
on u.region_id = tm.region_id
group by tm.region_id, u.cnt_mentee_all ;

--Гипотеза_2. Анализ менти, которые еще не приняли участие ни в одной встрече, по дате регистрации
select tm.dt, count(tm.user_id) as cnt_mentee_not,
		(SELECT COUNT(user_id) FROM users WHERE "role" LIKE 'mentee' 
		AND TO_CHAR(reg_date, 'YYYY-MM') = tm.dt) AS total_mentee_count,
		round (count(tm.user_id)*100.0/(SELECT COUNT(user_id) FROM users WHERE "role" LIKE 'mentee' 
		AND TO_CHAR(reg_date, 'YYYY-MM') = tm.dt),0) as Procent_mentee
from (
	select t.user_id, to_char(t.reg_date, 'YYYY-MM') as dt,   count(s.session_id) as cnt
	from (
		select * 
		from users u 
		where u."role" like 'mentee'
		) as t
	left join sessions s 
	on t.user_id = s.mentee_id
	group by t.user_id, to_char(t.reg_date, 'YYYY-MM')
	having count(s.session_id) = 0
	) as tm
group by tm.dt


--Сколько на платформе менторов, которые еще не приняли участие ни в одной встрече?
select count(tm.user_id) as cnt_mentor_not
from (
	select t.user_id, count(s.session_id) as cnt
	from (
		select u.user_id , u."role" 
		from users u 
		where u."role" like 'mentor'
		) as t
	left join sessions s 
	on t.user_id = s.mentor_id
	group by t.user_id
	order by cnt asc
	) as tm
where tm.cnt = 0

--Вопрос_3
--Сколько у каждого ментора в среднем успешных сессий в неделю по месяцам?
with t as(
	select date_trunc('week', session_date_time) as date_week, mentor_id,  count (session_id) as cnt_sess
	from sessions s 
	where session_status = 'finished'
	group by date_trunc('week', session_date_time), mentor_id 
	),
	tm as (
	select to_char(date_trunc('month', t.date_week), 'YYYY-MM') as date_month, t.mentor_id,
		avg(t.cnt_sess) as cnt_sess_week_month
	from t
	group by date_trunc('month', t.date_week), t.mentor_id
	order by date_trunc('month', t.date_week) asc
		)
select tm.date_month, round(avg(tm.cnt_sess_week_month),1) as cnt_sess_week_month
from tm
group by tm.date_month
order by tm.date_month asc

-- Расчет среднего и медианного значения успешных сессий в неделю по месяцам
with t as(
	select date_trunc('week', session_date_time) as date_week, mentor_id,  count (session_id) as cnt_sess
	from sessions s 
	where session_status = 'finished'
	group by date_trunc('week', session_date_time), mentor_id 
	),
	tm as (
	select to_char(date_trunc('month', t.date_week), 'YYYY-MM') as date_month, t.mentor_id,
		avg(t.cnt_sess) as cnt_sess_week_month
	from t
	group by date_trunc('month', t.date_week), t.mentor_id
	order by date_trunc('month', t.date_week) asc
		),
		tm_avg as (
		select tm.date_month, round(avg(tm.cnt_sess_week_month),1) as cnt_sess_week_month
		from tm
		group by tm.date_month
		order by tm.date_month asc
		)
select avg(cnt_sess_week_month), percentile_cont(0.5) within group (order by cnt_sess_week_month) as median
from tm_avg


-- Сколько у каждого конкретного ментора в среднем успешных сессий в неделю по месяцам?
with t as(
	select date_trunc('week', session_date_time) as date_week, mentor_id,  count (session_id) as cnt_sess
	from sessions s 
	where session_status = 'finished'
	group by date_trunc('week', session_date_time), mentor_id 
	)
select to_char(date_trunc('month', t.date_week), 'YYYY-MM') as date_month, t.mentor_id,
		avg(t.cnt_sess) as cnt_sess_week_month
from t
group by date_trunc('month', t.date_week), t.mentor_id
order by date_trunc('month', t.date_week) asc



--Как меняется частота встреч в неделю от месяца к месяцу?
with t as(
	select date_trunc('week', session_date_time) as date_week,  count (session_id) as cnt_sess
	from sessions s 
	where session_status = 'finished'
	group by date_trunc('week', session_date_time) 
	)
select to_char(date_trunc('month', t.date_week), 'YYYY-MM') as date_month, avg(t.cnt_sess) as avg_sess_week,
	round ((avg(t.cnt_sess)-  lag (avg(t.cnt_sess)) 
	over (order by to_char(date_trunc('month', t.date_week), 'YYYY-MM')))*1.0/
	lag(avg(t.cnt_sess)) over (order by to_char(date_trunc('month', t.date_week), 'YYYY-MM')),2)
	as change_freq_sess
from t
group by date_trunc('month', t.date_week)
order by date_trunc('month', t.date_week) asc

--Определите ТОП-5 менторов с самым большим числом сессий за последний полный месяц
with t as (
	select   rank () over (order by count (session_id) desc) as ranked, 
	count (session_id) as cnt_sess, mentor_id
	from sessions s
		where to_char(session_date_time , 'YYYY-MM') = '2022-08'
		group by mentor_id 
		order by count (session_id) desc
	)
select *
from t
where ranked <6

--Есть ли между ними что-то общее?
-- Анализ менторов по дате регистрации и региону
with t as (
	select   mentor_id, count (session_id) as cnt_sess, rank () over (order by count (session_id) desc) as ranked
	from sessions s
		where to_char(session_date_time , 'YYYY-MM') = '2022-08'
		group by mentor_id 
		order by count (session_id) desc
	)
select *
from t
join users u 
on mentor_id = user_id
where ranked <6

-- Анализ по темам сессий
with t as (
	select   mentor_id, count (session_id) as cnt_sess, rank () over (order by count (session_id) desc) as ranked
	from sessions s
		where to_char(session_date_time , 'YYYY-MM') = '2022-08'
		group by mentor_id 
		order by count (session_id) desc
	),
	tm as (
	select *
	from t
	where ranked <6
	)
select count(s.mentor_id) as cnt_domain_id , s.mentor_domain_id,
(select d.name from domain as d where s.mentor_domain_id = id)
from tm
left join sessions as s
on tm.mentor_id = s.mentor_id 
group by s.mentor_domain_id 

select *
from domain


--Вопрос_4
--Сколько времени в среднем проходит между менторскими встречами у одного менти? Ментора?
-- Сколько времени в среднем проходит между менторскими встречами у одного менти?
with t as (
	select session_date_time , mentee_id , 
	session_date_time - lag (session_date_time) over (partition by mentee_id order by  session_date_time  asc) as period_sess_mentee
	from sessions s
	where session_status = 'finished'
	),
	tm as (
		select mentee_id , avg(period_sess_mentee) as avg_mentee
		from t
		group by mentee_id
		)
select date_trunc('day',avg(avg_mentee) ) as avg_mentee_total
from tm


-- Ментора?
with t as (
	select session_date_time , mentor_id , 
	session_date_time - lag (session_date_time) over (partition by mentor_id order by  session_date_time  asc) as period_sess_mentor
	from sessions s 
	where session_status = 'finished'
	),
	tm as (
		select mentor_id , avg(period_sess_mentor) as avg_mentor
		from t
		group by mentor_id
		)
select date_trunc('day',avg(avg_mentor) ) as avg_mentor_total
from tm


--Вопрос_5 
--Сколько сессий по каждому направлению менторства в месяц обычно отменяется?
with t as 
	(
	select  count(session_id) as cnt_sess , to_char(session_date_time,'YYYY-MM') as date_month, mentor_domain_id  
	from sessions s 
	where session_status = 'canceled'
	group by to_char(session_date_time,'YYYY-MM'), mentor_domain_id
	)
select  (select  name from domain where mentor_domain_id=id),round (avg(cnt_sess),1) as avg_cancel_sess
from t
group by mentor_domain_id

-- Как меняется доля отмененных сессий помесячно?
with t as (
	select  count(session_id) as cnt_sess_cancel , to_char(session_date_time,'YYYY-MM') as date_month 
	from sessions s 
	where session_status = 'canceled'
	group by to_char(session_date_time,'YYYY-MM')
	order by to_char(session_date_time,'YYYY-MM')
	),
	tm as (
	select to_char(session_date_time,'YYYY-MM') as date_month_, count(session_id) as cnt_total
	from sessions ss
	group by to_char(session_date_time,'YYYY-MM')
	)
select date_month_,
*, 
(select cnt_sess_cancel from t where date_month=date_month_),
	round((select cnt_sess_cancel from t where date_month=date_month_)*1.0/cnt_total,2) as part_cancel
from tm
order by date_month_

--Вопрос_6
--Определите, в какой день недели последнего полного месяца прошло больше всего встреч.
with t as (
	select *, to_char(session_date_time, 'Dy') as day_week
	from sessions s 
	where session_status = 'finished'
		and to_char(session_date_time,'YYYY-MM') = '2022-08'
	), 
	tm as (
		select day_week, count (session_id) as cnt_sess_finish,
		rank () over ( order by count (session_id) desc) as ranked
		from t
		group by day_week
		order by cnt_sess_finish desc
		)
select day_week, cnt_sess_finish
from tm
where ranked = 1

--Определите самый загруженный день недели для каждого направления менторства. 
--В результатах выведите тип направления, день недели и количество встреч.
with t as (
	select *, to_char(session_date_time, 'Dy') as day_week
	from sessions s 
	where session_status = 'finished'
		and to_char(session_date_time,'YYYY-MM') = '2022-08'
	),
	tm as (
		select mentor_domain_id, day_week, count (session_id) as cnt_sess_finish, 
		rank () over (partition by mentor_domain_id 
		order by count (session_id) desc) as ranked
		from t
		group by mentor_domain_id, day_week
		order by mentor_domain_id, day_week
		)
select name, day_week, cnt_sess_finish
from tm
left join "domain" as d
on mentor_domain_id = id
where ranked =1


-- Задание 2. Определите точки роста
-- Посмотрим данные за последние 2 месяца по законченным сессиям по темам
select to_char(session_date_time, 'YYYY') as dt, 
	mentor_domain_id ,
	(select name from "domain" d where id = mentor_domain_id),
	count (session_id) as cnt_sessions
from sessions s 
where to_char(session_date_time, 'YYYY-MM') > '2022-07' 
and session_status = 'finished'
group by to_char(session_date_time, 'YYYY')
, mentor_domain_id
order by dt asc, cnt_sessions desc


-- Для анализа динамики посмотрим распределение завершенных сессий по месяцам
select 
		to_char(session_date_time, 'YYYY-MM') as dt, 
--		mentor_domain_id ,
		(select name from domain where id = mentor_domain_id),
		count (session_id) as cnt_sessions
from sessions s 
where session_status = 'finished'
group by to_char(session_date_time, 'YYYY-MM')
, mentor_domain_id
order by to_char(session_date_time, 'YYYY-MM') desc, cnt_sessions desc

-- Посмотрим данные за последние 3 месяца по темам
select to_char(session_date_time, 'YYYY-MM') as dt, 
	mentor_domain_id ,
	(select name from "domain" d where id = mentor_domain_id),
	count (session_id) as cnt_sessions
from sessions s 
where to_char(session_date_time, 'YYYY-MM') > '2022-06'
group by to_char(session_date_time, 'YYYY-MM')
, mentor_domain_id
order by dt asc, cnt_sessions desc

-- Посмотрим данные по темам за последние 3 месяца по сумме
select to_char(session_date_time, 'YYYY') as dt, 
	mentor_domain_id ,
	(select name from "domain" d where id = mentor_domain_id),
	count (session_id) as cnt_sessions
from sessions s 
where to_char(session_date_time, 'YYYY-MM') > '2022-06'
group by to_char(session_date_time, 'YYYY')
, mentor_domain_id
order by dt asc, cnt_sessions desc

-- Посмотрим данные за последние 3 месяца по законченным сессиям
select to_char(session_date_time, 'YYYY') as dt, 
	mentor_domain_id ,
	(select name from "domain" d where id = mentor_domain_id),
	count (session_id) as cnt_sessions
from sessions s 
where to_char(session_date_time, 'YYYY-MM') > '2022-06' 
and session_status = 'finished'
group by to_char(session_date_time, 'YYYY')
, mentor_domain_id
order by dt asc, cnt_sessions desc

-- Численность менти по регионам
select region_id,(select name from region r where id = region_id) as name_region,count(user_id) as cnt_mentee,
		rank () over (order by count(user_id) desc ) as ranked,
		count(user_id)*1.0/(select count (user_id) from users u where "role" = 'mentee') as procent_mentee
from users u
where "role" = 'mentee' 
group by region_id 
order by cnt_mentee desc

-- Проанализируем ранжирование за 2 месяца тем по регионам, оставим первые 3 ранга
with t as (
	select session_date_time , mentee_id, mentor_domain_id 
	from sessions s 
	where to_char(session_date_time, 'YYYY-MM') > '2022-02'
	),
	tm as (
		select *
		from t 
		left join users u  
		on mentee_id = user_id	
		),
		tm_region as (
				select (select name from domain where mentor_domain_id = id) as name_domain ,
				(select name from region where id = region_id) as name_region,
				count (user_id) as cnt_sessions,
				rank () over (partition by (select name from region where id = region_id) 
				order by count (user_id) desc)as ranked
				from tm 
				group by mentor_domain_id, region_id 
				having count (user_id) > 30
				order by name_region desc, count (user_id) desc
				)
select *
from tm_region 
where ranked <4
order by name_region, cnt_sessions desc


/* Задание 3*. Спрогнозируйте найм менторов. 
  Спрогнозируйте, сколько новых менторов нужно найти, если в следующем месяце количество
  активных менти увеличится на 500 человек.
  Учитывайте, что занятость новых менторов, будет такой же как у текущих. Объясните результат и ваше решение.*/


/* Посчитаем месячное количество завершенных сессий и количество уникальных активных пользователей по месяцам,
 активность пользователей и динамику изменения показателей */

-- Анализ динамики сессий и менти по месяцам
with t as (
		select to_char(session_date_time, 'YYYY-MM') as dt, count (session_id) as cnt_sessions,
				count (distinct(mentee_id)) as cnt_mentee,
				round(count (session_id)*1.0/count (distinct(mentee_id)), 2) as cnt_sessions_mentee
		from sessions s 
		where session_status = 'finished'
		group by to_char(session_date_time, 'YYYY-MM')
		order by dt desc
		)
select *,
		(cnt_sessions - lag(cnt_sessions) over (order by dt asc))*1.0/
		lag(cnt_sessions) over (order by dt asc) as diff_sessions,
		(cnt_mentee - lag(cnt_mentee) over (order by dt asc))*1.0/
		lag(cnt_mentee) over (order by dt asc) as diff_mentee,
		(cnt_sessions_mentee - lag(cnt_sessions_mentee) over (order by dt asc))*1.0/
		lag(cnt_sessions_mentee) over (order by dt asc) as diff_mentee_sessions
from t
order by dt desc


-- Показатели количества сессий в месяц на каждого конкретного ментора
select to_char(session_date_time, 'YYYY-MM') as dt_month, mentor_id, 
		count (distinct(mentee_id)) as cnt_mentee,
		count (session_id) as cnt_sessions
from sessions s 
where session_status = 'finished'
group by to_char(session_date_time, 'YYYY-MM'), mentor_id  
order by dt_month desc


-- Показатели среднего количества сессий в месяц на одного ментора
with t as (
		select to_char(session_date_time, 'YYYY-MM') as dt_month, 
				mentor_id, 
				count (session_id) as cnt_sessions
		from sessions s 
		where session_status = 'finished'
		group by to_char(session_date_time, 'YYYY-MM'), mentor_id  
		order by dt_month desc
		)
select dt_month, 
		avg (cnt_sessions) as avg_sessions_mentor,
		max (cnt_sessions) as max_sessions_mentor,
		(percentile_cont(0.5) within group (order by cnt_sessions))*1.0 as median
from t
group by dt_month
order by dt_month desc 

-- Динамика показателей количеств сессий, менторов, менти и загрузки по месяцам
select to_char(session_date_time, 'YYYY-MM') as dt_month,
		count (session_id) as cnt_sessions,
		count (distinct(mentor_id)) as cnt_mentor,
		count (distinct (mentee_id)) as cnt_mentee,
		count (session_id)*1.0/count (distinct(mentor_id)) as sessions_mentor,
		count (session_id)*1.0/count (distinct (mentee_id)) as sessions_mentee
from sessions s 
where session_status = 'finished'
group by to_char(session_date_time, 'YYYY-MM')
order by dt_month desc

-- Распределение завершенных сессий по месяцам и темам по месяцам
with t as (
		select to_char(session_date_time, 'YYYY-MM') as dt_month,
				mentor_domain_id ,
				count (session_id) as cnt_sessions
		from sessions s 
		where session_status = 'finished'
		group by to_char(session_date_time, 'YYYY-MM'), mentor_domain_id 
		order by dt_month desc
		)
select dt_month, 
		(select name from "domain" d where id = mentor_domain_id),
		round(cnt_sessions*100.0/(sum (cnt_sessions) over (partition by dt_month)),1) as percent_name,
		cnt_sessions
from t
order by dt_month desc, cnt_sessions desc

-- Динамика показателей по месяцам и темам по общему количеству
select to_char(session_date_time, 'YYYY-MM') as dt_month,
		mentor_domain_id ,
		count (session_id) as cnt_sessions,
		count (distinct(mentor_id)) as cnt_mentor,
		count (session_id)*1.0/count (distinct(mentor_id)) as sessions_mentor
from sessions s 
where session_status = 'finished'
group by to_char(session_date_time, 'YYYY-MM'), mentor_domain_id 
order by dt_month desc

-- Анализ специализации менторов по темам по месяцам
with t as (
		select to_char(session_date_time, 'YYYY-MM') as dt_month, 
				mentor_id,
				count(distinct(mentor_domain_id)) as cnt_domain
		from sessions s 
		where session_status = 'finished'
		group by to_char(session_date_time, 'YYYY-MM'), mentor_id
		order by dt_month desc
		)
select dt_month,
		count (mentor_id) as cnt_mentor,
		avg(cnt_domain) as avg_domain_mentor
from t
group by dt_month
order by dt_month desc


-- Анализ специализации менторов по темам по годам
with t as (
		select to_char(session_date_time, 'YYYY') as dt, 
				mentor_id,
				count(distinct(mentor_domain_id)) as cnt_domain
		from sessions s 
		where session_status = 'finished'
		group by to_char(session_date_time, 'YYYY'), mentor_id
		order by dt desc
		)
select dt,
		count (mentor_id) as cnt_mentor,
		avg(cnt_domain) as avg_domain_mentor,
		max (cnt_domain)
from t
group by dt
order by dt desc

-- Анализ загрузки менти по темам по месяцам
with t as (
		select to_char(session_date_time, 'YYYY-MM') as dt_month, 
				mentee_id,
				count(distinct(mentor_domain_id)) as cnt_domain
		from sessions s 
		where session_status = 'finished'
		group by to_char(session_date_time, 'YYYY-MM'), mentee_id
		order by dt_month desc
		)
select dt_month,
		count (mentee_id) as cnt_mentee,
		avg(cnt_domain) as avg_domain_mentor
from t
group by dt_month
order by dt_month desc


-- Анализ повторных встреч в течение месяца ментора с пользователем
select mentor_id ,mentee_id , count(session_id) as cnt_sessions
from sessions s 
where session_status = 'finished'
and to_char(session_date_time, 'YYYY-MM') = '2022-08'
group by mentor_id , mentee_id 
having count(session_id) > 1

-- Анализ повторных встреч в течение года ментора с пользователем
select mentor_id ,mentee_id , count(session_id) as cnt_sessions
from sessions s 
where session_status = 'finished'
and to_char(session_date_time, 'YYYY') = '2022'
group by mentor_id , mentee_id 
having count(session_id) > 1

-- Динамика количества сессий по дням в течение месяца, 2022-08
with t as (
		select to_char(session_date_time, 'YYYY-MM-DD') as dt_day, 
		count (session_id)as cnt_sessions
		from sessions s 
		where session_status = 'finished'
		and to_char(session_date_time, 'YYYY-MM') = '2022-08'
		group by to_char(session_date_time, 'YYYY-MM-DD')
			)
select avg(cnt_sessions),
		max(cnt_sessions),
		stddev(cnt_sessions)
from t

-- Метрики для дашборда(проверка)
-- Метрики по сессиям
select *, to_char(session_date_time, 'YYYY-MM') as dt_month
from sessions s 

select session_id, 
		session_date_time, 
		session_status, 
		"name" 
from sessions s 
join "domain" d 
on mentor_domain_id = id

-- Метрики по пользователям
-- Активные пользователи
with t as (
		select session_id, 
				session_date_time, 
				session_status, 
				"name",
				mentee_id
from sessions s 
join "domain" d 
on mentor_domain_id = id
)
select session_id, 
		session_date_time, 
		session_status, 
		"name",
		mentee_id,
		(select r.name from region r
		where r.id = region_id)
from t
left join users u 
on mentee_id = user_id

-- Пользователи и регионы
with t as (
		select user_id,
				reg_date,
				(select r.name from region r
				where r.id = region_id)
		from users u
		where "role" = 'mentee'
		),
		tm as (
				select mentee_id,
						count (session_id) as cnt_sessions
				from sessions s 
				where session_status = 'finished'
				group by mentee_id
				)
select *
from t 
left join tm
on user_id = mentee_id


select count (session_id), count(session_id) / 
			(select count(user_id)*1.0
			from users u
			where role = 'mentee'),
			count(session_id)*1.0 / count(distinct(mentee_id) ),
			 count(distinct(mentee_id)),
			 (select count(user_id)*1.0
			from users u
			where role = 'mentee')
from sessions s 
where session_status = 'finished'

-- Тайм-метрики
with t as (
		select min(session_date_time) as min_dt, mentee_id
		from sessions s 
		group by mentee_id
		),
		tm as (
				select min_dt, mentee_id, reg_date, min_dt-reg_date as diff_dt
				from t 
				left join users u 
				on user_id = mentee_id 
				)
select avg(diff_dt)
from tm










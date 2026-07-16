 drop table if exists #bdr
 drop table if exists #bdr_norm

declare @year int = 2026
declare @month int = 3

delete from [Business_Analytic].[report].[ecom_bdr]
where DATEFROMPARTS(@year, @month, 1)=date

 select a.[Признак_EBITDA], a.[Меппінг], sum(a.Glovo)+sum(a.[iPost])+sum(a.[Uklon])+sum(a.[Доставка shop.fora.ua])+
	  sum(a.[Самовывоз shop.fora.ua])+sum(a.[Рой])+sum(a.[Нова пошта]) [ON-LINE],
	  sum(a.Glovo) Glovo, sum(a.[iPost]) iPost, sum(a.[Uklon]) [Uklon], sum(a.[Доставка shop.fora.ua]) [Доставка shop.fora.ua],
	  sum(a.[Самовывоз shop.fora.ua]) [Самовывоз shop.fora.ua], sum(a.[Рой]) [Рой], sum(a.[Нова пошта]) [Нова пошта]
	  into #bdr
	  from (select Розрахунок, [Признак_EBITDA], type_vytraty, [Меппінг],sum(Glovo_final) Glovo,
	  sum([iPost_final]) [iPost], sum([Uklon_final]) [Uklon], sum([Доставка shop.fora.ua_final]) [Доставка shop.fora.ua], 
	  sum([Самовывоз shop.fora.ua_final]) [Самовывоз shop.fora.ua], sum([Рой_final]) [Рой], sum([Нова пошта_final]) [Нова пошта]
	  from [Business_Analytic].[ecom].[analyzer_mvz_final]
	  where year=@year and month=@month 
	  group by Розрахунок, [Признак_EBITDA], type_vytraty, [Меппінг]) a
	  right join business_analytic.ecom.channel_vytraty cv on cv.[Розрахунок]=a.[Розрахунок] and cv.type_statti=a.type_vytraty
	  where a.[Признак_EBITDA]='Операційний потік'
	  group by a.[Признак_EBITDA], [Меппінг]
	  order by [Меппінг]

update bdr
set bdr.меппінг='Інші Доходи'
from #bdr bdr
where bdr.меппінг='Інші - Доходи'

update bdr
set bdr.меппінг='Курєрська доставка'
from #bdr bdr
where bdr.меппінг='Кур''єрська доставка'


update bdr
set bdr.меппінг='ФОП прямий'
from #bdr bdr
where bdr.меппінг='ФОП - прямий'

select 
    b.[Признак_EBITDA],
    b.[Меппінг] as category,
    v.ChannelName as channel,
    v.Amount as [sum_bdr]
	into #bdr_norm
from #bdr b
cross apply (values
    ('Glovo', b.Glovo),
    ('iPost', b.iPost),
    ('Uklon', b.[Uklon]),
    ('Доставка', b.[Доставка shop.fora.ua]),
    ('Самовивіз', b.[Самовывоз shop.fora.ua]),
    ('Рой', b.[Рой]),
    ('Нова пошта', b.[Нова пошта])
) v (ChannelName, Amount)
where v.Amount is not null
order by b.[Меппінг], v.ChannelName	  



insert into [Business_Analytic].[report].[ecom_bdr]
select category, channel, DATEFROMPARTS(@year, @month, 1) as date, sum_bdr
from #bdr_norm


select sum(sum_bdr) from [Business_Analytic].[report].[ecom_bdr]
where date=DATEFROMPARTS(@year, @month, 1)


create database MarketingCampaignDB;
go --SSMS'e özgü bir komuttur. Önceki komutun (veritabanı oluşturma işleminin) sunucuya gönderilip tamamen bitirilmesini bekler.
use MarketingCampaignDB; --Bundan sonra yazacağın komutların varsayılan veritabanında (örneğin master) değil, yeni açtığın MarketingCampaignDB içinde çalışmasını sağlar.
go

Select count(*) as toplam_satır from stg_campaigns; --Tabloda toplam kaç satır veri var?
Select top 10 * from stg_campaigns;--Tablodaki ilk 10 satır
Select COLUMN_NAME,DATA_TYPE,CHARACTER_MAXIMUM_LENGTH from INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'stg_campaigns'; --SQL Server'ın sistem kataloğundan tablonun metaverisini çeker. Tablodaki her bir sütunun adını, veri tipini ve varsa karakter uzunluğunu listeler.

-- Önce gerçekten böyle mi diye kontrol edelim
SELECT MIN(Conversion_Rate) AS min_deger, MAX(Conversion_Rate) AS max_deger FROM stg_campaigns;

UPDATE stg_campaigns SET Conversion_Rate = Conversion_Rate / 100;

SELECT TOP 5 Conversion_Rate FROM stg_campaigns;

--Bu kod, metin olarak tutulan ve içinde ($) veya (,) gibi para birimi sembolleri bulunan maliyet verisini temizleyip, üzerinde matematiksel ve analitik işlem yapılabilecek ondalık sayı (DECIMAL) formatına dönüştürmek için kullanılır.
--ALTER TABLE, veritabanında önceden oluşturulmuş bir tablonun yapısını (iskeletini) değiştirmek için kullanılan SQL komutudur.
Alter table stg_campaigns add Acquisition_Cost_Clean decimal(10,2);
go
Update stg_campaigns set Acquisition_Cost_Clean = Cast(replace(replace(Acquisition_Cost, '$', ''), ',','') as decimal(10,2)); --tip dönüşümü yapmak için CAST kullandık.


--Bu kod genel olarak, tablodaki "30 days" veya "15 gün" gibi yanında metin bulunan süre verilerini temizleyip, içindeki sadece rakam kısmını (gün sayısını) çekerek matematiksel işlem yapılabilecek bir tamsayı (INT) haline getirmeye yarar.
Alter table stg_campaigns add Duration_Days int;
go
update stg_campaigns set Duration_Days = Cast(Left(Duration, CHARINDEX(' ', Duration)-1)as int);
go

SELECT TOP 5 Duration, Duration_Days FROM stg_campaigns;
SELECT TOP 5 Acquisition_Cost, Acquisition_Cost_Clean FROM stg_campaigns;


--Boyut tabloları oluşturmaya başlıyoruz. 4 ana boyutlu tablo oluşturucaz.
--Tablo 1: Kanal
create table dim_channel (
       channel_id int identity(1,1) primary key, --identity primary keyimizi otomatik olarak 1'den başlatıp birer birer artırır. Bizim bir daha manuel olarak girmemize gerek kalmaz.
       channel_name nvarchar(50) unique --UNIQUE kısıtlaması, kolona aynı değeri ikinci kez eklemeye çalıştığında SQL Server'ın hata vermesini ve işlemi reddetmesini sağlıyor.
);
go

insert into dim_channel (channel_name)
Select distinct Channel_Used from stg_campaigns;
go

-- Tablo 2: Kampanya Türleri 
create table dim_campaign_type (
       campaign_type_id int identity(1,1) primary key,
       campaign_type_name nvarchar(50) unique
);
go

insert into dim_campaign_type (campaign_type_name)
select distinct Campaign_Type from stg_campaigns;
go

-- Tablo 3: Müşteri Segmenti
create table dim_customer_segment (
       segment_id int identity(1,1) primary key,
       segment_name nvarchar(50) unique
);
go

insert into dim_customer_segment (segment_name)
select distinct Customer_Segment from stg_campaigns;
go

-- Tablo 4: Hedef Kitle
create table dim_target_audience(
       audience_id int identity(1,1) primary key,
       audience_name nvarchar(50) unique
);
go

insert into dim_target_audience (audience_name)
select distinct Target_Audience from stg_campaigns;
go

-- Tablo 5: Şirketler
create table dim_company (
       company_id int identity(1,1) primary key,
       company_name nvarchar(50) unique
);
go

insert into dim_company (company_name)
select distinct Company from stg_campaigns;
go

-- Tablo 6: Bölgeler
create table dim_location (
       location_id int identity(1,1) primary key,
       location_name nvarchar(50) unique
);
go

insert into dim_location (location_name)
select distinct Location from stg_campaigns;
go

EXEC sp_rename 'dim_location.locatin_name', 'location_name', 'COLUMN';
GO -- ayy yanlış yazmışım da onu düzeltmek zorunda kaldım maalesef :(. Bu kod satırı bu yüzden

-- Tablo 7: Diller
create table dim_language (
       language_id int identity(1,1) primary key,
       language_name nvarchar(50) unique
);
go



insert into dim_language (language_name)
select distinct Language from stg_campaigns;
go



SELECT * FROM dim_channel;
SELECT * FROM dim_campaign_type;
SELECT * FROM dim_customer_segment;
SELECT * FROM dim_target_audience;
SELECT * FROM dim_company;
SELECT * FROM dim_location;
SELECT * FROM dim_language;

--Fact tablosunu oluşturmaya başlıyoruz.
create table fact_campaign_performance(
       campaign_id int primary key,
       channel_id int foreign key references dim_channel(channel_id),
       campaign_type_id int foreign key references dim_campaign_type(campaign_type_id),
       segment_id int foreign key references dim_customer_segment(segment_id),
       audience_id int foreign key references dim_target_audience(audience_id),
       company_id int foreign key references dim_company(company_id),
       location_id int foreign key references dim_location(location_id),
       language_id int foreign key references dim_language(language_id),
       campaign_date DATE,
       duration_days INT,
       acquisition_cost DECIMAL(10,2),
       conversion_rate FLOAT,
       roi FLOAT,
       clicks SMALLINT,
       impressions SMALLINT,
       engagement_score TINYINT
);
go

--fact tablosunu oluşturduk ama içi boş. şimdi doldurmaya başlıyoruz.
INSERT INTO fact_campaign_performance
SELECT
    s.Campaign_ID,
    ch.channel_id,
    ct.campaign_type_id,
    seg.segment_id,
    aud.audience_id,
    co.company_id,
    loc.location_id,
    lang.language_id,
    s.Date,
    s.Duration_Days,
    s.Acquisition_Cost_Clean,
    s.Conversion_Rate,
    s.ROI,
    s.Clicks,
    s.Impressions,
    s.Engagement_Score
FROM stg_campaigns s
JOIN dim_channel ch ON s.Channel_Used = ch.channel_name
JOIN dim_campaign_type ct ON s.Campaign_Type = ct.campaign_type_name
JOIN dim_customer_segment seg ON s.Customer_Segment = seg.segment_name
JOIN dim_target_audience aud ON s.Target_Audience = aud.audience_name
JOIN dim_company co ON s.Company = co.company_name
JOIN dim_location loc ON s.Location = loc.location_name
JOIN dim_language lang ON s.Language = lang.language_name;
GO

Select count(*) as toplam from fact_campaign_performance;


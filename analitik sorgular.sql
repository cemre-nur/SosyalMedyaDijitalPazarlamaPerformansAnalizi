Use MarketingCampaignDB;
go

--1. Kanal bazlı performans özeti
select ch.channel_name,
count(*) as kampanya_sayisi, -- o kümede kaç satır var?
avg(f.roi) as ortalama_roi, --o kümedeki tüm ROI değerlerinin ortalaması
avg(f.conversion_rate) as ortalama_donusun_orani,
avg(cast(f.clicks as float) / nullif(f.impressions, 0)) as ortalama_ctr, -- nullif:İki değer birbirine eşitse NULL (yani boş/tanımsız) üretmek.
--cast: SQL'de bir verinin tipini (türünü) değiştirmeye yarar.
avg(f.acquisition_cost) as ortalama_maliyet
from fact_campaign_performance f
join dim_channel ch on f.channel_id = ch.channel_id
group by ch.channel_name --Her kanal kendi içinde ne yapmış? Kanalları gruplandırdık
order by ortalama_roi desc; -- Sonuç satırlarını ortalama_roi'ye göre büyükten küçüğe (desc) sıralar.



-- 2. Kampanya türü bazlı performans
select ct.campaign_type_name,
count(*) as kampanya_sayisi,
avg(f.roi) as ortalama_roi,
avg(f.conversion_rate) as ortalama_donusum_orani,
avg(f.engagement_score) as ortalama_etkilesim
from fact_campaign_performance f
join dim_campaign_type ct on f.campaign_type_id= ct.campaign_type_id
group by ct.campaign_type_name
order by ortalama_roi desc;


--Bu, veri setinin sentetik olup olmadığını anlamak için yazdığımız bir kod. Sentetikmiş
SELECT
    MIN(engagement_score) AS min_skor,
    MAX(engagement_score) AS max_skor,
    STDEV(engagement_score) AS standart_sapma
FROM fact_campaign_performance;


--Pencere fonksiyonları (window functions)
--Örnek: Her şirketin, kendi şehrindeki kampanyalarını ROI'ye göre sıralamak
select co.company_name,
loc.location_name,
f.campaign_id,
f.roi,
rank() over( --"Bana belirlediğim kurallara göre (OVER) bir derece/sıra (RANK) ver."
   partition by co.company_name --Partition by: SQL'e "Satırları şirket isimlerine göre ayrı odalara böl" der.
   order by f.roi desc --Her şirketin odasındaki kampanyaları ROI'si en yüksekten en düşüğe dizer.
   ) as sirket_ici_roi_sirasi
from fact_campaign_performance f
join dim_company co on f.company_id=co.company_id
join dim_location loc on f.location_id=loc.location_id
order by co.company_name,sirket_ici_roi_sirasi;

--Hangi şirketin hangi kampanyası kaçıncı sırada
Select top 20 --en fazla 20
    company_name,
    campaign_id,
    roi,
    rank() over (partition by company_name order by roi desc) as rank_sirasi, -- company_name bazında kampanyaları ROI değerine göre yüksekten düşüğe doğru sıralar.
    dense_rank() over (partition by company_name order by roi desc) as dense_rank_sirasi, -- dense row eşit değerlere aynı sırayı verir; ancak RANK() gibi numara atlamaz. Dereceleri kesintisiz bir sıra halinde (1, 2, 3...) devam ettirir.
    row_number() over (partition by company_name order by roi desc) as row_number_sirasi -- row number değerler eşit olsun ya da olmasın, hiçbir duruma bakmaksızın satırlara ardışık olarak 1, 2, 3, 4, ... şeklinde benzersiz sıra numarası verir.
from fact_campaign_performance f
join dim_company co ON f.company_id = co.company_id
order by company_name, rank_sirasi;


--Alpha Innovations Şirketinin ROI Sıralamasında 16–25 Arasındaki Kampanyalarını Listeleme
select company_name, campaign_id, roi, rank_sirasi, dense_rank_sirasi, row_number_sirasi
from ( -- from içine sorgu yazmak literatürde Derived Table (Türetilmiş Tablo) veya Inline View denir.
    select
        co.company_name,
        f.campaign_id,
        f.roi,
        rank() over (partition by co.company_name order by f.roi desc) as rank_sirasi,
        dense_rank() over (partition by co.company_name order by f.roi desc) as dense_rank_sirasi,
        row_number() over (partition by co.company_name order by f.roi desc) as row_number_sirasi
    from fact_campaign_performance f
    join dim_company co ON f.company_id = co.company_id
) t
where company_name = 'Alpha Innovations' --Tüm şirketlerin verisi yerine sadece 'Alpha Innovations' şirketine ait kampanyaları filtreler.
order by row_number_sirasi
offset 15 rows fetch next 10 rows only;
--offset 15: İlk 15 satırı atla
--fetch next 10 rows only: Atladığın noktadan sonra gelen sadece ilk 10 satırı getir.


--Alpha Innovations Şirketinde ROI Değerinin İlk Kez 799’un Altına Düştüğü Kırılma/Geçiş Satırını Bulma Analizi
select min(row_number_sirasi) as gecis_satiri
from (
    select
        co.company_name,
        f.roi,
        row_number() over (partition by co.company_name order by f.roi desc) as row_number_sirasi
    from fact_campaign_performance f
    join dim_company co ON f.company_id = co.company_id
    where co.company_name = 'Alpha Innovations'
) t
where roi < 799;


--Alpha Innovations Şirketinin ROI Sıralamasında 60–65 Arasındaki Kampanyalarını Listeleme Analizi
select company_name, campaign_id, roi, rank_sirasi, dense_rank_sirasi, row_number_sirasi
from (
    select
        co.company_name,
        f.campaign_id,
        f.roi,
        rank() over (partition by co.company_name order by f.roi desc) as rank_sirasi,
        dense_rank() over (partition by co.company_name order by f.roi desc) as dense_rank_sirasi,
        row_number() over (partition by co.company_name order by f.roi desc) as row_number_sirasi
    from fact_campaign_performance f
    join dim_company co ON f.company_id = co.company_id
) t
where company_name = 'Alpha Innovations'
order by row_number_sirasi
offset 59 rows fetch next 6 rows only;


--Kampanyaların Aylık Ortalama ROI Performansını ve Bir Önceki Aya Göre Değişimini (MoM) Hesaplama Analizi
select
    yil, ay, ortalama_roi,
    --LAG, geçmiş satırdaki veriyi bugünkü satırın yanına getirip kıyaslama veya fark alma yapabilmeni sağlayan bir araçtır.
    lag(ortalama_roi) over (order by yil, ay) AS onceki_ay_roi,
    ortalama_roi - lag(ortalama_roi) over (order by yil, ay) AS roi_degisimi
from (
    select
        year(campaign_date) as yil,
        month(campaign_date) as ay,
        avg(roi) AS ortalama_roi
    from fact_campaign_performance
    group by year(campaign_date), month(campaign_date)
) aylik_ozet
order by yil, ay;


--Özet Kural
--Tekil satır numarası istiyorsanız: ROW_NUMBER()
--Eşitler aynı kalsın, arkadan gelen toplam satır sayısına göre atlasın: RANK()
--Eşitler aynı kalsın, arkadan gelen kesintisiz devam etsin: DENSE_RANK()
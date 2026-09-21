# 📊 Sosyal Medya & Pazarlama Performans Analitiği (End-to-End BI & Data Audit)

Bu proje; 200.000 satırlık pazarlama kampanya verisinin ham durumdan alınarak **ilişkisel veri modeline (Star Schema)** dönüştürülmesini, **ileri düzey T-SQL** ile analitik sorgulanmasını, **Python** ile istatistiksel dağılım ve sentetik veri testlerinden geçirilmesini ve **Power BI** üzerinde interaktif bir karar destek dashboard'una dönüştürülmesini kapsayan uçtan uca bir İş Zekası (BI) çalışmasıdır.

---

## 🎯 Projenin Öne Çıkan Özellikleri

* **Kurumsal Veri Ambarı Mimarisi:** Ham verinin staging katmanından 7 Boyut (Dimension) ve 1 Olgu (Fact) tablosundan oluşan Yıldız Şema mimarisine taşınması.
* **İleri Seviye T-SQL Analitiği:** `RANK()`, `DENSE_RANK()`, `ROW_NUMBER()`, `LAG()` pencere fonksiyonları ve `NULLIF` güvenli bölme pratikleri.
* **Analitik Şüphecilik & Veri Denetimi (Data Audit):** Sentetik verinin dar bant varyansının SQL, Python (Boxplot) ve tek yönlü ANOVA testi ($p > 0.05$) ile tespit edilip belgelenmesi.
* **Modern UI/UX Dashboard:** Fütüristik tema üzerinde hizalanmış KPI kartları, dinamik dilimleyiciler ve istatistiksel dipnotlarla zenginleştirilmiş 3 sayfalık rapor.

---

## 🖥️ Power BI Dashboard Görünümü

| 1. Genel Bakış (Overview) | 2. Kanal & Kampanya Türü Analizi |
| :---: | :---: |
| <img width="1197" height="676" alt="Ekran görüntüsü 2026-09-21 204539" src="https://github.com/user-attachments/assets/61dfa4ad-1af3-4bb4-8ab5-18312d8fae1b" /> | | <img width="1196" height="668" alt="Ekran görüntüsü 2026-09-21 204550" src="https://github.com/user-attachments/assets/f919f0e0-4c14-4cd2-9f3d-4246c241149a" /> |

### 3. Zaman Bazlı Performans Trendleri

<img width="1197" height="667" alt="Ekran görüntüsü 2026-09-21 204606" src="https://github.com/user-attachments/assets/fa4acc94-95ba-4624-b5e6-b3740d9a658a" />

---

## 🔬 Veri Kalitesi Denetimi & İstatistiksel Doğrulama (Python & EDA)

Proje sürecinde kanal, segment ve kampanya türü kırılımları incelendiğinde; ortalama ROI (~%453–%458), dönüşüm oranı (~%7.36) ve etkileşim skorlarının dar bir bantta homojen dağıldığı fark edilmiştir. Bu durum verinin ham haliyle kabul edilmeyip istatistiksel testlere tabi tutulmasını sağlamıştır.

### 📈 Yapılan Testler ve Bulgular:

1. **Kutu Grafiği (Boxplot) Dağılımı:**
   * Python (Seaborn/Matplotlib) ile çizilen kutu grafiğinde tüm kanalların minimum (~20), medyan (~460), kartiller arası açıklık (IQR) ve maksimum (~800) sınırlarının milimetrik olarak örtüştüğü gözlemlenmiştir. Detaylar `Sosyal Medya Pazarlama Analitiği Projesi .ipynb` notebook dosyasında yer almaktadır.
2. **Hipotez Testi (One-Way ANOVA):**
   * Zaman trendleri üzerinde yapılan tek yönlü varyans analizi sonucunda **$F = 1.1484, p = 0.3180$** bulunmuştur.
   * **Sonuç ($p > 0.05$):** Aylar arasındaki ROI farkı istatistiksel olarak anlamsızdır; dalgalanmalar tamamen rassaldır.
3. **Analitik Yaklaşım & İş Etiği:**
   * Gerçek iş senaryolarında veri doğrulama yapılmadan karar vericilere *"Instagram en yüksek getiriyi sağladı, bütçeyi buraya aktaralım"* gibi yanıltıcı öneriler sunulmasının önüne geçilmiş; bu bulgu rapor arayüzüne şeffaf bir dipnot olarak eklenmiştir.

---

## 🗄️ Veri Ambarı & Yıldız Şema (Star Schema) Tasarımı

Ham veri, doğrudan analiz edilmek yerine normalizasyon adımlarından geçirilerek kurumsal bir veri modeli kurgulanmıştır:

* **Staging (`stg_campaigns`):** Ham veri içeri alınmış; sembol içeren maliyetler (`$`, `,`) `DECIMAL(10,2)` tipine, metin formatındaki süreler (`"30 days"`) sayısal güne dönüştürülmüştür.
* **Boyut Tabloları (Dimension Tables):** `dim_channel`, `dim_campaign_type`, `dim_company`, `dim_customer_segment`, `dim_target_audience`, `dim_location`, `dim_language` (IDENTITY PK ve UNIQUE kısıtlamalarıyla).
* **Olgu Tablosu (Fact Table):** `fact_campaign_performance` (Boyut tablolarına FK referansları, metrikler ve tarih alanı).

---

## 💻 Öne Çıkan SQL Sorguları

### 1. Kanal Bazlı Performans Özeti ve Güvenli CTR Hesabı

```sql
SELECT 
    ch.channel_name,
    COUNT(*) AS kampanya_sayisi,
    AVG(f.roi) AS ortalama_roi,
    AVG(f.conversion_rate) AS ortalama_donusum_orani,
    -- Sıfıra bölme ve tam sayı yuvarlama hatalarını önleme:
    AVG(CAST(f.clicks AS FLOAT) / NULLIF(f.impressions, 0)) AS ortalama_ctr,
    AVG(f.acquisition_cost) AS ortalama_maliyet
FROM fact_campaign_performance f
JOIN dim_channel ch ON f.channel_id = ch.channel_id
GROUP BY ch.channel_name
ORDER BY ortalama_roi DESC;

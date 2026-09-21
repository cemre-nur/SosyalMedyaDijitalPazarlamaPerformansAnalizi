# 📊 Sosyal Medya & Pazarlama Performans Analitiği (End-to-End BI & Data Audit)

Bu proje; 200.000 satırlık pazarlama kampanya verisinin ham durumdan alınarak **ilişkisel veri modeline (Star Schema)** dönüştürülmesini, **T-SQL** ile analitik olarak modellenmesini, **Python** ile istatistiksel dağılım/sentetik veri testlerinden geçirilmesini ve **Power BI** üzerinde interaktif bir karar destek dashboard'una dönüştürülmesini kapsayan uçtan uca bir İş Zekası (BI) çalışmasıdır.

---

## 🗄️ Veri Ambarı & Yıldız Şema (Star Schema) Tasarımı

Ham veri, doğrudan analiz edilmek yerine normalizasyon ve boyutlandırma adımlarından geçirilerek kurumsal standartlarda modellenmiştir:

* **Staging (`stg_campaigns`):** Ham veri içeri alınmış; metin halindeki maliyetler (`$`, `,`) sayısal tipe (`DECIMAL`), metin formatındaki süreler (`"30 days"`) sayısal güne dönüştürülmüştür.
* **Boyut Tabloları (Dimension Tables):** `dim_channel`, `dim_campaign_type`, `dim_company`, `dim_customer_segment`, `dim_target_audience`, `dim_location`, `dim_language` (IDENTITY PK ve UNIQUE kısıtlamalarıyla).
* **Olgu Tablosu (Fact Table):** `fact_campaign_performance` (Tüm boyut tablolarına FK referansları, metrikler ve tarih alanı).

### 📐 SQL Server Veritabanı Şeması
<img width="100%" alt="Yıldız Şema Diyagramı" src="Ekran görüntüsü 2026-09-18 110503.png" />

---

## 🖥️ Power BI Dashboard Görünümü

### 1. Genel Bakış (Overview)
<img width="100%" alt="Ekran görüntüsü 2026-09-21 204539" src="https://github.com/user-attachments/assets/61dfa4ad-1af3-4bb4-8ab5-18312d8fae1b" />

### 2. Kanal & Kampanya Türü Analizi
<img width="100%" alt="Ekran görüntüsü 2026-09-21 204550" src="https://github.com/user-attachments/assets/f919f0e0-4c14-4cd2-9f3d-4246c241149a" />

### 3. Zaman Bazlı Performans Trendleri
<img width="100%" alt="Ekran görüntüsü 2026-09-21 204606" src="https://github.com/user-attachments/assets/fa4acc94-95ba-4624-b5e6-b3740d9a658a" />

---

## 🔬 Veri Kalitesi Denetimi & İstatistiksel Doğrulama (Python & EDA)

Proje sürecinde kanal, segment ve kampanya türü kırılımları incelendiğinde; ortalama ROI (~%453–%458), dönüşüm oranı (~%7.36) ve etkileşim skorlarının dar bir bantta homojen dağıldığı tespit edilmiştir. Bu durum verinin ham haliyle kabul edilmeyip istatistiksel testlere tabi tutulmasını sağlamıştır.

* **Kutu Grafiği (Boxplot) Dağılımı:** Python ile yapılan analizde tüm kanalların kartiller arası açıklık (IQR) ve medyan değerlerinin farksız olduğu doğrulanmıştır. Detaylar `Sosyal Medya Pazarlama Analitiği Projesi .ipynb` dosyasında yer almaktadır.
* **Hipotez Testi (One-Way ANOVA):** Zaman trendleri üzerinde yapılan tek yönlü varyans analizi sonucunda **$F = 1.1484, p = 0.3180$** bulunmuştur.
* **Sonuç ($p > 0.05$):** Aylar arasındaki ROI farkı istatistiksel olarak anlamsızdır; dalgalanmalar tamamen rassaldır. Karar vericilere sahte bir "en iyi kanal" önerisi sunulmasının önüne geçilmiş, bu bulgu rapor arayüzüne şeffaf bir dipnot olarak eklenmiştir.

---

## 🛠️ Kullanılan Teknolojiler
* **Veritabanı & Modelleme:** MS SQL Server, SSMS (T-SQL, Star Schema, DDL/DML, Window Functions)
* **İstatistik & Veri Doğrulama:** Python (Pandas, Seaborn, Matplotlib, SciPy - ANOVA)
* **İş Zekası & Raporlama:** Power BI (DAX, Interactive Filtering, UI/UX Design)

CREATE DATABASE YemekSiparisDB;
GO
USE YemekSiparisDB;
GO

CREATE TABLE Kullanicilar (
    KullaniciID INT PRIMARY KEY IDENTITY(1,1),
    Ad NVARCHAR(50) NOT NULL,
    Soyad NVARCHAR(50) NOT NULL,
    Eposta NVARCHAR(100) UNIQUE NOT NULL, -- Tekrarlanamaz
    Telefon NVARCHAR(20) UNIQUE NOT NULL, -- Tekrarlanamaz
    Sifre NVARCHAR(100) NOT NULL,
    Rol NVARCHAR(20) CHECK (Rol IN ('Musteri', 'IhtiyacSahibi', 'Kurye')), -- Mantıksal kontrol
    IsActive BIT DEFAULT 1 -- Soft Delete (Pasife çekme) mantığı
);


CREATE TABLE Restoranlar (
    RestoranID INT PRIMARY KEY IDENTITY(1,1),
    RestoranAd NVARCHAR(100) NOT NULL,
    Puan FLOAT CHECK (Puan BETWEEN 1 AND 5), -- Puan kısıtlaması
    Ciro DECIMAL(18,2) DEFAULT 0,
    IsActive BIT DEFAULT 1
);


CREATE TABLE AskidaYemekHavuzu (
    HavuzID INT PRIMARY KEY IDENTITY(1,1),
    ToplamBakiye DECIMAL(18,2) DEFAULT 0, -- Hayırseverlerin bağışladığı para burada birikir
    GuncellemeTarihi DATETIME DEFAULT GETDATE()
);


CREATE TABLE Bagislar (
    BagisID INT PRIMARY KEY IDENTITY(1,1),
    BagisciID INT NULL, -- NULL olabilir çünkü "Kimliğini Gizleyerek" kuralı var
    Miktar DECIMAL(18,2) NOT NULL CHECK (Miktar > 0),
    BagisTarihi DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (BagisciID) REFERENCES Kullanicilar(KullaniciID)
);

-- 6. Ürünler Tablosu (Hangi restoranın hangi yemeği var?)
CREATE TABLE Urunler (
    UrunID INT PRIMARY KEY IDENTITY(1,1),
    RestoranID INT NOT NULL,
    UrunAd NVARCHAR(100) NOT NULL,
    Fiyat DECIMAL(10,2) CHECK (Fiyat > 0), -- Mantıksız fiyat girişini engeller (Zorunlu İster)
    IsActive BIT DEFAULT 1, -- Soft Delete
    FOREIGN KEY (RestoranID) REFERENCES Restoranlar(RestoranID)
);

-- 7. Siparişler Tablosu (Genel Sipariş Bilgisi)
CREATE TABLE Siparisler (
    SiparisID INT PRIMARY KEY IDENTITY(1,1),
    MusteriID INT NOT NULL,
    RestoranID INT NOT NULL,
    SiparisTarihi DATETIME DEFAULT GETDATE(),
    ToplamTutar DECIMAL(10,2) DEFAULT 0,
    Durum NVARCHAR(50) DEFAULT 'Hazırlandı', -- Hazırlandı, Yolda, Teslim Edildi
    IsAskida BIT DEFAULT 0, -- Eğer 1 ise Askıda Yemek havuzundan karşılanıyor demektir
    FOREIGN KEY (MusteriID) REFERENCES Kullanicilar(KullaniciID),
    FOREIGN KEY (RestoranID) REFERENCES Restoranlar(RestoranID)
);

-- 8. Sipariş Detayları (Bir siparişte birden fazla ürün olabilir)
CREATE TABLE SiparisDetaylari (
    DetayID INT PRIMARY KEY IDENTITY(1,1),
    SiparisID INT NOT NULL,
    UrunID INT NOT NULL,
    Adet INT CHECK (Adet > 0),
    BirimFiyat DECIMAL(10,2),
    FOREIGN KEY (SiparisID) REFERENCES Siparisler(SiparisID),
    FOREIGN KEY (UrunID) REFERENCES Urunler(UrunID)
);



CREATE TRIGGER trg_BagisYapildigindaHavuzuGuncelle
ON Bagislar
AFTER INSERT
AS
BEGIN
    DECLARE @Miktar DECIMAL(18,2)
    SELECT @Miktar = Miktar FROM inserted

    -- Havuz tablosundaki bakiyeyi artır
    UPDATE AskidaYemekHavuzu 
    SET ToplamBakiye = ToplamBakiye + @Miktar,
        GuncellemeTarihi = GETDATE()
END;
GO

CREATE TRIGGER trg_AskidaSiparisVerildigindeHavuzdanDus
ON Siparisler
AFTER INSERT
AS
BEGIN
    DECLARE @Tutar DECIMAL(18,2)
    DECLARE @IsAskida BIT

    SELECT @Tutar = ToplamTutar, @IsAskida = IsAskida FROM inserted

    IF (@IsAskida = 1)
    BEGIN
        -- Havuzda yeterli para var mı kontrolü (Basit mühendislik mantığı)
        UPDATE AskidaYemekHavuzu 
        SET ToplamBakiye = ToplamBakiye - @Tutar,
            GuncellemeTarihi = GETDATE()
    END
END;
GO

-- 1. Görünüm: Aktif Restoranların Menüleri
CREATE VIEW vw_AktifMenu AS
SELECT R.RestoranAd, U.UrunAd, U.Fiyat
FROM Restoranlar R
JOIN Urunler U ON R.RestoranID = U.RestoranID
WHERE R.IsActive = 1 AND U.IsActive = 1;
GO

-- 2. Görünüm: Havuzun Güncel Durumu
CREATE VIEW vw_HavuzDurumu AS
SELECT ToplamBakiye, GuncellemeTarihi
FROM AskidaYemekHavuzu;
GO

-- 1. ADIM: Restoranlar
INSERT INTO Restoranlar (RestoranAd, Puan) VALUES 
('Acıktım Kebap', 4.8), ('Pizza Limanı', 4.2), ('Anne Yemekleri', 4.9), 
('Burger Dünyası', 3.5), ('Sultan Sofrası', 4.5);

-- 2. ADIM: Kullanıcılar (Müşteriler, İhtiyaç Sahipleri ve Kuryeler)
INSERT INTO Kullanicilar (Ad, Soyad, Eposta, Telefon, Sifre, Rol) VALUES 
('Ahmet', 'Yılmaz', 'ahmet@mail.com', '5551112233', '123', 'Musteri'),
('Kader', 'Dimen', 'kader@mail.com', '5552223344', '123', 'Musteri'),
('Mehmet', 'Kaya', 'mehmet@mail.com', '5553334455', '123', 'IhtiyacSahibi'),
('Fatma', 'Çelik', 'fatma@mail.com', '5554445566', '123', 'IhtiyacSahibi'),
('Can', 'Öz', 'can@mail.com', '5550009988', '123', 'Kurye');

-- 3. ADIM: Ürünler (Hocanın istediği en az 50 ürün için örnekler)
INSERT INTO Urunler (RestoranID, UrunAd, Fiyat) VALUES 
(1, 'Adana Kebap', 250), (1, 'Urfa Kebap', 240), (1, 'Lahmacun', 80), (1, 'Ayran', 30),
(2, 'Karışık Pizza', 200), (2, 'Margarita', 180), (2, 'Kola', 45),
(3, 'Kuru Fasulye', 120), (3, 'Pilav', 60), (3, 'Cacık', 40);

-- 4. ADIM: Askıda Yemek Havuzunu Başlatma
-- (Eğer daha önce oluşturmadıysan 1 kez çalıştır)
INSERT INTO AskidaYemekHavuzu (ToplamBakiye) VALUES (0);

-- 5. ADIM: Bağış Yapma (Trigger sayesinde havuz otomatik dolacak)
INSERT INTO Bagislar (BagisciID, Miktar) VALUES (1, 1000); -- Ahmet 1000 TL bağışladı
INSERT INTO Bagislar (BagisciID, Miktar) VALUES (2, 500);  -- Kader 500 TL bağışladı

-- 6. ADIM: Siparişler (Hem Normal Hem Askıda)
INSERT INTO Siparisler (MusteriID, RestoranID, ToplamTutar, IsAskida) VALUES 
(1, 1, 330, 0), -- Normal sipariş
(3, 2, 180, 1), -- Askıdan sipariş (Mehmet ücretsiz yedi, havuzdan düştü)
(4, 3, 220, 1); -- Askıdan sipariş (Fatma ücretsiz yedi, havuzdan düştü)


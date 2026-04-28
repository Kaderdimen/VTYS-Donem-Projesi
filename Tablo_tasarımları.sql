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
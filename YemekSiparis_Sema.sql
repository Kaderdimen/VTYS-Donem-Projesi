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
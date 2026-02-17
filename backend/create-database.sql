-- ============================================
-- Script de création complète de la base de données CheckFilling
-- Date: 2026-02-17
-- ============================================

-- Créer la base de données si elle n'existe pas
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'CheckFilling')
BEGIN
    CREATE DATABASE CheckFilling;
    PRINT 'Base de données CheckFilling créée.';
END
ELSE
BEGIN
    PRINT 'Base de données CheckFilling existe déjà.';
END
GO

USE CheckFilling;
GO

-- ============================================
-- Créer la table __EFMigrationsHistory
-- ============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = '__EFMigrationsHistory')
BEGIN
    CREATE TABLE [__EFMigrationsHistory] (
        [MigrationId] nvarchar(150) NOT NULL,
        [ProductVersion] nvarchar(32) NOT NULL,
        CONSTRAINT [PK___EFMigrationsHistory] PRIMARY KEY ([MigrationId])
    );
    PRINT 'Table __EFMigrationsHistory créée.';
END
GO

-- ============================================
-- Créer la table Regions
-- ============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Regions')
BEGIN
    CREATE TABLE [Regions] (
        [Id] int NOT NULL IDENTITY,
        [Name] nvarchar(max) NOT NULL,
        [Cities] nvarchar(max) NOT NULL,
        [CreatedAt] datetime2 NOT NULL,
        CONSTRAINT [PK_Regions] PRIMARY KEY ([Id])
    );
    PRINT 'Table Regions créée.';
END
GO

-- ============================================
-- Créer la table Banks
-- ============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Banks')
BEGIN
    CREATE TABLE [Banks] (
        [Id] int NOT NULL IDENTITY,
        [Name] nvarchar(max) NOT NULL,
        [Code] nvarchar(450) NOT NULL,
        [PdfUrl] nvarchar(max) NULL,
        [PositionsJson] nvarchar(max) NOT NULL,
        [CreatedAt] datetime2 NOT NULL,
        CONSTRAINT [PK_Banks] PRIMARY KEY ([Id])
    );
    
    CREATE UNIQUE INDEX [IX_Banks_Code] ON [Banks] ([Code]);
    PRINT 'Table Banks créée.';
END
GO

-- ============================================
-- Créer la table Users
-- ============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Users')
BEGIN
    CREATE TABLE [Users] (
        [Id] int NOT NULL IDENTITY,
        [FirstName] nvarchar(max) NOT NULL,
        [LastName] nvarchar(max) NOT NULL,
        [Email] nvarchar(450) NOT NULL,
        [PasswordHash] nvarchar(max) NOT NULL,
        [PhoneNumber] nvarchar(max) NOT NULL,
        [Direction] nvarchar(max) NOT NULL,
        [Role] nvarchar(450) NOT NULL,
        [RegionId] int NULL,
        [CreatedAt] datetime2 NOT NULL,
        CONSTRAINT [PK_Users] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Users_Regions_RegionId] FOREIGN KEY ([RegionId]) REFERENCES [Regions] ([Id])
    );
    
    CREATE UNIQUE INDEX [IX_Users_Email] ON [Users] ([Email]);
    CREATE INDEX [IX_Users_RegionId] ON [Users] ([RegionId]);
    CREATE INDEX [IX_Users_Role] ON [Users] ([Role]);
    PRINT 'Table Users créée.';
END
GO

-- ============================================
-- Créer la table AuditLogs
-- ============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AuditLogs')
BEGIN
    CREATE TABLE [AuditLogs] (
        [Id] int NOT NULL IDENTITY,
        [UserId] int NOT NULL,
        [Action] nvarchar(450) NOT NULL,
        [EntityType] nvarchar(max) NOT NULL,
        [EntityId] int NULL,
        [Details] nvarchar(max) NOT NULL,
        [CreatedAt] datetime2 NOT NULL,
        CONSTRAINT [PK_AuditLogs] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_AuditLogs_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [Users] ([Id]) ON DELETE CASCADE
    );
    
    CREATE INDEX [IX_AuditLogs_Action] ON [AuditLogs] ([Action]);
    CREATE INDEX [IX_AuditLogs_CreatedAt] ON [AuditLogs] ([CreatedAt]);
    CREATE INDEX [IX_AuditLogs_UserId] ON [AuditLogs] ([UserId]);
    PRINT 'Table AuditLogs créée.';
END
GO

-- ============================================
-- Créer la table Checkbooks
-- ============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Checkbooks')
BEGIN
    CREATE TABLE [Checkbooks] (
        [Id] int NOT NULL IDENTITY,
        [Number] nvarchar(450) NOT NULL,
        [FirstCheckNumber] int NOT NULL,
        [LastCheckNumber] int NOT NULL,
        [BankId] int NOT NULL,
        [CreatedAt] datetime2 NOT NULL,
        CONSTRAINT [PK_Checkbooks] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Checkbooks_Banks_BankId] FOREIGN KEY ([BankId]) REFERENCES [Banks] ([Id]) ON DELETE CASCADE
    );
    
    CREATE INDEX [IX_Checkbooks_BankId] ON [Checkbooks] ([BankId]);
    CREATE UNIQUE INDEX [IX_Checkbooks_Number] ON [Checkbooks] ([Number]);
    PRINT 'Table Checkbooks créée.';
END
GO

-- ============================================
-- Créer la table Suppliers
-- ============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Suppliers')
BEGIN
    CREATE TABLE [Suppliers] (
        [Id] int NOT NULL IDENTITY,
        [Name] nvarchar(max) NOT NULL,
        [CreatedAt] datetime2 NOT NULL,
        CONSTRAINT [PK_Suppliers] PRIMARY KEY ([Id])
    );
    PRINT 'Table Suppliers créée.';
END
GO

-- ============================================
-- Créer la table Checks
-- ============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Checks')
BEGIN
    CREATE TABLE [Checks] (
        [Id] int NOT NULL IDENTITY,
        [UserId] int NOT NULL,
        [CheckNumber] nvarchar(max) NOT NULL,
        [CheckbookId] int NULL,
        [BankName] nvarchar(max) NOT NULL,
        [Amount] decimal(18,2) NOT NULL,
        [AmountInWords] nvarchar(max) NOT NULL,
        [Beneficiary] nvarchar(max) NOT NULL,
        [City] nvarchar(max) NOT NULL,
        [Date] datetime2 NOT NULL,
        [PrintedAt] datetime2 NOT NULL,
        CONSTRAINT [PK_Checks] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Checks_Checkbooks_CheckbookId] FOREIGN KEY ([CheckbookId]) REFERENCES [Checkbooks] ([Id]) ON DELETE SET NULL,
        CONSTRAINT [FK_Checks_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [Users] ([Id]) ON DELETE CASCADE
    );
    
    CREATE INDEX [IX_Checks_CheckbookId] ON [Checks] ([CheckbookId]);
    CREATE INDEX [IX_Checks_PrintedAt] ON [Checks] ([PrintedAt]);
    CREATE INDEX [IX_Checks_UserId] ON [Checks] ([UserId]);
    PRINT 'Table Checks créée.';
END
GO

-- ============================================
-- Créer la table UserBankCalibrations
-- ============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'UserBankCalibrations')
BEGIN
    CREATE TABLE [UserBankCalibrations] (
        [Id] int NOT NULL IDENTITY,
        [UserId] int NOT NULL,
        [BankId] int NOT NULL,
        [PositionsJson] nvarchar(max) NOT NULL,
        [CreatedAt] datetime2 NOT NULL,
        [UpdatedAt] datetime2 NOT NULL,
        CONSTRAINT [PK_UserBankCalibrations] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_UserBankCalibrations_Banks_BankId] FOREIGN KEY ([BankId]) REFERENCES [Banks] ([Id]) ON DELETE CASCADE,
        CONSTRAINT [FK_UserBankCalibrations_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [Users] ([Id]) ON DELETE CASCADE
    );
    
    CREATE INDEX [IX_UserBankCalibrations_BankId] ON [UserBankCalibrations] ([BankId]);
    CREATE UNIQUE INDEX [IX_UserBankCalibrations_UserId_BankId] ON [UserBankCalibrations] ([UserId], [BankId]);
    PRINT 'Table UserBankCalibrations créée.';
END
GO

-- ============================================
-- Insérer les données initiales - Users
-- ============================================
IF NOT EXISTS (SELECT * FROM Users WHERE Email = 'test@gmail.com')
BEGIN
    SET IDENTITY_INSERT [Users] ON;
    INSERT INTO [Users] ([Id], [FirstName], [LastName], [Email], [PasswordHash], [PhoneNumber], [Direction], [Role], [RegionId], [CreatedAt])
    VALUES 
    (1, N'Test', N'User', N'test@gmail.com', N'$2a$11$3f1y0aSd2iVFhKoWi60oVuwBiNQb913o5x94e0pYXB9eaqvHXW1By', N'0661000000', N'Test', N'admin', NULL, '2025-01-01T00:00:00'),
    (2, N'Admin', N'Test', N'admin@test.com', N'$2a$11$3f1y0aSd2iVFhKoWi60oVuwBiNQb913o5x94e0pYXB9eaqvHXW1By', N'0661999999', N'Administration', N'admin', NULL, '2025-01-01T00:00:00'),
    (3, N'Admin', N'Gmail', N'admin@gmail.com', N'$2a$11$3f1y0aSd2iVFhKoWi60oVuwBiNQb913o5x94e0pYXB9eaqvHXW1By', N'0661999998', N'Administration', N'admin', NULL, '2025-01-01T00:00:00');
    SET IDENTITY_INSERT [Users] OFF;
    PRINT 'Utilisateurs initiaux créés. (Mot de passe par défaut: 123456789)';
END
GO

-- ============================================
-- Insérer les migrations dans l'historique
-- ============================================
IF NOT EXISTS (SELECT * FROM __EFMigrationsHistory WHERE MigrationId = '20260115125651_InitialCreate')
BEGIN
    INSERT INTO __EFMigrationsHistory (MigrationId, ProductVersion) VALUES ('20260115125651_InitialCreate', '8.0.11');
END

IF NOT EXISTS (SELECT * FROM __EFMigrationsHistory WHERE MigrationId = '20260217100000_AddUserBankCalibrationTable')
BEGIN
    INSERT INTO __EFMigrationsHistory (MigrationId, ProductVersion) VALUES ('20260217100000_AddUserBankCalibrationTable', '8.0.11');
END
GO

-- ============================================
PRINT '';
PRINT '========================================';
PRINT 'Base de données créée avec succès!';
PRINT '========================================';
PRINT 'Utilisateurs par défaut:';
PRINT '  - test@gmail.com (admin)';
PRINT '  - admin@test.com (admin)';
PRINT '  - admin@gmail.com (admin)';
PRINT 'Mot de passe pour tous: 123456789';
PRINT '========================================';
GO

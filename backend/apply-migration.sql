-- Drop CalibrationsJson column from Users table
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'CalibrationsJson')
BEGIN
    ALTER TABLE [Users] DROP COLUMN [CalibrationsJson];
END
GO

-- Create UserBankCalibrations table
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
END
GO

-- Insert migration history record
IF NOT EXISTS (SELECT * FROM [__EFMigrationsHistory] WHERE [MigrationId] = N'20260217100000_AddUserBankCalibrationTable')
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260217100000_AddUserBankCalibrationTable', N'8.0.11');
END
GO

PRINT 'Migration applied successfully!'

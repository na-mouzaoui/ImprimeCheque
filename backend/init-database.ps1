# Script d'initialisation de la base de données
# À exécuter sur la VM en tant qu'administrateur

Write-Host "=== INITIALISATION DE LA BASE DE DONNÉES ===" -ForegroundColor Cyan
Write-Host ""

# 1. Vérifier si SQL Server est installé
Write-Host "1. Vérification de SQL Server..." -ForegroundColor Yellow
$sqlService = Get-Service -Name "MSSQLSERVER" -ErrorAction SilentlyContinue

if ($sqlService) {
    Write-Host "   ✓ SQL Server trouvé (État: $($sqlService.Status))" -ForegroundColor Green
    
    if ($sqlService.Status -ne "Running") {
        Write-Host "   ! Démarrage de SQL Server..." -ForegroundColor Yellow
        Start-Service -Name "MSSQLSERVER"
        Write-Host "   ✓ SQL Server démarré" -ForegroundColor Green
    }
} else {
    Write-Host "   ✗ SQL Server non trouvé!" -ForegroundColor Red
    Write-Host ""
    Write-Host "   Installez SQL Server Express :" -ForegroundColor Yellow
    Write-Host "   https://www.microsoft.com/fr-fr/sql-server/sql-server-downloads" -ForegroundColor White
    Write-Host ""
    Write-Host "   Ou utilisez LocalDB :" -ForegroundColor Yellow
    Write-Host "   Changez la chaîne de connexion dans appsettings.json vers :" -ForegroundColor White
    Write-Host '   "Server=(localdb)\\mssqllocaldb;Database=CheckFilling;Trusted_Connection=True;"' -ForegroundColor Gray
    exit 1
}

# 2. Vérifier le dossier publish
Write-Host "`n2. Vérification du dossier publish..." -ForegroundColor Yellow
$publishPath = "C:\publish"

if (Test-Path $publishPath) {
    Write-Host "   ✓ Dossier trouvé: $publishPath" -ForegroundColor Green
} else {
    Write-Host "   ✗ Dossier non trouvé: $publishPath" -ForegroundColor Red
    Write-Host "   Veuillez publier le backend d'abord!" -ForegroundColor Yellow
    exit 1
}

# 3. Créer le dossier uploads s'il n'existe pas
Write-Host "`n3. Création du dossier uploads..." -ForegroundColor Yellow
$uploadsPath = Join-Path $publishPath "wwwroot\uploads"

if (!(Test-Path $uploadsPath)) {
    New-Item -Path $uploadsPath -ItemType Directory -Force | Out-Null
    Write-Host "   ✓ Dossier créé: $uploadsPath" -ForegroundColor Green
} else {
    Write-Host "   ✓ Dossier existe déjà: $uploadsPath" -ForegroundColor Green
}

# 4. Tester la connexion à la base de données
Write-Host "`n4. Test de connexion à SQL Server..." -ForegroundColor Yellow

try {
    $sqlCmd = "SELECT @@VERSION"
    $result = Invoke-Sqlcmd -Query $sqlCmd -ServerInstance "localhost" -ErrorAction Stop
    Write-Host "   ✓ Connexion réussie" -ForegroundColor Green
    Write-Host "   Version: $($result.Column1.Split("`n")[0])" -ForegroundColor White
} catch {
    Write-Host "   ✗ Erreur de connexion: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "   Vérifiez que :" -ForegroundColor Yellow
    Write-Host "   1. SQL Server est démarré" -ForegroundColor White
    Write-Host "   2. L'authentification Windows est activée" -ForegroundColor White
    Write-Host "   3. Votre compte a les permissions nécessaires" -ForegroundColor White
    exit 1
}

# 5. Redémarrer IIS pour appliquer les migrations
Write-Host "`n5. Redémarrage de l'application..." -ForegroundColor Yellow

try {
    Stop-WebAppPool -Name "CheckFillingAPIPool" -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Start-WebAppPool -Name "CheckFillingAPIPool"
    Write-Host "   ✓ Application pool redémarré" -ForegroundColor Green
} catch {
    Write-Host "   ! Erreur lors du redémarrage: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 6. Attendre que la base soit créée
Write-Host "`n6. Création de la base de données (peut prendre quelques secondes)..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# 7. Vérifier que la base a été créée
Write-Host "`n7. Vérification de la base de données..." -ForegroundColor Yellow

try {
    $dbCheck = Invoke-Sqlcmd -Query "SELECT name FROM sys.databases WHERE name = 'CheckFilling'" -ServerInstance "localhost"
    
    if ($dbCheck) {
        Write-Host "   ✓ Base de données 'CheckFilling' créée avec succès!" -ForegroundColor Green
    } else {
        Write-Host "   ✗ Base de données non trouvée" -ForegroundColor Red
        Write-Host "   Vérifiez les logs de l'application" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ! Erreur: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 8. Vérifier les tables
Write-Host "`n8. Vérification des tables..." -ForegroundColor Yellow

try {
    $tables = Invoke-Sqlcmd -Query "SELECT TABLE_NAME FROM CheckFilling.INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE'" -ServerInstance "localhost"
    
    if ($tables) {
        Write-Host "   ✓ Tables créées:" -ForegroundColor Green
        foreach ($table in $tables) {
            Write-Host "     - $($table.TABLE_NAME)" -ForegroundColor White
        }
    } else {
        Write-Host "   ✗ Aucune table trouvée" -ForegroundColor Red
    }
} catch {
    Write-Host "   ! Erreur: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 9. Afficher les logs de l'application
Write-Host "`n9. Derniers logs de l'application:" -ForegroundColor Yellow
$logFile = Get-ChildItem "$publishPath\logs\stdout*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if ($logFile) {
    Write-Host "   Fichier: $($logFile.Name)" -ForegroundColor White
    Get-Content $logFile.FullName -Tail 20 | ForEach-Object {
        if ($_ -match "error|exception|fail") {
            Write-Host "   $_" -ForegroundColor Red
        } elseif ($_ -match "warn") {
            Write-Host "   $_" -ForegroundColor Yellow
        } else {
            Write-Host "   $_" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "   Aucun fichier de log trouvé" -ForegroundColor Yellow
}

Write-Host "`n=== INITIALISATION TERMINÉE ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Si la base n'est pas créée, vérifiez :" -ForegroundColor Yellow
Write-Host "1. Les logs ci-dessus pour des erreurs" -ForegroundColor White
Write-Host "2. Que SQL Server est bien démarré" -ForegroundColor White
Write-Host "3. Les permissions de l'application pool IIS" -ForegroundColor White
Write-Host "4. Que l'application est redémarrée (les migrations s'exécutent au démarrage)" -ForegroundColor White

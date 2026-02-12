# Script de diagnostic et correction pour le problème de connexion
# À exécuter en tant qu'ADMINISTRATEUR

Write-Host "=== DIAGNOSTIC ET CORRECTION CheckFillingAPI ===" -ForegroundColor Cyan
Write-Host ""

# 1. Vérifier le pare-feu
Write-Host "1. Vérification du pare-feu Windows..." -ForegroundColor Yellow
$firewallRule = Get-NetFirewallRule -DisplayName "CheckFillingAPI*" -ErrorAction SilentlyContinue

if ($firewallRule) {
    Write-Host "   ✓ Règle de pare-feu existante trouvée" -ForegroundColor Green
    $firewallRule | Format-Table DisplayName, Enabled, Direction, Action
} else {
    Write-Host "   ✗ Aucune règle de pare-feu trouvée. Création..." -ForegroundColor Red
    New-NetFirewallRule -DisplayName "CheckFillingAPI - Port 5001" `
        -Direction Inbound `
        -Protocol TCP `
        -LocalPort 5001 `
        -Action Allow `
        -Profile Any `
        -Enabled True
    Write-Host "   ✓ Règle créée" -ForegroundColor Green
}

# 2. Vérifier si le port est à l'écoute
Write-Host "`n2. Vérification de l'écoute sur le port 5001..." -ForegroundColor Yellow
$listening = netstat -an | Select-String ":5001.*LISTENING"

if ($listening) {
    Write-Host "   ✓ Port 5001 en écoute:" -ForegroundColor Green
    $listening
} else {
    Write-Host "   ✗ PROBLÈME: Le port 5001 n'écoute pas!" -ForegroundColor Red
    Write-Host "   L'application n'est probablement pas démarrée." -ForegroundColor Red
}

# 3. Vérifier IIS
Write-Host "`n3. Vérification de la configuration IIS..." -ForegroundColor Yellow
Import-Module WebAdministration -ErrorAction SilentlyContinue

$site = Get-Website -Name "CheckFillingAPI" -ErrorAction SilentlyContinue

if ($site) {
    Write-Host "   ✓ Site IIS trouvé:" -ForegroundColor Green
    Write-Host "     - État: $($site.State)" -ForegroundColor White
    Write-Host "     - Chemin: $($site.PhysicalPath)" -ForegroundColor White
    Write-Host "     - Pool: $($site.ApplicationPool)" -ForegroundColor White
    
    # Vérifier les bindings
    $bindings = Get-WebBinding -Name "CheckFillingAPI"
    Write-Host "`n   Bindings configurés:" -ForegroundColor White
    foreach ($binding in $bindings) {
        Write-Host "     - $($binding.protocol)://$($binding.bindingInformation)" -ForegroundColor White
    }
    
    # Vérifier l'état de l'application pool
    $pool = Get-WebAppPoolState -Name $site.ApplicationPool
    Write-Host "`n   Application Pool État: $($pool.Value)" -ForegroundColor White
    
    if ($pool.Value -ne "Started") {
        Write-Host "   ! Démarrage de l'application pool..." -ForegroundColor Yellow
        Start-WebAppPool -Name $site.ApplicationPool
        Write-Host "   ✓ Application pool démarrée" -ForegroundColor Green
    }
    
    if ($site.State -ne "Started") {
        Write-Host "   ! Démarrage du site..." -ForegroundColor Yellow
        Start-Website -Name "CheckFillingAPI"
        Write-Host "   ✓ Site démarré" -ForegroundColor Green
    }
} else {
    Write-Host "   ✗ PROBLÈME: Site IIS 'CheckFillingAPI' non trouvé!" -ForegroundColor Red
    Write-Host "   Le site doit être créé dans IIS Manager." -ForegroundColor Red
}

# 4. Test de connectivité locale
Write-Host "`n4. Test de connectivité locale..." -ForegroundColor Yellow

try {
    $response = Invoke-WebRequest -Uri "http://localhost:5001/api/auth/login" `
        -Method GET `
        -TimeoutSec 5 `
        -ErrorAction Stop
    Write-Host "   ✓ Connexion locale réussie (Status: $($response.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "   ✗ Échec de connexion locale: $($_.Exception.Message)" -ForegroundColor Red
}

# 5. Test avec l'adresse IP
Write-Host "`n5. Test avec l'adresse IP 172.20.0.3..." -ForegroundColor Yellow

try {
    $response = Invoke-WebRequest -Uri "http://172.20.0.3:5001/api/auth/login" `
        -Method GET `
        -TimeoutSec 5 `
        -ErrorAction Stop
    Write-Host "   ✓ Connexion via IP réussie (Status: $($response.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "   ✗ Échec de connexion via IP: $($_.Exception.Message)" -ForegroundColor Red
}

# 6. Vérifier les interfaces réseau
Write-Host "`n6. Adresses IP de la machine:" -ForegroundColor Yellow
Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -ne "127.0.0.1" } | 
    Select-Object IPAddress, InterfaceAlias | Format-Table

# 7. Suggestions
Write-Host "`n=== ACTIONS RECOMMANDÉES ===" -ForegroundColor Cyan
Write-Host ""

if (-not $listening) {
    Write-Host "⚠ PROBLÈME PRINCIPAL: Le port 5001 n'écoute pas" -ForegroundColor Red
    Write-Host ""
    Write-Host "Solutions:" -ForegroundColor Yellow
    Write-Host "1. Vérifier que le site IIS est démarré (ci-dessus)" -ForegroundColor White
    Write-Host "2. Vérifier les logs dans: $($site.PhysicalPath)\logs\" -ForegroundColor White
    Write-Host "3. Tester le backend directement:" -ForegroundColor White
    Write-Host "   cd '$($site.PhysicalPath)'" -ForegroundColor Gray
    Write-Host "   dotnet CheckFillingAPI.dll" -ForegroundColor Gray
    Write-Host ""
}

if ($listening) {
    Write-Host "✓ Le backend écoute correctement" -ForegroundColor Green
    Write-Host ""
    Write-Host "Pour tester depuis un PC client:" -ForegroundColor Yellow
    Write-Host "1. Sur le PC client, ouvrir PowerShell et exécuter:" -ForegroundColor White
    Write-Host "   Test-NetConnection -ComputerName 172.20.0.3 -Port 5001" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Test navigateur:" -ForegroundColor White
    Write-Host "   http://172.20.0.3:5001/api/auth/login" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Si ça ne fonctionne toujours pas:" -ForegroundColor White
    Write-Host "   - Vérifier qu'il n'y a pas d'autre pare-feu (antivirus, réseau)" -ForegroundColor Gray
    Write-Host "   - Vérifier la configuration réseau de la VM" -ForegroundColor Gray
    Write-Host "   - Vérifier les logs IIS et de l'application" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=== FIN DU DIAGNOSTIC ===" -ForegroundColor Cyan

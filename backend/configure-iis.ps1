# Script de configuration IIS et pare-feu pour CheckFillingAPI
# À exécuter en tant qu'administrateur

Write-Host "Configuration du pare-feu Windows..." -ForegroundColor Cyan

# Ouvrir le port 5001 pour les connexions entrantes
New-NetFirewallRule -DisplayName "CheckFillingAPI - Port 5001" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 5001 `
    -Action Allow `
    -Profile Any `
    -ErrorAction SilentlyContinue

Write-Host "✓ Règle de pare-feu créée pour le port 5001" -ForegroundColor Green

# Vérifier si l'application écoute sur 0.0.0.0:5001
Write-Host "`nVérification des ports en écoute..." -ForegroundColor Cyan
netstat -an | Select-String ":5001"

Write-Host "`nConfiguration terminée!" -ForegroundColor Green
Write-Host "`nÉtapes suivantes :" -ForegroundColor Yellow
Write-Host "1. Dans IIS Manager, assurez-vous que le binding est configuré sur *:5001 (pas localhost:5001)"
Write-Host "2. Redémarrez l'application pool dans IIS"
Write-Host "3. Testez depuis un client : http://172.20.0.3:5001/api/auth/login"

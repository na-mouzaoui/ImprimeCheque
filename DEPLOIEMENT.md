# Guide de déploiement CheckFillingAPI sur VM Windows avec IIS

## Problème résolu
✓ Erreurs TypeScript corrigées (motif null → undefined, id → reference)
✓ Backend configuré pour écouter sur toutes les interfaces (0.0.0.0:5001)
✓ Configuration pare-feu et IIS

## Étapes de déploiement sur la VM (172.20.0.3)

### 1. Configurer le pare-feu Windows

Exécutez PowerShell **en tant qu'administrateur** sur la VM :

```powershell
# Ouvrir le port 5001
New-NetFirewallRule -DisplayName "CheckFillingAPI - Port 5001" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 5001 `
    -Action Allow `
    -Profile Any

# Vérifier la règle
Get-NetFirewallRule -DisplayName "CheckFillingAPI*"
```

### 2. Publier le backend

Dans le dossier backend :

```powershell
cd "C:\Users\mouza\OneDrive\Desktop\imprimecheque - Copie\backend"

# Publier l'application
dotnet publish -c Release -o C:\inetpub\wwwroot\CheckFillingAPI
```

### 3. Configurer IIS

**Option A : Via IIS Manager (GUI)**

1. Ouvrir **IIS Manager**
2. Créer un nouveau site :
   - Nom : CheckFillingAPI
   - Chemin physique : `C:\inetpub\wwwroot\CheckFillingAPI`
   - Type : http
   - Adresse IP : **Toutes non attribuées** (ou spécifiquement 172.20.0.3)
   - Port : **5001**
   - Nom d'hôte : (laisser vide)
3. Pool d'applications :
   - Version .NET CLR : **Aucun code managé**
   - Mode pipeline : Intégré
4. Redémarrer l'application pool

**Option B : Via PowerShell**

```powershell
Import-Module WebAdministration

# Créer l'application pool
New-WebAppPool -Name "CheckFillingAPIPool"
Set-ItemProperty IIS:\AppPools\CheckFillingAPIPool -Name managedRuntimeVersion -Value ""

# Créer le site
New-Website -Name "CheckFillingAPI" `
    -PhysicalPath "C:\inetpub\wwwroot\CheckFillingAPI" `
    -ApplicationPool "CheckFillingAPIPool" `
    -Port 5001

# Démarrer le site
Start-Website -Name "CheckFillingAPI"
```

### 4. Tester depuis la VM

```powershell
# Test local
Invoke-WebRequest -Uri "http://localhost:5001/api/auth/login" -Method POST `
    -ContentType "application/json" `
    -Body '{"email":"test@mobilis.dz","password":"test"}'

# Test avec l'IP
Invoke-WebRequest -Uri "http://172.20.0.3:5001/api/auth/login" -Method POST `
    -ContentType "application/json" `
    -Body '{"email":"test@mobilis.dz","password":"test"}'
```

### 5. Tester depuis un PC client

Ouvrir un navigateur ou PowerShell sur le PC client :

```powershell
# Test de connectivité
Test-NetConnection -ComputerName 172.20.0.3 -Port 5001

# Test API
Invoke-WebRequest -Uri "http://172.20.0.3:5001/api/auth/login" -Method POST `
    -ContentType "application/json" `
    -Body '{"email":"test@mobilis.dz","password":"test"}'
```

Ou dans le navigateur : `http://172.20.0.3:5001/api/auth/login`

### 6. Déployer le frontend

Dans le dossier frontend :

```powershell
cd "C:\Users\mouza\OneDrive\Desktop\imprimecheque - Copie\frontend"

# Build
npm run build

# Copier le dossier out vers IIS
Copy-Item -Path ".\out\*" -Destination "C:\inetpub\wwwroot\CheckFilling" -Recurse -Force
```

Configurer IIS pour servir le frontend sur le port 80 :

```powershell
New-Website -Name "CheckFilling" `
    -PhysicalPath "C:\inetpub\wwwroot\CheckFilling" `
    -Port 80
```

### 7. Dépannage

**Si le port 5001 n'est toujours pas accessible depuis l'extérieur :**

1. Vérifier que le binding IIS est correct :
   ```powershell
   Get-WebBinding -Name "CheckFillingAPI"
   ```

2. Vérifier que l'application écoute bien :
   ```powershell
   netstat -an | Select-String ":5001"
   ```
   Vous devriez voir : `0.0.0.0:5001` ou `[::]:5001`

3. Désactiver temporairement le pare-feu pour tester :
   ```powershell
   Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
   # Tester
   # Puis réactiver :
   Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
   ```

4. Vérifier les logs IIS :
   - Logs stdout : `C:\inetpub\wwwroot\CheckFillingAPI\logs\`
   - Event Viewer : Windows Logs > Application

5. Vérifier la configuration CORS dans appsettings.json :
   ```json
   "Cors": {
     "AllowedOrigins": [
       "http://localhost",
       "http://172.20.0.3"
     ]
   }
   ```

**Si le frontend ne fonctionne pas :**

1. Vérifier que toutes les routes ont un fichier index.html :
   ```powershell
   Get-ChildItem "C:\inetpub\wwwroot\CheckFilling" -Recurse -Directory | 
       Where-Object { -not (Test-Path "$($_.FullName)\index.html") }
   ```

2. Configurer IIS pour rediriger vers index.html (créer web.config) :
   ```xml
   <?xml version="1.0" encoding="utf-8"?>
   <configuration>
     <system.webServer>
       <rewrite>
         <rules>
           <rule name="React Routes" stopProcessing="true">
             <match url=".*" />
             <conditions logicalGrouping="MatchAll">
               <add input="{REQUEST_FILENAME}" matchType="IsFile" negate="true" />
               <add input="{REQUEST_FILENAME}" matchType="IsDirectory" negate="true" />
             </conditions>
             <action type="Rewrite" url="/index.html" />
           </rule>
         </rules>
       </rewrite>
     </system.webServer>
   </configuration>
   ```

## Résumé des changements effectués

### Frontend
- ✓ `lib/config.ts` : Port 5000 → 5001
- ✓ `next.config.mjs` : Ajout de `trailingSlash: true` pour éviter les 403
- ✓ `check-history.tsx` : Correction erreurs TypeScript (motif null → undefined, id → reference)

### Backend
- ✓ `Properties/launchSettings.json` : localhost → 0.0.0.0
- ✓ `Program.cs` : Ajout configuration Kestrel pour écouter sur 0.0.0.0:5001


# Guide de Déploiement - Check Filling Application

## Prérequis sur la VM

### 1. Installer .NET 8.0 Runtime
```bash
# Télécharger et installer le runtime ASP.NET Core 8.0
# Depuis: https://dotnet.microsoft.com/download/dotnet/8.0
```

### 2. Installer SQL Server

**Option A: SQL Server Express (Gratuit)**
```bash
# Télécharger SQL Server Express depuis:
# https://www.microsoft.com/sql-server/sql-server-downloads

# Après installation, noter les informations de connexion:
# - Nom du serveur (ex: localhost, .\SQLEXPRESS)
# - Mode d'authentification (Windows ou SQL Server)
```

**Option B: Utiliser une base de données distante**
- Azure SQL Database
- SQL Server sur un autre serveur
- Vous aurez besoin de la chaîne de connexion

## Étapes de Déploiement

### Étape 1: Transférer les fichiers

Transférer sur la VM:
- Le dossier `backend` compilé (depuis `backend/bin/Release/net8.0/publish/`)
- Le fichier `create-database.sql`
- Le dossier `frontend` (si vous hébergez le frontend sur la même VM)

### Étape 2: Créer la base de données

**Méthode 1: Avec sqlcmd (si SQL Server installé localement)**
```bash
# Ouvrir PowerShell en administrateur
cd C:\chemin\vers\backend

# Exécuter le script de création
sqlcmd -S localhost -E -C -i create-database.sql

# OU si vous utilisez une authentification SQL Server:
sqlcmd -S localhost -U votre_utilisateur -P votre_mot_de_passe -C -i create-database.sql
```

**Méthode 2: Avec SQL Server Management Studio (SSMS)**
1. Ouvrir SSMS
2. Se connecter au serveur SQL
3. Ouvrir le fichier `create-database.sql`
4. Exécuter le script (F5)

**Méthode 3: Sans SQL Server installé - Utiliser une base distante**
1. Créer la base de données sur le serveur distant
2. Exécuter le script `create-database.sql` depuis SSMS ou un autre outil
3. Mettre à jour la chaîne de connexion dans `appsettings.json`

### Étape 3: Configurer appsettings.json

Éditer `backend/appsettings.json`:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=VOTRE_SERVEUR;Database=CheckFilling;Integrated Security=True;Encrypt=False;Trusted_Connection=True;TrustServerCertificate=True;"
  },
  "Cors": {
    "AllowedOrigins": [
      "http://IP_DE_VOTRE_VM",
      "http://localhost"
    ]
  },
  "Jwt": {
    "Key": "VOTRE_CLE_SECRETE_JWT_MIN_32_CARACTERES",
    "Issuer": "CheckFillingAPI",
    "Audience": "CheckFillingUsers",
    "ExpiryInMinutes": 480
  }
}
```

**Exemples de chaînes de connexion:**

```json
// SQL Server Express avec authentification Windows
"Server=.\\SQLEXPRESS;Database=CheckFilling;Trusted_Connection=True;TrustServerCertificate=True;"

// SQL Server avec authentification SQL
"Server=localhost;Database=CheckFilling;User Id=sa;Password=VotreMotDePasse;TrustServerCertificate=True;"

// Azure SQL Database
"Server=tcp:votreserveur.database.windows.net,1433;Database=CheckFilling;User ID=admin;Password=MotDePasse;Encrypt=True;TrustServerCertificate=False;"

// SQL Server distant
"Server=192.168.1.100;Database=CheckFilling;User Id=admin;Password=MotDePasse;TrustServerCertificate=True;"
```

### Étape 4: Installer le Backend comme Service Windows

**Option A: Utiliser NSSM (Non-Sucking Service Manager)**
```bash
# Télécharger NSSM: https://nssm.cc/download

# Installer le service
nssm install CheckFillingAPI "C:\chemin\vers\CheckFillingAPI.exe"
nssm set CheckFillingAPI AppDirectory "C:\chemin\vers\backend"
nssm set CheckFillingAPI DisplayName "Check Filling API"
nssm set CheckFillingAPI Description "API Backend pour l'application Check Filling"
nssm start CheckFillingAPI
```

**Option B: Créer un service Windows manuel**
```bash
# Créer un service avec sc.exe
sc create CheckFillingAPI binPath="C:\chemin\vers\CheckFillingAPI.exe" start=auto
sc description CheckFillingAPI "API Backend pour Check Filling"
sc start CheckFillingAPI
```

**Option C: Exécuter manuellement (pour tester)**
```bash
cd C:\chemin\vers\backend
dotnet CheckFillingAPI.dll
# OU
CheckFillingAPI.exe
```

### Étape 5: Configurer le Frontend

**Si vous utilisez Next.js en production:**

1. Éditer `frontend/.env.production`:
```env
NEXT_PUBLIC_API_URL=http://IP_DE_VOTRE_VM:5000
```

2. Builder le frontend:
```bash
cd frontend
npm install
npm run build
```

3. Démarrer le frontend:
```bash
npm start
# Le frontend sera accessible sur le port 3000
```

**Utiliser un reverse proxy (IIS ou Nginx):**
- Configurer IIS ou Nginx pour router les requêtes vers le backend (port 5000) et frontend (port 3000)

### Étape 6: Ouvrir les ports du pare-feu

```bash
# Ouvrir PowerShell en administrateur

# Port backend (5000)
New-NetFirewallRule -DisplayName "Check Filling API" -Direction Inbound -Protocol TCP -LocalPort 5000 -Action Allow

# Port frontend (3000)
New-NetFirewallRule -DisplayName "Check Filling Frontend" -Direction Inbound -Protocol TCP -LocalPort 3000 -Action Allow
```

## Vérification du déploiement

### 1. Tester la base de données
```sql
-- Dans SSMS ou sqlcmd
USE CheckFilling;
SELECT * FROM Users;
-- Vous devriez voir 3 utilisateurs
```

### 2. Tester le backend
```bash
# Dans un navigateur ou avec curl
curl http://localhost:5000/api/banks
# OU
curl http://IP_VM:5000/api/banks
```

### 3. Tester la connexion
- Ouvrir `http://IP_VM:3000/login`
- Se connecter avec:
  - Email: `test@gmail.com`
  - Mot de passe: `123456789`

## Comptes par défaut

Après création de la base de données, 3 comptes admin sont disponibles:

| Email | Mot de passe | Rôle |
|-------|--------------|------|
| test@gmail.com | 123456789 | admin |
| admin@test.com | 123456789 | admin |
| admin@gmail.com | 123456789 | admin |

**⚠️ IMPORTANT: Changez ces mots de passe après le premier déploiement!**

## Dépannage

### Erreur de connexion à la base de données
- Vérifier que SQL Server est démarré: `services.msc` → SQL Server
- Vérifier la chaîne de connexion dans `appsettings.json`
- Vérifier que le port 1433 est ouvert si base distante
- Tester avec: `sqlcmd -S nom_serveur -U utilisateur -P mot_de_passe`

### Le backend ne démarre pas
- Vérifier les logs dans `backend/logs/` ou Event Viewer
- Vérifier que .NET 8.0 Runtime est installé: `dotnet --list-runtimes`
- Vérifier les permissions du dossier `wwwroot/uploads`

### Erreur CORS
- Vérifier que l'URL du frontend est dans `AllowedOrigins` dans `appsettings.json`
- Vérifier que le frontend utilise la bonne URL de l'API

### Le frontend ne trouve pas l'API
- Vérifier `NEXT_PUBLIC_API_URL` dans `.env.production`
- Vérifier que le backend est accessible: `curl http://IP:5000/api/banks`

## Maintenance

### Sauvegardes
```sql
-- Sauvegarder la base de données
BACKUP DATABASE CheckFilling 
TO DISK = 'C:\Backups\CheckFilling.bak'
WITH FORMAT, INIT, NAME = 'Full Backup of CheckFilling';
```

### Mise à jour
1. Arrêter les services
2. Sauvegarder la base de données
3. Remplacer les fichiers de l'application
4. Appliquer les nouvelles migrations si nécessaire
5. Redémarrer les services

### Logs
- Backend logs: `backend/logs/` (si configuré)
- Event Viewer: Applications and Services Logs
- SQL Server logs: SQL Server Management Studio → Management → SQL Server Logs

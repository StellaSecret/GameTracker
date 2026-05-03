# 🎲 GameTracker

Application Flutter de suivi de scores pour jeux de société — avec synchronisation Google Drive, groupes temps réel (Firebase) et modèle freemium.

[![Build & Deploy](https://github.com/StellaSecret/GameTracker/actions/workflows/build.yml/badge.svg)](https://github.com/StellaSecret/GameTracker/actions/workflows/build.yml)

**[📱 Télécharger l'APK](https://github.com/StellaSecret/GameTracker/releases)** · **[🌐 Version Web](https://stellasecret.github.io/GameTracker/)**

---

## ✨ Fonctionnalités

### Gratuit
- **3 modes de jeu** : Points · Duel · Classement
- Jusqu'à **5 jeux** et **20 parties par jeu**
- Gestion des joueurs avec couleur personnalisée
- Statistiques : leaderboard, records, total de victoires
- Persistance locale JSON sur l'appareil
- **Sync Google Drive** : sauvegarde / restauration manuelle

### Premium
- Jeux et historique **illimités**
- **Groupes temps réel** (Firebase) — scores synchronisés entre joueurs
- *(À venir)* Statistiques avancées, export CSV

---

## 🚀 Installation rapide

### Prérequis

- [Flutter](https://flutter.dev/docs/get-started/install) (dernière version stable)
- Java 17
- Compte Google Cloud (pour Drive + Firebase)

### Lancer en dev

```bash
git clone https://github.com/StellaSecret/GameTracker.git
cd GameTracker
flutter pub get
flutter run
```

### Lancer avec le premium activé (dev)

```bash
flutter run --dart-define=PREMIUM_EMAILS=ton@email.com
```

---

## ☁️ Configuration Google Cloud / Firebase

### 1. Créer le projet Firebase

1. [console.firebase.google.com](https://console.firebase.google.com/) → nouveau projet `GameTracker`
2. Ajouter une app Android : package `com.stellasecret.gametracker`
3. **Authentication → Sign-in method** → activer **Google**
4. **Firestore Database** → créer en mode Production, région `europe-west1`
5. Télécharger `google-services.json` → placer dans `android/app/`

> Le même projet Firebase sert pour Drive (Google Sign-In), Firestore (groupes) et Firebase Auth.

### 2. SHA-1 dans Firebase

Firebase vérifie la signature APK pour Google Sign-In. Ajoutez les deux empreintes dans **Firebase Console → Paramètres → Ton app Android** :

```bash
# Debug (flutter run)
keytool -list -v -keystore ~/.android/debug.keystore \
  -alias androiddebugkey -storepass android | grep SHA1

# Release (build CI)
keytool -list -v -keystore release-key.jks -alias game-tracker | grep SHA1
```

Après chaque ajout de SHA-1, **retéléchargez** `google-services.json` et mettez à jour le secret `GOOGLE_SERVICES_JSON`.

### 3. Règles Firestore

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /groups/{groupId} {
      allow read, write: if request.auth != null
        && request.auth.token.email in resource.data.memberEmails;
      allow create: if request.auth != null;
    }
  }
}
```

---

## 🔏 Build de production signé

### Créer une keystore

```bash
keytool -genkey -v \
  -keystore release-key.jks \
  -keyalg RSA -keysize 2048 \
  -validity 10000 \
  -alias game-tracker
```

### Secrets GitHub Actions

**Settings → Secrets and variables → Actions** :

| Secret | Description | Commande pour obtenir la valeur |
|---|---|---|
| `KEYSTORE_BASE64` | Keystore de signature encodé | `base64 -w 0 release-key.jks` |
| `KEYSTORE_PASSWORD` | Mot de passe keystore | — |
| `KEY_ALIAS` | Alias de la clé | `game-tracker` |
| `KEY_PASSWORD` | Mot de passe de la clé | — |
| `GOOGLE_SERVICES_JSON` | Contenu de `google-services.json` (minifié) | `python3 -c "import json; print(json.dumps(json.load(open('android/app/google-services.json'))))"` |
| `GOOGLE_WEB_CLIENT_ID` | Client ID OAuth Web (pour GitHub Pages) | Google Cloud Console → Credentials |
| `PREMIUM_EMAILS` | Emails avec accès premium gratuit | `email1@x.com,email2@x.com` |

> **Gestion de `PREMIUM_EMAILS`** : utilisez le script `./update_premium_emails.sh` pour éditer la liste et mettre à jour le secret automatiquement via `gh` CLI. Le fichier `.premium_emails.txt` (ignoré par git) sert de référence locale.

### Ce que produit le CI à chaque push sur `main`

- **APK arm64** → installable directement sur Android (sideload)
- **AAB** → à uploader sur Google Play Console
- **Web** → déployé sur GitHub Pages automatiquement
- Une **GitHub Release** est créée avec le numéro de build

---

## 🌐 GitHub Pages

Activez Pages dans **Settings → Pages → Source : GitHub Actions**.

URL : `https://stellasecret.github.io/GameTracker/`

> Firebase et les groupes temps réel ne sont **pas disponibles** sur la version web (guards `kIsWeb`). La sync Google Drive fonctionne sur le web.

---

## 💰 Modèle freemium

Les limites sont définies dans `lib/models/entitlement.dart` :

```dart
static const int freeGameLimit = 5;      // Jeux max (gratuit)
static const int freeSessionLimit = 20;  // Parties max par jeu (gratuit)
```

Les achats in-app sont gérés par **RevenueCat** (`lib/services/purchase_service.dart`). Pour activer RevenueCat, remplacez les placeholders :

```dart
static const String _kApiKeyAndroid = 'YOUR_REVENUECAT_ANDROID_KEY';
static const String _kApiKeyIOS    = 'YOUR_REVENUECAT_IOS_KEY';
```

L'entitlement RevenueCat doit s'appeler exactement `premium`.

---

## 🏗️ Architecture

```
lib/
├── main.dart
├── models/
│   ├── app_data.dart           # Modèle racine + merge Drive/Firestore
│   ├── entitlement.dart        # Limites freemium
│   ├── game.dart               # Jeu + helpers stats
│   ├── game_mode.dart          # Enum modes (points/duel/classement)
│   ├── game_session.dart       # Partie jouée
│   └── player.dart             # Joueur
├── services/
│   ├── app_state.dart          # ChangeNotifier global (Provider)
│   ├── storage_service.dart    # Persistance locale (SharedPreferences)
│   ├── google_drive_service.dart  # Sync Drive (backup/restore)
│   ├── google_sign_in_singleton.dart  # Instance GoogleSignIn partagée
│   ├── group_service.dart      # Groupes temps réel (Firestore)
│   └── purchase_service.dart   # RevenueCat + override email premium
├── screens/
│   ├── games_screen.dart
│   ├── game_detail_screen.dart
│   ├── add_game_screen.dart
│   ├── add_session_screen.dart # Création ET édition de session
│   ├── players_screen.dart
│   ├── group_screen.dart       # Gestion des groupes (premium)
│   └── paywall_screen.dart     # Écran d'achat premium
├── widgets/
│   └── gt_card.dart
└── theme/
    └── app_theme.dart
```

---

## 📋 Roadmap

- [ ] Statistiques avancées (graphiques, nemesis, séries)
- [ ] Mode tournoi (bracket)
- [ ] Export CSV / PDF
- [ ] Notifications de rappel de partie
- [ ] Thème clair

---

## 🔒 Confidentialité

Politique de confidentialité : [stellasecret.github.io/privacy-pages/gametracker/privacy.html](https://stellasecret.github.io/privacy-pages/gametracker/privacy.html)

GameTracker ne collecte aucune donnée personnelle. Toutes les données restent localement sur l'appareil sauf si l'utilisateur active explicitement la sync Drive ou les groupes Firebase.

---

## 📄 Licence

MIT — voir [LICENSE](LICENSE)

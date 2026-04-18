# 🎲 GameTracker

Application Flutter pour suivre les scores de vos jeux de société, avec synchronisation Google Drive et partage entre joueurs.

[![Build & Deploy](https://github.com/StellaSecret/GameTracker/actions/workflows/build.yml/badge.svg)](https://github.com/StellaSecret/GameTracker/actions/workflows/build.yml)

**[📱 Télécharger l'APK](https://github.com/StellaSecret/GameTracker/actions)** · **[🌐 Version Web](https://stellasecret.github.io/GameTracker/)**

---

## ✨ Fonctionnalités

- **3 modes de jeu** :
  - 🏆 **Points** — classement par score, record individuel, total par joueur
  - ⚔️ **Duel** — Victoire / Match nul / Défaite, classement aux victoires
  - 🎖️ **Classement** — podium positionnel multi-joueurs (1er, 2ème…)
- **Tri alphabétique** automatique avec index par lettre
- **Gestion des joueurs** avec couleur personnalisée
- **Statistiques** : leaderboard, records, total de victoires
- **Persistance locale** : données sauvegardées en JSON sur l'appareil
- **Sync Google Drive** : upload / download / partage avec d'autres utilisateurs
- **Design sombre** moderne avec animations fluides

---

## 🚀 Installation rapide

### Prérequis

- [Flutter 3.22+](https://flutter.dev/docs/get-started/install)
- Java 17
- Un compte Google Cloud (pour Drive)

### Lancer en dev

```bash
git clone https://github.com/StellaSecret/GameTracker.git
cd GameTracker
flutter pub get
flutter run
```

---

## ☁️ Configuration Google Drive

### 1. Créer un projet Google Cloud

1. Aller sur [console.cloud.google.com](https://console.cloud.google.com/)
2. Créer un nouveau projet → nommez-le `GameTracker`
3. Activer l'API **Google Drive API** (APIs & Services → Library)
4. Activer l'API **Google Sign-In**

### 2. Créer les identifiants OAuth

1. APIs & Services → **Credentials** → Create Credentials → **OAuth 2.0 Client ID**
2. Application type : **Android**
3. Package name : `com.example.game_tracker` *(ou le vôtre dans `build.gradle`)*
4. SHA-1 fingerprint : obtenez-le avec :
   ```bash
   # Debug (développement)
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1
   
   # Release (production)
   keytool -list -v -keystore your-release-key.jks -alias your-key-alias
   ```
5. Téléchargez `google-services.json` → placez-le dans `android/app/`

> **Web** : créez également un client OAuth de type *Web application* et notez le Client ID pour la version GitHub Pages.

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

### Configurer les secrets GitHub

Dans Settings → Secrets and variables → Actions, ajoutez :

| Secret | Valeur |
|---|---|
| `KEYSTORE_BASE64` | `base64 -w 0 release-key.jks` |
| `KEYSTORE_PASSWORD` | Mot de passe de la keystore |
| `KEY_ALIAS` | `game-tracker` |
| `KEY_PASSWORD` | Mot de passe de la clé |

L'APK signé sera généré automatiquement à chaque push sur `main`.

### Créer une release

```bash
git tag v1.0.0
git push origin v1.0.0
```

L'APK sera attaché automatiquement à la release GitHub.

---

## 🌐 GitHub Pages

La version web est déployée automatiquement sur chaque push dans `main`.

**Activer Pages** : Settings → Pages → Source : **GitHub Actions**

URL : `https://stellasecret.github.io/GameTracker/`

---

## 🏗️ Architecture

```
lib/
├── main.dart                    # Point d'entrée
├── models/
│   ├── app_data.dart            # Modèle racine (sérialisé en JSON)
│   ├── game.dart                # Jeu + helpers stats
│   ├── game_mode.dart           # Enum des modes (points/duel/classement)
│   ├── game_session.dart        # Partie jouée
│   └── player.dart              # Joueur
├── services/
│   ├── app_state.dart           # ChangeNotifier global (Provider)
│   ├── storage_service.dart     # Persistance locale (SharedPreferences JSON)
│   └── google_drive_service.dart # Upload / download / share Drive
├── screens/
│   ├── games_screen.dart        # Liste alphabétique des jeux
│   ├── game_detail_screen.dart  # Détail + stats + historique
│   ├── add_game_screen.dart     # Création / édition de jeu
│   ├── add_session_screen.dart  # Saisie de scores (adaptée au mode)
│   └── players_screen.dart      # Gestion des joueurs
├── widgets/
│   └── gt_card.dart             # Composants réutilisables
└── theme/
    └── app_theme.dart           # Design system (couleurs, typographie)
```

---

## 📋 Roadmap

- [ ] Graphiques d'évolution des scores
- [ ] Mode tournoi (bracket)
- [ ] Statistiques globales (joueur le plus actif, jeu le plus joué…)
- [ ] Export CSV / PDF
- [ ] Notifications de rappel de partie
- [ ] Thème clair

---

## 📄 Licence

MIT — voir [LICENSE](LICENSE)

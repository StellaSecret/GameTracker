# 🚀 Guide de configuration — GameTracker

Ce document couvre uniquement les étapes de configuration tierces nécessaires
pour activer les fonctionnalités premium et la sync Drive.

---

## 1. Google Drive (plan gratuit — backup manuel)

### Créer les credentials OAuth

1. [console.cloud.google.com](https://console.cloud.google.com/) → nouveau projet `GameTracker`
2. Activer **Google Drive API** et **Google Sign-In API**
3. APIs & Services → Credentials → OAuth 2.0 Client ID
   - Type : **Android**, package : `com.stellasecret.gametracker`
   - SHA-1 : `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android`
   - Type : **Web Application** (pour GitHub Pages)
     - Authorized Javascript Origins: `https://stellasecret.github.io`
     - Authorized Redirect URIs: `https://stellasecret.github.io/GameTracker/`
4. Télécharger `google-services.json` → placer dans `android/app/`
5. Note sur le **Web** :
   - Vous devez passer `--dart-define=GOOGLE_WEB_CLIENT_ID=votre_id.apps.googleusercontent.com` au build.
   - Sur GitHub Pages, le flow est forcé en **Redirect Mode** via un shim JS dans `index.html` car COOP n'est pas supporté.
   - Les **ad-blockers** peuvent bloquer le bouton. Un avertissement est affiché dans l'UI si kIsWeb.

> Le scope utilisé est `driveAppdataScope` (données cachées, invisible dans le Drive de l'utilisateur).

---

## 2. Firebase / Firestore (groupes temps réel — premium)

1. [console.firebase.google.com](https://console.firebase.google.com/) → même projet Google Cloud
2. Ajouter une app Android (même `google-services.json` que Drive, re-télécharger)
3. Firestore Database → **Créer** → mode Production → région `europe-west1`
4. Règles de sécurité Firestore :

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /groups/{groupId} {
      // Lecture : membre du groupe (par email)
      allow read: if request.auth != null
        && request.auth.token.email in resource.data.memberEmails;
      // Écriture : membre du groupe
      allow write: if request.auth != null
        && request.auth.token.email in resource.data.memberEmails;
      // Création : authentifié
      allow create: if request.auth != null;
    }
  }
}
```

5. Dans `lib/main.dart`, décommenter `await Firebase.initializeApp();`

---

## 3. RevenueCat (achats in-app — freemium)

1. [app.revenuecat.com](https://app.revenuecat.com) → nouveau projet
2. Ajouter les apps Android et iOS
3. Créer un **Entitlement** nommé exactement `premium`
4. Créer des **Products** dans Google Play Console et App Store Connect :
   - `gametracker_premium_monthly` (mensuel)
   - `gametracker_premium_annual` (annuel)
5. Créer une **Offering** `default` avec ces deux packages
6. Copier les clés API dans `lib/services/purchase_service.dart` :
   ```dart
   static const String _kApiKeyAndroid = 'appl_XXXXXXXX';
   static const String _kApiKeyIOS = 'goog_XXXXXXXX';
   ```

---

## 4. Déploiement

### APK signé

```bash
keytool -genkey -v -keystore release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias game-tracker
```

Secrets GitHub Actions :

| Secret | Valeur |
|--------|--------|
| `KEYSTORE_BASE64` | `base64 -w 0 release-key.jks` |
| `KEYSTORE_PASSWORD` | Mot de passe keystore |
| `KEY_ALIAS` | `game-tracker` |
| `KEY_PASSWORD` | Mot de passe clé |
| `ADMOB_REWARDED_AD_UNIT_ANDROID` | ID d'unité pub AdMob (format `ca-app-pub-XXXX/YYYY`) — sans ce secret, le build utilise l'ID de test Google (voir `lib/services/ad_service.dart`) |
| `ADMOB_APPLICATION_ID_ANDROID` | App ID AdMob (format `ca-app-pub-XXXX~YYYY`, remarquez le `~`) — **doit correspondre à la même appli AdMob** que `ADMOB_REWARDED_AD_UNIT_ANDROID` ci-dessus, sinon les requêtes pub échouent avec `ERROR_CODE_INVALID_REQUEST`. Sans ce secret, le build utilise l'App ID de test Google (voir `android/app/build.gradle` / `AndroidManifest.xml`) |
| `PREMIUM_EMAILS` | Emails séparés par des virgules avec accès développeur/reviewer **complet** (Premium + Group Sync), sans achat réel — voir `lib/services/purchase_service.dart` |
| `GROUP_SYNC_EMAILS` | Emails séparés par des virgules avec accès **Group Sync uniquement** (comp/beta-testeurs), indépendant de Premium — même mécanisme que `PREMIUM_EMAILS` mais volontairement séparé (voir `entitlement.dart` sur pourquoi les deux entitlements sont indépendants) |

---

## 5. Limites freemium (modifiables)

Dans `lib/models/entitlement.dart` :

```dart
static const int freeGameLimit = 5;      // Jeux max sur le plan gratuit
static const int freeSessionLimit = 20;  // Parties max par jeu sur le plan gratuit
```

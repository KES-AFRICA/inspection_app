# 📋 Inspection App (KES)

Application Flutter dédiée à la réalisation d'inspections techniques sur le terrain (installations électriques, risques foudre, éclairage, classement de zones, etc.), avec stockage local hors-ligne, synchronisation et génération automatique de rapports PDF enrichis par IA.

---

## 🚀 Prise en main (Après `git clone`)

Suivez ces étapes pour configurer et exécuter le projet sur votre nouveau PC :

### 1. Cloner le projet et installer les dépendances
```bash
git clone <URL_DU_DEPOT>
cd inspection_app
flutter pub get
```

### 2. Configurer le fichier des clés API (`api_keys.dart`)
Le fichier `lib/config/api_keys.dart` contient les clés d'accès aux services IA (Gemini & Groq). Pour des raisons de sécurité, **ce fichier est exclu du suivi Git (.gitignore)**.

1. **Dupliquez le fichier exemple** fourni à la racine du module config :
   ```bash
   cp lib/config/api_keys.dart.example lib/config/api_keys.dart
   ```
2. **Éditez `lib/config/api_keys.dart`** et renseignez vos véritables clés API :
   ```dart
   class ApiKeys {
     static const String geminiApiKey = String.fromEnvironment(
       'GEMINI_API_KEY',
       defaultValue: 'VOTRE_CLE_GEMINI_REELLE',
     );

     static const String groqApiKey = String.fromEnvironment(
       'GROQ_API_KEY',
       defaultValue: 'VOTRE_CLE_GROQ_REELLE',
     );
   }
   ```
   > 💡 *Alternativement, vous pouvez passer ces variables lors de la commande de build/run via `--dart-define=GEMINI_API_KEY=... --dart-define=GROQ_API_KEY=...`.*

### 3. Générer les adaptateurs Hive (`build_runner`)
L'application utilise **Hive** pour la persistance locale et nécessite la génération des modèles d'adaptateurs (`.g.dart`) :
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. Lancer l'application
```bash
flutter run
```

---

## 🛠️ Stack Technique & Architecture

- **Framework** : Flutter (Dart SDK `^3.9.2`)
- **Gestion d'état & DI** : Flutter Riverpod & GetIt
- **Base de données locale** : Hive (NoSQL hors-ligne)
- **Génération de documents** : Package `pdf` & `printing`
- **Services IA** : Google Gemini API & Groq API (Synthèses exécutives de missions)

### Structure du projet (`lib/`)

```text
lib/
├── components/     # Composants UI réutilisables
├── config/         # Configs (api_keys.dart, api_keys.dart.example)
├── constants/      # Thèmes, couleurs et constantes globales
├── core/           # Injection de dépendances (GetIt) et briques noyau
├── features/       # Modules fonctionnels (Auth, Backup, etc.)
├── models/         # Modèles de données & adaptateurs Hive
├── pages/          # Écrans principaux de l'application
├── services/       # Services métiers (IA, PDF, Storage, Backup)
└── utils/          # Helpers & utilitaires (Compression images, etc.)
```

---

## 🔒 Sécurité & Conventions Git

- ⚠️ **Protection des secrets** : Ne commitez jamais `lib/config/api_keys.dart`. Seul `api_keys.dart.example` doit être versionné.
- 📝 **Messages de commit** : Utiliser la pré-syntaxe conventionnelle du projet : `[CREATE]`, `[UPD]`, `[DLT]`.


# AyimolouMap Mobile

## Installation

1. Clonez le projet
```bash
git clone <votre-repo>
cd ayimolouMapfront
```

2. Créez le fichier `.env` à partir de l'exemple
```bash
cp .env.example .env
```

3. Ajoutez vos clés API dans `.env`
```env
GOOGLE_MAPS_API_KEY=votre_cle_google_maps
API_KEY=votre_cle_api
BASE_URL=https://votre-api.com
```

4. Installez les dépendances
```bash
flutter pub get
```

5. Lancez l'application
```bash
flutter run
```

## Configuration Google Maps

Pour obtenir une clé API Google Maps :
1. Allez sur https://console.cloud.google.com/
2. Créez un projet
3. Activez "Maps SDK for Android"
4. Créez une clé API
5. Ajoutez-la dans votre fichier `.env`
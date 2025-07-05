# 📱 Location App - Flutter & Node.js

Cette application permet aux **bailleurs** de publier des maisons et aux **locataires** de les consulter et d’envoyer des demandes de réservation.

## ✨ Fonctionnalités

### 🔐 Authentification
- Inscription / Connexion pour bailleurs et locataires
- Gestion de session avec token JWT

### 🏘️ Propriétés
- Création, modification, suppression (bailleur)
- Liste publique (locataire)

### 📌 Réservations
- Demande de location (locataire)
- Gestion des demandes reçues (bailleur)

## 🧱 Structure du projet

```
mon-projet/
├── backend/            # Node.js (Express + MongoDB)
│   ├── models/
│   ├── routes/
│   ├── middleware/
│   └── index.js
├── location_app/       # Flutter App
│   ├── lib/
│   ├── android/
│   └── ...
└── README.md
```

## 🚀 Lancement

### Backend (Node.js)
```bash
cd backend
npm install
node index.js
```

### Flutter App
```bash
cd location_app
flutter pub get
flutter run
```

## ⚠️ Remarques
- Pour un test sur Android physique : utilisez l’IP locale du PC (ex: `192.168.x.x`) au lieu de `10.0.2.2`
- Le fichier `.env` côté backend doit contenir :
```
PORT=3000
MONGO_URI=...
JWT_SECRET=...
```

## 👨‍💻 Auteur
Aziz Thiombiano"# groupe5-location-app" 

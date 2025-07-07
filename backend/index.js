const express = require('express');
const cors = require('cors');
require('dotenv').config();
const connectDB = require('./config/db');

const app = express();

// Middlewares
app.use(cors());
app.use(express.json());

// Connexion MongoDB
connectDB();

// Routes
app.use('/uploads', express.static('uploads'));
app.use('/auth', require('./routes/auth.routes'));
app.use('/properties', require('./routes/property.routes'));
app.use('/bookings', require('./routes/booking.routes'));
app.use('/admin', require('./routes/admin.routes')); // ✅ Assure-toi que ce fichier existe

// Démarrer le serveur
const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () =>
  console.log(`🚀 Server running on port ${PORT}`)
); // ✅ parenthèse ajoutée ici

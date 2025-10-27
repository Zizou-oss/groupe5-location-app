const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const rateLimit = require('express-rate-limit');
const User = require('../models/User');

// Rate limiting for auth routes
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // limit each IP to 5 requests per windowMs for auth routes
  message: { message: 'Trop de tentatives de connexion, veuillez réessayer plus tard.' }
});

// Input validation helper
const validateEmail = (email) => {
  const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return re.test(email);
};

const validatePassword = (password) => {
  return password && password.length >= 6;
};

// POST /auth/register
router.post('/register', authLimiter, async (req, res) => {
  const { email, password, role } = req.body;

  // Validation des champs
  if (!email || !password || !role) {
    return res.status(400).json({ message: "Tous les champs sont requis" });
  }

  if (!validateEmail(email)) {
    return res.status(400).json({ message: "Format d'email invalide" });
  }

  if (!validatePassword(password)) {
    return res.status(400).json({ message: "Le mot de passe doit contenir au moins 6 caractères" });
  }

  const allowedRoles = ['renter', 'landlord', 'admin'];
  if (!allowedRoles.includes(role)) {
    return res.status(400).json({ message: "Rôle invalide" });
  }

  try {
    // Vérifie si l'utilisateur existe déjà
    const existingUser = await User.findOne({ email: email.toLowerCase() });
    if (existingUser) {
      return res.status(409).json({ message: "Utilisateur déjà existant" });
    }

    // Hash du mot de passe
    const saltRounds = 12;
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    // Création de l'utilisateur
    const newUser = new User({ 
      email: email.toLowerCase(), 
      password: hashedPassword, 
      role 
    });
    await newUser.save();

    // Génère un token
    const token = jwt.sign(
      { userId: newUser._id, role: newUser.role },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.status(201).json({
      token,
      userId: newUser._id,
      role: newUser.role,
      userName: newUser.name || "Utilisateur"
    });
  } catch (err) {
    console.error('Erreur registration:', err);
    res.status(500).json({ message: "Erreur serveur", error: err.message });
  }
});

// POST /auth/login
router.post('/login', authLimiter, async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ message: "Email et mot de passe requis" });
  }

  if (!validateEmail(email)) {
    return res.status(400).json({ message: "Format d'email invalide" });
  }

  try {
    const user = await User.findOne({ email: email.toLowerCase() });

    if (!user) {
      return res.status(401).json({ message: "Identifiants incorrects" });
    }

    // Comparer les mots de passe hashés
    const isValidPassword = await bcrypt.compare(password, user.password);
    if (!isValidPassword) {
      return res.status(401).json({ message: "Identifiants incorrects" });
    }

    const token = jwt.sign(
      { userId: user._id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.status(200).json({
      token,
      userId: user._id,
      userName: user.name || "Utilisateur",
      role: user.role
    });
  } catch (err) {
    console.error('Erreur login:', err);
    res.status(500).json({ message: "Erreur serveur", error: err.message });
  }
});

module.exports = router;

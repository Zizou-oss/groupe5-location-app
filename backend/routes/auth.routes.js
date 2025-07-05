const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const User = require('../models/User');

// POST /auth/register
router.post('/register', async (req, res) => {
  const { email, password, role } = req.body;

  // Validation des champs
  if (!email || !password || !role) {
    return res.status(400).json({ message: "Tous les champs sont requis" });
  }

  const allowedRoles = ['renter', 'landlord', 'admin'];
  if (!allowedRoles.includes(role)) {
    return res.status(400).json({ message: "Rôle invalide" });
  }

  try {
    // Vérifie si l'utilisateur existe déjà
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(409).json({ message: "Utilisateur déjà existant" });
    }

    // Création de l'utilisateur
    const newUser = new User({ email, password, role });
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
    res.status(500).json({ message: "Erreur serveur", error: err.message });
  }
});

// POST /auth/login
router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ message: "Email et mot de passe requis" });
  }

  try {
    const user = await User.findOne({ email });

    if (!user || user.password !== password) {
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
    res.status(500).json({ message: "Erreur serveur", error: err.message });
  }
});

module.exports = router;

const express = require('express');
const router = express.Router();
const Property = require('../models/Property');
const User = require('../models/User');
const verifyToken = require('../middleware/authMiddleware');
const checkRole = require('../middleware/roleMiddleware');

// ✅ GET tous les utilisateurs (ADMIN uniquement)
router.get('/users', verifyToken, checkRole(['admin']), async (req, res) => {
  try {
    const users = await User.find({}, '-password'); // exclure mot de passe
    res.status(200).json(users);
  } catch (error) {
    res.status(500).json({ message: 'Erreur lors du chargement des utilisateurs' });
  }
});

// ✅ DELETE un utilisateur (ADMIN uniquement)
router.delete('/users/:id', verifyToken, checkRole(['admin']), async (req, res) => {
  try {
    await User.findByIdAndDelete(req.params.id);
    res.status(200).json({ message: 'Utilisateur supprimé' });
  } catch (error) {
    res.status(500).json({ message: 'Erreur lors de la suppression' });
  }
});

// ✅ DELETE une maison (ADMIN uniquement)
router.delete('/properties/:id', verifyToken, checkRole(['landlord', 'admin']), async (req, res) => {
  try {
    await Property.findByIdAndDelete(req.params.id);
    res.status(200).json({ message: 'Propriété supprimée' });
  } catch (error) {
    res.status(500).json({ message: 'Erreur suppression propriété' });
  }
});

// ✅ PUT modifier une maison (ADMIN uniquement)
router.put('/properties/:id', verifyToken, checkRole(['admin']), async (req, res) => {
  try {
    const updatedProperty = await Property.findByIdAndUpdate(req.params.id, req.body, { new: true });
    res.status(200).json(updatedProperty);
  } catch (error) {
    res.status(500).json({ message: 'Erreur de mise à jour' });
  }
});

module.exports = router;

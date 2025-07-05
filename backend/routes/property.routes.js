const express = require('express');
const router = express.Router();
const Property = require('../models/Property');
const verifyToken = require('../middleware/authMiddleware');  // Middleware JWT
const checkRole = require('../middleware/roleMiddleware');    // Middleware rôle

// ➕ Créer une propriété (seulement bailleurs)
router.post(
  '/',
  verifyToken,
  checkRole(['landlord']),
  async (req, res) => {
    try {
      const { title, city, price, size, features } = req.body;

      if (!title || !city || !price) {
        return res.status(400).json({ message: "Title, city et price sont obligatoires." });
      }

      const newProperty = new Property({
        title,
        city,
        price,
        size,
        features,
        ownerId: req.user.userId, // ID récupéré depuis le token décodé
      });

      const savedProperty = await newProperty.save();
      res.status(201).json(savedProperty);
    } catch (error) {
      res.status(500).json({ message: error.message });
    }
  }
);

// 🔍 Récupérer toutes les propriétés avec filtres optionnels
router.get('/', async (req, res) => {
  try {
    const { city, minPrice, maxPrice } = req.query;
    const filters = {};

    if (city) filters.city = city;
    if (minPrice || maxPrice) {
      filters.price = {};
      if (minPrice) filters.price.$gte = Number(minPrice);
      if (maxPrice) filters.price.$lte = Number(maxPrice);
    }

    const properties = await Property.find(filters);
    res.json(properties);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// ✏️ Modifier une propriété (seulement propriétaire bailleur)
router.put('/:id', verifyToken, checkRole(['landlord']), async (req, res) => {
  try {
    const property = await Property.findById(req.params.id);
    if (!property) return res.status(404).json({ message: "Propriété non trouvée." });

    if (property.ownerId.toString() !== req.user.userId) {
      return res.status(403).json({ message: "Action non autorisée." });
    }

    Object.assign(property, req.body);
    const updatedProperty = await property.save();
    res.json(updatedProperty);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// ❌ Supprimer une propriété (seulement propriétaire bailleur)
router.delete('/:id', verifyToken, checkRole(['landlord']), async (req, res) => {
  try {
    const property = await Property.findById(req.params.id);
    if (!property) return res.status(404).json({ message: "Propriété non trouvée." });

    if (property.ownerId.toString() !== req.user.userId) {
      return res.status(403).json({ message: "Action non autorisée." });
    }

    await property.remove();
    res.json({ message: "Propriété supprimée." });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// ✅ Récupérer une propriété par son ID (publique)
router.get('/:id', async (req, res) => {
  try {
    const property = await Property.findById(req.params.id);
    if (!property) {
      return res.status(404).json({ message: "Propriété non trouvée." });
    }
    res.json(property);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;

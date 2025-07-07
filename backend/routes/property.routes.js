const express = require('express');
const router = express.Router();
const multer = require('multer');
const Property = require('../models/Property');
const verifyToken = require('../middleware/authMiddleware');
const checkRole = require('../middleware/roleMiddleware');
const path = require('path');
const fs = require('fs');

// 📁 Configuration de multer pour l'upload des images
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const dir = 'uploads/properties';
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    cb(null, dir);
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + '-' + file.originalname);
  },
});
const upload = multer({ storage });

// ➕ Créer une propriété (avec upload d'images)
router.post(
  '/',
  verifyToken,
  checkRole(['landlord']),
  upload.array('images'), // ⚠️ Reçoit des fichiers
  async (req, res) => {
    try {
      const { title, city, price, size, description, features } = req.body;

      if (!title || !city || !price) {
        return res.status(400).json({ message: "Title, city et price sont obligatoires." });
      }

      // 📷 Extraire les chemins des images
      const imagePaths = req.files.map(file => `/uploads/properties/${file.filename}`);

      const newProperty = new Property({
        title,
        city,
        price,
        size,
        description, // Ajout de la description
        features,
        images: imagePaths,
        ownerId: req.user.userId,
      });

      const savedProperty = await newProperty.save();
      res.status(201).json(savedProperty);
    } catch (error) {
      res.status(500).json({ message: error.message });
    }
  }
);

// 🔍 Récupérer toutes les propriétés
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

// ✏️ Modifier une propriété
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

// ❌ Supprimer une propriété
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

// ✅ Récupérer une propriété par ID
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

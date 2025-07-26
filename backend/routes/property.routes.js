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
    const ext = path.extname(file.originalname);
    const filename = `${Date.now()}-${Math.round(Math.random() * 1E9)}${ext}`;
    cb(null, filename);
  },
});

const upload = multer({ 
  storage,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB max
    files: 10 // max 10 files
  },
  fileFilter: (req, file, cb) => {
    const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Type de fichier non autorisé. Utilisez JPG, PNG ou WebP.'), false);
    }
  }
});

// ➕ Créer une propriété (avec upload d'images)
router.post(
  '/',
  verifyToken,
  checkRole(['landlord']),
  upload.array('images'),
  async (req, res) => {
    try {
      const { title, city, price, size, description, features } = req.body;

      // Validation améliorée
      if (!title?.trim() || !city?.trim() || !price) {
        return res.status(400).json({ message: "Title, city et price sont obligatoires." });
      }

      if (isNaN(price) || price <= 0) {
        return res.status(400).json({ message: "Le prix doit être un nombre positif." });
      }

      // 📷 Traitement des images
      const imagePaths = req.files ? req.files.map(file => `/uploads/properties/${file.filename}`) : [];

      const newProperty = new Property({
        title: title.trim(),
        city: city.trim().toLowerCase(),
        price: Number(price),
        size: size?.trim(),
        description: description?.trim(),
        features: features ? (Array.isArray(features) ? features : [features]) : [],
        images: imagePaths,
        ownerId: req.user.userId,
      });

      const savedProperty = await newProperty.save();
      res.status(201).json(savedProperty);
    } catch (error) {
      console.error('Erreur création propriété:', error);
      if (error.name === 'ValidationError') {
        return res.status(400).json({ message: error.message });
      }
      res.status(500).json({ message: 'Erreur serveur' });
    }
  }
);

// 🔍 Récupérer toutes les propriétés avec pagination et filtres optimisés
router.get('/', async (req, res) => {
  try {
    const { 
      city, 
      minPrice, 
      maxPrice, 
      page = 1, 
      limit = 10,
      sortBy = 'createdAt',
      sortOrder = 'desc'
    } = req.query;

    // Construction des filtres
    const filters = { isActive: true };

    if (city) {
      filters.city = { $regex: city.toLowerCase(), $options: 'i' };
    }

    if (minPrice || maxPrice) {
      filters.price = {};
      if (minPrice && !isNaN(minPrice)) filters.price.$gte = Number(minPrice);
      if (maxPrice && !isNaN(maxPrice)) filters.price.$lte = Number(maxPrice);
    }

    // Pagination
    const pageNum = Math.max(1, parseInt(page));
    const limitNum = Math.min(50, Math.max(1, parseInt(limit))); // Max 50 items per page
    const skip = (pageNum - 1) * limitNum;

    // Tri
    const sort = {};
    sort[sortBy] = sortOrder === 'asc' ? 1 : -1;

    // Requête optimisée avec projection
    const [properties, total] = await Promise.all([
      Property.find(filters)
        .select('title city price size images createdAt imageCount')
        .sort(sort)
        .skip(skip)
        .limit(limitNum)
        .lean(), // Utilise lean() pour de meilleures performances
      Property.countDocuments(filters)
    ]);

    // Headers de cache
    res.set({
      'Cache-Control': 'public, max-age=300', // 5 minutes
      'ETag': `W/"${Date.now()}"`,
    });

    res.json({
      properties,
      pagination: {
        page: pageNum,
        limit: limitNum,
        total,
        pages: Math.ceil(total / limitNum)
      }
    });
  } catch (error) {
    console.error('Erreur récupération propriétés:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

// ✏️ Modifier une propriété
router.put('/:id', verifyToken, checkRole(['landlord']), async (req, res) => {
  try {
    const property = await Property.findById(req.params.id);
    if (!property) {
      return res.status(404).json({ message: "Propriété non trouvée." });
    }

    if (property.ownerId.toString() !== req.user.userId) {
      return res.status(403).json({ message: "Action non autorisée." });
    }

    // Validation des données modifiées
    const { title, city, price, size, description, features } = req.body;
    
    if (price && (isNaN(price) || price <= 0)) {
      return res.status(400).json({ message: "Le prix doit être un nombre positif." });
    }

    // Mise à jour sélective
    const updateData = {};
    if (title) updateData.title = title.trim();
    if (city) updateData.city = city.trim().toLowerCase();
    if (price) updateData.price = Number(price);
    if (size !== undefined) updateData.size = size?.trim();
    if (description !== undefined) updateData.description = description?.trim();
    if (features) updateData.features = Array.isArray(features) ? features : [features];

    const updatedProperty = await Property.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true, runValidators: true }
    );

    res.json(updatedProperty);
  } catch (error) {
    console.error('Erreur mise à jour propriété:', error);
    if (error.name === 'ValidationError') {
      return res.status(400).json({ message: error.message });
    }
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

// ❌ Supprimer une propriété (soft delete)
router.delete('/:id', verifyToken, checkRole(['landlord']), async (req, res) => {
  try {
    const property = await Property.findById(req.params.id);
    if (!property) {
      return res.status(404).json({ message: "Propriété non trouvée." });
    }

    if (property.ownerId.toString() !== req.user.userId) {
      return res.status(403).json({ message: "Action non autorisée." });
    }

    // Soft delete - marquer comme inactive au lieu de supprimer
    await Property.findByIdAndUpdate(req.params.id, { isActive: false });
    res.json({ message: "Propriété désactivée." });
  } catch (error) {
    console.error('Erreur suppression propriété:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

// ✅ Récupérer une propriété par ID avec cache
router.get('/:id', async (req, res) => {
  try {
    const property = await Property.findOne({
      _id: req.params.id,
      isActive: true
    }).populate('ownerId', 'email').lean();

    if (!property) {
      return res.status(404).json({ message: "Propriété non trouvée." });
    }

    // Headers de cache pour ressource spécifique
    res.set({
      'Cache-Control': 'public, max-age=600', // 10 minutes
      'ETag': `W/"${property._id}-${property.updatedAt}"`,
    });

    res.json(property);
  } catch (error) {
    console.error('Erreur récupération propriété:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

module.exports = router;

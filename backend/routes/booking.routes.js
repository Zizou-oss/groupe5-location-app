const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const Booking = require('../models/Booking');
const verifyToken = require('../middleware/authMiddleware');
const checkRole = require('../middleware/roleMiddleware');

// ⚙️ Config multer pour upload image
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/bookings');
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + '-' + file.originalname);
  },
});
const upload = multer({ storage });

// ➕ POST /bookings → créer une demande (locataire uniquement)
router.post('/', verifyToken, checkRole(['renter']), upload.array('images'), async (req, res) => {
  try {
    const { propertyId, message, ownerId, propertyTitle, renterName } = req.body;
    if (!propertyId || !ownerId) {
      return res.status(400).json({ message: "Champs requis manquants" });
    }

    const imagePaths = req.files ? req.files.map(file => `/uploads/bookings/${file.filename}`) : [];

    const newBooking = new Booking({
      propertyId,
      renterId: req.user.userId,
      renterName: renterName || "Locataire",
      propertyTitle,
      ownerId,
      message,
      images: imagePaths,
      status: 'pending',
      createdAt: new Date(),
    });

    const savedBooking = await newBooking.save();
    res.status(201).json(savedBooking);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// 🔍 GET /bookings/owner/:ownerId → réservations reçues par un bailleur
router.get('/owner/:ownerId', verifyToken, checkRole(['landlord']), async (req, res) => {
  try {
    if (req.params.ownerId !== req.user.userId) {
      return res.status(403).json({ message: "Accès interdit" });
    }

    const bookings = await Booking.find({ ownerId: req.user.userId }).populate('propertyId');
    res.status(200).json(bookings);
  } catch (error) {
    res.status(500).json({ message: "Erreur serveur lors de la récupération." });
  }
});

// 🔍 GET /bookings/received/:ownerId (optionnel, doublon à supprimer si inutile)
router.get('/received/:ownerId', verifyToken, checkRole(['landlord']), async (req, res) => {
  try {
    if (req.params.ownerId !== req.user.userId) {
      return res.status(403).json({ message: "Accès interdit" });
    }

    const bookings = await Booking.find()
      .populate({
        path: 'propertyId',
        match: { ownerId: req.user.userId },
      });

    const filteredBookings = bookings.filter(b => b.propertyId !== null);
    res.json(filteredBookings);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// 🔍 GET /bookings/user/:userId → voir ses propres demandes (locataire)
router.get('/user/:userId', verifyToken, checkRole(['renter']), async (req, res) => {
  try {
    if (req.params.userId !== req.user.userId) {
      return res.status(403).json({ message: "Accès interdit" });
    }

    const bookings = await Booking.find({ renterId: req.user.userId }).populate('propertyId');
    res.json(bookings);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// ✏️ PUT /bookings/:id/status → modifier statut (accept/reject)
router.put('/:id/status', verifyToken, checkRole(['landlord']), async (req, res) => {
  try {
    const booking = await Booking.findById(req.params.id).populate('propertyId');

    if (!booking) {
      return res.status(404).json({ message: "Demande non trouvée" });
    }

    if (booking.propertyId.ownerId.toString() !== req.user.userId) {
      return res.status(403).json({ message: "Action non autorisée" });
    }

    const { status } = req.body;
    if (!['pending', 'accepted', 'rejected'].includes(status)) {
      return res.status(400).json({ message: "Statut invalide" });
    }

    booking.status = status;
    await booking.save();

    res.json(booking);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;

const mongoose = require('mongoose');

const bookingSchema = new mongoose.Schema({
  propertyId: { type: mongoose.Schema.Types.ObjectId, ref: 'Property', required: true },
  renterId: { type: String, required: true }, // Id du locataire (User)
  message: { type: String, default: '' },
  status: { type: String, enum: ['pending', 'accepted', 'rejected'], default: 'pending' },
  createdAt: { type: Date, default: Date.now },
  image: { type: String, default: '' }, // URL de l'image de la propriété
});

module.exports = mongoose.model('Booking', bookingSchema);

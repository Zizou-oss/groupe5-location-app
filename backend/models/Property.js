const mongoose = require('mongoose');

const propertySchema = new mongoose.Schema({
  title: {
    type: String,
    required: [true, 'Le titre est requis'],
    trim: true,
    maxLength: [100, 'Le titre ne peut pas dépasser 100 caractères']
  },
  images: [{ 
    type: String,
    validate: {
      validator: function(v) {
        return !v || v.length <= 10; // Maximum 10 images
      },
      message: 'Maximum 10 images autorisées'
    }
  }],
  city: {
    type: String,
    required: [true, 'La ville est requise'],
    trim: true,
    index: true // Index pour optimiser les recherches par ville
  },
  price: {
    type: Number,
    required: [true, 'Le prix est requis'],
    min: [0, 'Le prix doit être positif'],
    index: true // Index pour optimiser les recherches par prix
  },
  size: {
    type: String,
    trim: true
  },
  description: {
    type: String,
    trim: true,
    maxLength: [1000, 'La description ne peut pas dépasser 1000 caractères']
  },
  features: [{
    type: String,
    trim: true
  }],
  ownerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'Le propriétaire est requis'],
    index: true // Index pour optimiser les recherches par propriétaire
  },
  isActive: {
    type: Boolean,
    default: true,
    index: true
  }
}, { 
  timestamps: true,
  // Optimisation des requêtes
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Index composé pour optimiser les recherches complexes
propertySchema.index({ city: 1, price: 1 });
propertySchema.index({ ownerId: 1, isActive: 1 });
propertySchema.index({ createdAt: -1 }); // Pour trier par date

// Virtual pour le nombre d'images
propertySchema.virtual('imageCount').get(function() {
  return this.images ? this.images.length : 0;
});

// Middleware pre-save pour optimisation
propertySchema.pre('save', function(next) {
  if (this.isModified('city')) {
    this.city = this.city.toLowerCase();
  }
  next();
});

module.exports = mongoose.model('Property', propertySchema);

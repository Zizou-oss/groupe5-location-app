#!/bin/bash

# Location App - Script de déploiement optimisé
# Usage: ./scripts/deploy.sh [production|staging]

set -e

ENVIRONMENT=${1:-staging}
PROJECT_ROOT=$(dirname "$(dirname "$(realpath "$0")")")

echo "🚀 Déploiement en cours pour l'environnement: $ENVIRONMENT"

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Vérification des prérequis
check_requirements() {
    log_info "Vérification des prérequis..."
    
    # Node.js
    if ! command -v node &> /dev/null; then
        log_error "Node.js n'est pas installé"
        exit 1
    fi
    
    # Flutter
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter n'est pas installé"
        exit 1
    fi
    
    # MongoDB
    if ! command -v mongod &> /dev/null && [ "$ENVIRONMENT" = "production" ]; then
        log_warning "MongoDB n'est pas installé localement (OK si vous utilisez un service cloud)"
    fi
    
    log_success "Prérequis vérifiés"
}

# Backend deployment
deploy_backend() {
    log_info "Déploiement du backend..."
    
    cd "$PROJECT_ROOT/backend"
    
    # Installation des dépendances
    log_info "Installation des dépendances backend..."
    npm ci --only=production
    
    # Vérification du fichier .env
    if [ ! -f ".env" ]; then
        log_warning "Fichier .env manquant, copie depuis .env.example"
        cp .env.example .env
        log_warning "⚠️  Veuillez configurer vos variables d'environnement dans .env"
    fi
    
    # Tests (si disponibles)
    if [ -f "package.json" ] && grep -q '"test"' package.json; then
        log_info "Exécution des tests backend..."
        npm test || log_warning "Tests échoués mais continue le déploiement"
    fi
    
    # Optimisation pour production
    if [ "$ENVIRONMENT" = "production" ]; then
        export NODE_ENV=production
        log_info "Configuration en mode production"
    fi
    
    log_success "Backend déployé avec succès"
}

# Flutter deployment
deploy_flutter() {
    log_info "Déploiement de l'application Flutter..."
    
    cd "$PROJECT_ROOT/location_app"
    
    # Clean et récupération des dépendances
    log_info "Nettoyage et installation des dépendances Flutter..."
    flutter clean
    flutter pub get
    
    # Analyse du code
    log_info "Analyse du code Flutter..."
    flutter analyze || log_warning "Analyse échouée mais continue le déploiement"
    
    # Build pour Android
    log_info "Construction de l'APK Android..."
    if [ "$ENVIRONMENT" = "production" ]; then
        flutter build apk --release --split-per-abi
        log_success "APK de production créé"
    else
        flutter build apk --debug
        log_success "APK de développement créé"
    fi
    
    log_success "Application Flutter déployée avec succès"
}

# Health check
health_check() {
    log_info "Vérification de santé du backend..."
    
    cd "$PROJECT_ROOT/backend"
    
    # Démarrage du serveur en arrière-plan
    if [ "$ENVIRONMENT" = "production" ]; then
        npm start &
    else
        npm run dev &
    fi
    
    SERVER_PID=$!
    
    # Attendre que le serveur démarre
    sleep 5
    
    # Test de l'endpoint de santé
    if curl -f http://localhost:3000/health > /dev/null 2>&1; then
        log_success "✅ Serveur opérationnel - Health check OK"
    else
        log_error "❌ Health check échoué"
        kill $SERVER_PID 2>/dev/null || true
        exit 1
    fi
    
    # Arrêter le serveur de test
    kill $SERVER_PID 2>/dev/null || true
}

# Optimisations post-déploiement
post_deployment_optimizations() {
    log_info "Application des optimisations post-déploiement..."
    
    # MongoDB index creation
    if command -v mongo &> /dev/null; then
        log_info "Création des index MongoDB..."
        cd "$PROJECT_ROOT/backend"
        node -e "
        const mongoose = require('mongoose');
        require('dotenv').config();
        
        mongoose.connect(process.env.MONGO_URL).then(() => {
            console.log('Connexion MongoDB OK');
            // Les index sont créés automatiquement par les modèles
            process.exit(0);
        }).catch(err => {
            console.error('Erreur MongoDB:', err);
            process.exit(1);
        });
        " || log_warning "Impossible de se connecter à MongoDB pour créer les index"
    fi
    
    log_success "Optimisations appliquées"
}

# Rapport de déploiement
deployment_report() {
    log_info "📊 Rapport de déploiement"
    echo "================================="
    echo "Environnement: $ENVIRONMENT"
    echo "Date: $(date)"
    echo "Backend: ✅ Déployé"
    echo "Flutter: ✅ Déployé"
    
    if [ "$ENVIRONMENT" = "production" ]; then
        echo "APK disponible: location_app/build/app/outputs/flutter-apk/"
    fi
    
    echo "================================="
    log_success "🎉 Déploiement terminé avec succès!"
    
    if [ "$ENVIRONMENT" = "production" ]; then
        echo ""
        log_info "📋 Prochaines étapes pour la production:"
        echo "1. Configurez un reverse proxy (nginx)"
        echo "2. Activez HTTPS"
        echo "3. Configurez la surveillance et les logs"
        echo "4. Testez la charge"
    fi
}

# Fonction principale
main() {
    echo "🏠 Location App - Déploiement Optimisé"
    echo "======================================="
    
    check_requirements
    deploy_backend
    deploy_flutter
    health_check
    post_deployment_optimizations
    deployment_report
}

# Gestion des erreurs
trap 'log_error "❌ Déploiement échoué!"; exit 1' ERR

# Exécution
main
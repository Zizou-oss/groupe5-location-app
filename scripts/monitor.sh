#!/bin/bash

# Location App - Script de monitoring
# Usage: ./scripts/monitor.sh [start|stop|status|logs]

set -e

ACTION=${1:-status}
PROJECT_ROOT=$(dirname "$(dirname "$(realpath "$0")")")
LOG_DIR="$PROJECT_ROOT/logs"
PID_FILE="$LOG_DIR/backend.pid"

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] [INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] [SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] [WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR]${NC} $1"
}

# Créer le répertoire de logs
mkdir -p "$LOG_DIR"

# Vérifier l'état du serveur
check_server_status() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if kill -0 "$PID" 2>/dev/null; then
            return 0  # Serveur en cours d'exécution
        else
            rm -f "$PID_FILE"
            return 1  # PID invalide
        fi
    else
        return 1  # Pas de fichier PID
    fi
}

# Démarrer le monitoring
start_monitoring() {
    log_info "🚀 Démarrage du monitoring..."
    
    cd "$PROJECT_ROOT/backend"
    
    if check_server_status; then
        log_warning "Le serveur est déjà en cours d'exécution"
        return 0
    fi
    
    # Démarrer le serveur en arrière-plan
    nohup npm start > "$LOG_DIR/backend.log" 2>&1 &
    echo $! > "$PID_FILE"
    
    # Attendre que le serveur démarre
    sleep 3
    
    if check_server_status; then
        log_success "✅ Serveur démarré avec succès (PID: $(cat "$PID_FILE"))"
        
        # Test de santé
        if curl -f http://localhost:3000/health > /dev/null 2>&1; then
            log_success "✅ Health check OK"
        else
            log_error "❌ Health check échoué"
        fi
    else
        log_error "❌ Échec du démarrage du serveur"
        return 1
    fi
}

# Arrêter le monitoring
stop_monitoring() {
    log_info "🛑 Arrêt du monitoring..."
    
    if check_server_status; then
        PID=$(cat "$PID_FILE")
        kill "$PID"
        rm -f "$PID_FILE"
        log_success "✅ Serveur arrêté (PID: $PID)"
    else
        log_warning "Le serveur n'est pas en cours d'exécution"
    fi
}

# Afficher le statut
show_status() {
    echo "🏠 Location App - Status du Monitoring"
    echo "======================================="
    
    # Statut du serveur
    if check_server_status; then
        PID=$(cat "$PID_FILE")
        log_success "✅ Serveur: EN COURS (PID: $PID)"
        
        # Utilisation mémoire
        if command -v ps &> /dev/null; then
            MEMORY=$(ps -p "$PID" -o rss= 2>/dev/null || echo "N/A")
            if [ "$MEMORY" != "N/A" ]; then
                MEMORY_MB=$((MEMORY / 1024))
                echo "💾 Mémoire: ${MEMORY_MB}MB"
            fi
        fi
        
        # Test de santé
        if curl -f -s http://localhost:3000/health > /dev/null 2>&1; then
            log_success "✅ Health Check: OK"
            
            # Métriques détaillées
            HEALTH_RESPONSE=$(curl -s http://localhost:3000/health 2>/dev/null || echo "{}")
            echo "🕐 Timestamp: $(echo "$HEALTH_RESPONSE" | grep -o '"timestamp":"[^"]*"' | cut -d'"' -f4 || date)"
        else
            log_error "❌ Health Check: ÉCHEC"
        fi
    else
        log_error "❌ Serveur: ARRÊTÉ"
    fi
    
    echo ""
    
    # Statut MongoDB (si disponible)
    if command -v mongo &> /dev/null; then
        if mongo --eval "db.adminCommand('ismaster')" --quiet > /dev/null 2>&1; then
            log_success "✅ MongoDB: CONNECTÉ"
        else
            log_error "❌ MongoDB: DÉCONNECTÉ"
        fi
    fi
    
    # Espace disque
    echo "💽 Espace disque:"
    df -h "$PROJECT_ROOT" | tail -1
    
    # Dernières lignes de log
    if [ -f "$LOG_DIR/backend.log" ]; then
        echo ""
        echo "📋 Dernières lignes de log:"
        tail -5 "$LOG_DIR/backend.log"
    fi
}

# Afficher les logs
show_logs() {
    log_info "📋 Affichage des logs..."
    
    if [ -f "$LOG_DIR/backend.log" ]; then
        echo "=== Logs Backend ==="
        tail -50 "$LOG_DIR/backend.log"
    else
        log_warning "Aucun fichier de log trouvé"
    fi
    
    # Logs en temps réel
    echo ""
    echo "Appuyez sur Ctrl+C pour quitter le suivi des logs"
    tail -f "$LOG_DIR/backend.log" 2>/dev/null || log_error "Impossible de suivre les logs"
}

# Métriques de performance
show_metrics() {
    log_info "📊 Métriques de performance..."
    
    if ! check_server_status; then
        log_error "Le serveur n'est pas en cours d'exécution"
        return 1
    fi
    
    echo "🔄 Test de charge basique..."
    
    # Test de réponse simple
    RESPONSE_TIME=$(curl -w "%{time_total}" -s -o /dev/null http://localhost:3000/health)
    echo "⏱️  Temps de réponse /health: ${RESPONSE_TIME}s"
    
    # Test des propriétés
    PROPERTIES_TIME=$(curl -w "%{time_total}" -s -o /dev/null http://localhost:3000/properties)
    echo "⏱️  Temps de réponse /properties: ${PROPERTIES_TIME}s"
    
    # Utilisation système
    echo ""
    echo "💻 Utilisation système:"
    echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 || echo "N/A")%"
    echo "RAM: $(free | grep Mem | awk '{printf "%.1f%%", $3/$2 * 100.0}' || echo "N/A")"
}

# Menu principal
case $ACTION in
    start)
        start_monitoring
        ;;
    stop)
        stop_monitoring
        ;;
    restart)
        stop_monitoring
        sleep 2
        start_monitoring
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    metrics)
        show_metrics
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs|metrics}"
        echo ""
        echo "Commandes disponibles:"
        echo "  start    - Démarrer le serveur et le monitoring"
        echo "  stop     - Arrêter le serveur"
        echo "  restart  - Redémarrer le serveur"
        echo "  status   - Afficher l'état du système"
        echo "  logs     - Afficher et suivre les logs"
        echo "  metrics  - Afficher les métriques de performance"
        exit 1
        ;;
esac
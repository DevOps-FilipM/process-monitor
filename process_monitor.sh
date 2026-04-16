#!/bin/bash

# process_monitor.sh - System process monitor

# --- CONFIGURATION ---
CPU_THRESHOLD=80        # CPU threshold in %
MEM_THRESHOLD=80        # Memory threshold in %
LOG_FILE="/var/log/process-monitor/monitor.log"
REPORT_DIR="/var/log/process-monitor/reports"
EMAIL_TO="admin@example.com"
EMAIL_FROM="monitor@$(hostname)"

# --- INITIALIZATION ---
mkdir -p "/var/log/process-monitor/reports"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
REPORT_FILE="$REPORT_DIR/report_$(date '+%Y%m%d_%H%M%S').json"

# --- FUNCTIONS ---
log() {
    echo "[$TIMESTAMP] $1" | sudo tee -a "$LOG_FILE"
}

send_alert() {
    local subject="$1"
    local message="$2"

    log "ALERT: $subject"

    # Log to syslog
    logger -t process-monitor "ALERT: $subject"

    # Email (requires configured SMTP)
    if command -v mail &>/dev/null; then
        echo "$message" | mail -s "[ALERT] $subject" "$EMAIL_TO"
        log "Alert email sent to $EMAIL_TO"
    fi
}

# --- DATA COLLECTION ---
log "Starting process monitoring..."

# Processes with high CPU usage
high_cpu=$(ps aux --sort=-%cpu | awk -v threshold="$CPU_THRESHOLD" '
    NR>1 && $3+0 >= threshold {
        printf "{\"pid\":\"%s\",\"user\":\"%s\",\"cpu\":\"%s\",\"mem\":\"%s\",\"command\":\"%s\"},\n",
        $2, $1, $3, $4, $11
    }
')

# Processes with high memory usage
high_mem=$(ps aux --sort=-%mem | awk -v threshold="$MEM_THRESHOLD" '
    NR>1 && $4+0 >= threshold {
        printf "{\"pid\":\"%s\",\"user\":\"%s\",\"cpu\":\"%s\",\"mem\":\"%s\",\"command\":\"%s\"},\n",
        $2, $1, $3, $4, $11
    }
')

# Remove trailing comma from last entry
high_cpu=$(echo "$high_cpu" | sed '$ s/,$//')
high_mem=$(echo "$high_mem" | sed '$ s/,$//')

# --- JSON REPORT GENERATION ---
cat > "$REPORT_FILE" << REPORT
{
    "timestamp": "$TIMESTAMP",
    "hostname": "$(hostname)",
    "thresholds": {
        "cpu": $CPU_THRESHOLD,
        "memory": $MEM_THRESHOLD
    },
    "system": {
        "cpu_usage": "$(top -bn1 | grep 'Cpu(s)' | awk '{print $2}')%",
        "memory_usage": "$(free | awk '/Mem:/ {printf "%.1f", $3/$2*100}')%",
        "load_average": "$(uptime | awk -F'load average:' '{print $2}' | xargs)"
    },
    "high_cpu_processes": [
        ${high_cpu:-}
    ],
    "high_memory_processes": [
        ${high_mem:-}
    ]
}
REPORT

log "Report saved: $REPORT_FILE"

# --- ALERTS ---
if [[ -n "$high_cpu" ]]; then
    send_alert "High CPU usage detected on $(hostname)" "$(cat $REPORT_FILE)"
fi

if [[ -n "$high_mem" ]]; then
    send_alert "High memory usage detected on $(hostname)" "$(cat $REPORT_FILE)"
fi

# --- DISPLAY REPORT ---
cat "$REPORT_FILE"

log "Monitoring completed."

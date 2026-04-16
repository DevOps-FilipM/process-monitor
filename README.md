# Process Monitor

A bash script for monitoring system processes and alerting on high CPU/memory usage.

## Features
- Monitors processes exceeding CPU and memory thresholds
- Generates JSON reports with system metrics
- Sends email alerts (requires configured SMTP)
- Logs all activity to system log

## Requirements
- Linux (Ubuntu/Debian)
- postfix + mailutils (for email alerts)
- sudo privileges

## Configuration

Edit the following variables in `process_monitor.sh`:

| Variable | Default | Description |
|---|---|---|
| `CPU_THRESHOLD` | 80 | CPU usage threshold in % |
| `MEM_THRESHOLD` | 80 | Memory usage threshold in % |
| `EMAIL_TO` | admin@example.com | Alert recipient email |
| `LOG_FILE` | /var/log/process-monitor/monitor.log | Log file path |
| `REPORT_DIR` | /var/log/process-monitor/reports | JSON reports directory |

## Usage

```bash
# Run manually
sudo ./process_monitor.sh

# Run automatically every 10 minutes via cron
(sudo crontab -l 2>/dev/null; echo "*/10 * * * * /path/to/process_monitor.sh") | sudo crontab -
```

## Email Configuration

SMTP credentials template is located at `/etc/postfix/sasl_passwd`.
Configuration options for Gmail, SendGrid and Mailgun are available in `/etc/postfix/smtp_config`.

## Report Format

Reports are saved as JSON files in `REPORT_DIR`:

```json
{
    "timestamp": "2026-04-16 11:01:27",
    "hostname": "LearnIT-LinuxVM",
    "thresholds": {
        "cpu": 80,
        "memory": 80
    },
    "system": {
        "cpu_usage": "0.0%",
        "memory_usage": "50.8%",
        "load_average": "0.02, 0.20, 0.41"
    },
    "high_cpu_processes": [],
    "high_memory_processes": []
}
```

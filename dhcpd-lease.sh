#!/bin/sh
# dhcp_lease_parser.sh - Enhanced BSD dhcpcd lease parser
# Author: Andrew Smalley
# License: BSD-3
# Version: 2.0
# Origional Author: Peter Andersson, peter@it-slav.net

# =======================
# Default Configuration
# =======================
LEASE_FILE="/var/db/dhcpd.leases"
LOG_FILE="/var/log/dhcp_lease_parser.log"
NOTIFICATION_THRESHOLD=86400  # Seconds (default: 1 day)
OUTPUT_FORMAT="table"          # Options: table, csv, json

# =======================
# Function Definitions
# =======================

# Display the help message
show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  -f, --file FILE            Specify the DHCP lease file path (default: /var/db/dhcpd.leases)
  -o, --output FORMAT        Specify output format: table (default), csv, json
  --filter-ip IP_RANGE        Filter leases by IP range (e.g., 192.168.1.100-192.168.1.200)
  --filter-mac MAC_ADDRESS    Filter leases by MAC address (e.g., aa:bb:cc:dd:ee:ff)
  --filter-hostname HOSTNAME  Filter leases by hostname
  --notify                   Enable notifications for leases nearing expiration
  --threshold SECONDS         Set notification threshold in seconds (default: 86400)
  --log FILE                  Specify a log file path (default: /var/log/dhcp_lease_parser.log)
  --help                     Display this help message
  --about                    Display information about this script

Examples:
  $(basename "$0") --output csv
  $(basename "$0") --filter-ip 192.168.1.100-192.168.1.200 --notify
EOF
}

# Display the about message
show_about() {
    cat << EOF
dhcp_lease_parser.sh - Enhanced DHCP Lease Parser

Version: 2.0
Author: [Your Name]
License: BSD-3

This script parses the BSD dhcpcd DHCP lease file, providing formatted output,
filtering options, logging, and notifications for leases nearing expiration.

EOF
}

# Log messages with timestamp
log_message() {
    local message="$1"
    echo "$(date '+%Y/%m/%d %H:%M:%S') - $message" >> "$LOG_FILE"
}

# Send notifications for leases nearing expiration
send_notification() {
    local ip="$1"
    local hostname="$2"
    local end_time="$3"
    # Example: Send a desktop notification (requires 'notify-send' on Linux)
    # You can customize this function to send emails or other types of notifications
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "DHCP Lease Expiration Alert" "Lease for $hostname ($ip) expires at $end_time."
    else
        # Fallback: Log the notification if notify-send is not available
        log_message "Notification: Lease for $hostname ($ip) expires at $end_time."
    fi
}

# Parse command-line arguments
parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            -f|--file)
                LEASE_FILE="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_FORMAT="$2"
                shift 2
                ;;
            --filter-ip)
                FILTER_IP_RANGE="$2"
                shift 2
                ;;
            --filter-mac)
                FILTER_MAC="$2"
                shift 2
                ;;
            --filter-hostname)
                FILTER_HOSTNAME="$2"
                shift 2
                ;;
            --notify)
                ENABLE_NOTIFY=1
                shift
                ;;
            --threshold)
                NOTIFICATION_THRESHOLD="$2"
                shift 2
                ;;
            --log)
                LOG_FILE="$2"
                shift 2
                ;;
            --help)
                show_help
                exit 0
                ;;
            --about)
                show_about
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Validate IP range filter
validate_ip_range() {
    if echo "$FILTER_IP_RANGE" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+-[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'; then
        :
    else
        echo "Error: Invalid IP range format. Use startIP-endIP (e.g., 192.168.1.100-192.168.1.200)" >&2
        exit 1
    fi
}

# Convert IP to a comparable number
ip_to_num() {
    awk -v ip="$1" 'BEGIN{
        split(ip, octets, ".")
        print octets[1]*16777216 + octets[2]*65536 + octets[3]*256 + octets[4]
    }'
}

# Apply filters to a lease
apply_filters() {
    local ip="$1"
    local mac="$2"
    local hostname="$3"
    local start_epoch="$4"
    local end_epoch="$5"

    # Filter by IP range
    if [ -n "$FILTER_IP_RANGE" ]; then
        IFS='-' read -r start_ip end_ip <<EOF
$FILTER_IP_RANGE
EOF
        start_num=$(ip_to_num "$start_ip")
        end_num=$(ip_to_num "$end_ip")
        current_num=$(ip_to_num "$ip")
        if [ "$current_num" -lt "$start_num" ] || [ "$current_num" -gt "$end_num" ]; then
            return 1
        fi
    fi

    # Filter by MAC address
    if [ -n "$FILTER_MAC" ]; then
        if [ "$mac" != "$FILTER_MAC" ]; then
            return 1
        fi
    fi

    # Filter by Hostname
    if [ -n "$FILTER_HOSTNAME" ]; then
        if [ "$hostname" != "$FILTER_HOSTNAME" ]; then
            return 1
        fi
    fi

    return 0
}

# =======================
# Main Script Execution
# =======================

# Parse command-line arguments
parse_args "$@"

# Validate IP range if set
if [ -n "$FILTER_IP_RANGE" ]; then
    validate_ip_range
fi

# Check if lease file exists and is readable
if [ ! -r "$LEASE_FILE" ]; then
    echo "Error: Cannot read lease file '$LEASE_FILE'" >&2
    log_message "Error: Cannot read lease file '$LEASE_FILE'"
    exit 1
fi

# Log script start
log_message "Script started. Parsing lease file '$LEASE_FILE'."

# Get current epoch time in UTC
current_epoch=$(date -u +%s)

# Initialize output storage
declare -A latest_start_epoch
declare -A latest_end_epoch
declare -A latest_mac
declare -A latest_hostname

# Parse the lease file using gawk
gawk -v current_epoch="$current_epoch" '
function parse_time(weekday, ymd, time,    split_ymd, split_time, year, month, day, hour, min, sec) {
    split(ymd, split_ymd, "/")
    split(time, split_time, ":")
    year = split_ymd[1]
    month = split_ymd[2]
    day = split_ymd[3]
    hour = split_time[1]
    min = split_time[2]
    sec = split_time[3]
    return mktime(year " " month " " day " " hour " " min " " sec)
}

BEGIN {
    FS = "[ ;]+"
}

{
    if ($1 == "lease") {
        ip = $2
        in_lease = 1
        hostname = "-"
        mac = "-"
        start_epoch = 0
        end_epoch = 0
    }
    else if (in_lease) {
        if ($1 == "client-hostname") {
            gsub(/"/, "", $2)
            hostname = $2
        }
        else if ($1 == "hardware" && $2 == "ethernet") {
            mac = $3
        }
        else if ($1 == "starts") {
            start_epoch = parse_time($2, $3, $4)
        }
        else if ($1 == "ends") {
            end_epoch = parse_time($2, $3, $4)
        }
        else if ($1 == "}") {
            in_lease = 0
            # Only include active leases
            if (current_epoch < end_epoch) {
                # For each IP, keep the lease with the latest start time
                if (!(ip in latest_start_epoch) || start_epoch > latest_start_epoch[ip]) {
                    latest_start_epoch[ip] = start_epoch
                    latest_end_epoch[ip] = end_epoch
                    latest_mac[ip] = mac
                    latest_hostname[ip] = hostname
                }
            }
        }
    }
}

END {
    for (ip in latest_start_epoch) {
        printf "%s\t%s\t%d\t%d\t%s\n", ip, latest_mac[ip], latest_start_epoch[ip], latest_end_epoch[ip], latest_hostname[ip]
    }
}' "$LEASE_FILE" > /tmp/dhcp_leases.tmp

# Process the parsed leases
output=""
IFS=$'\n'
for line in $(cat /tmp/dhcp_leases.tmp); do
    ip=$(echo "$line" | awk '{print $1}')
    mac=$(echo "$line" | awk '{print $2}')
    start_epoch=$(echo "$line" | awk '{print $3}')
    end_epoch=$(echo "$line" | awk '{print $4}')
    hostname=$(echo "$line" | awk '{print $5}')

    # Apply filters
    if apply_filters "$ip" "$mac" "$hostname" "$start_epoch" "$end_epoch"; then
        # Calculate if notification is needed
        if [ "$ENABLE_NOTIFY" -eq 1 ]; then
            time_left=$(( end_epoch - current_epoch ))
            if [ "$time_left" -le "$NOTIFICATION_THRESHOLD" ]; then
                end_time=$(date -u -d "@$end_epoch" +"%Y/%m/%d %H:%M:%S UTC")
                send_notification "$ip" "$hostname" "$end_time"
            fi
        fi

        # Prepare output based on format
        if [ "$OUTPUT_FORMAT" = "table" ]; then
            start_time=$(date -u -d "@$start_epoch" +"%Y/%m/%d %H:%M:%S UTC")
            end_time=$(date -u -d "@$end_epoch" +"%Y/%m/%d %H:%M:%S UTC")
            output="$output$ip\t$mac\t$start_time\t$end_time\t$hostname\n"
        elif [ "$OUTPUT_FORMAT" = "csv" ]; then
            start_time=$(date -u -d "@$start_epoch" +"%Y/%m/%d %H:%M:%S UTC")
            end_time=$(date -u -d "@$end_epoch" +"%Y/%m/%d %H:%M:%S UTC")
            output="$output\"$ip\",\"$mac\",\"$start_time\",\"$end_time\",\"$hostname\"\n"
        elif [ "$OUTPUT_FORMAT" = "json" ]; then
            start_time=$(date -u -d "@$start_epoch" +"%Y/%m/%d %H:%M:%S UTC")
            end_time=$(date -u -d "@$end_epoch" +"%Y/%m/%d %H:%M:%S UTC")
            # Escape quotes in hostname
            escaped_hostname=$(echo "$hostname" | sed 's/"/\\"/g')
            output="$output{\"ip\":\"$ip\",\"mac\":\"$mac\",\"start_time\":\"$start_time\",\"end_time\":\"$end_time\",\"hostname\":\"$escaped_hostname\"},\n"
        fi
    fi
done

# Output the results
if [ "$OUTPUT_FORMAT" = "table" ]; then
    printf "%-15s\t%-17s\t%-20s\t%-20s\t%s\n" "IP" "HW Address" "Lease Start" "Lease End" "Hostname"
    printf "$output" | sort -V
elif [ "$OUTPUT_FORMAT" = "csv" ]; then
    echo "IP,HW Address,Lease Start,Lease End,Hostname"
    printf "$output" | sed '$ s/,$//'  # Remove trailing comma
elif [ "$OUTPUT_FORMAT" = "json" ]; then
    echo "["
    # Remove the last comma and newline
    printf "$output" | sed '$ s/,$//' 
    echo "]"
fi

# Log script completion
log_message "Script completed successfully."

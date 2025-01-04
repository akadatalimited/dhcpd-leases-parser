DHCP Lease Parser

Version: 2.0
Author: [Your Name]
License: BSD-3
Date: January 4, 2025
Table of Contents

    Overview
    Features
    Prerequisites
    Installation
    Usage
        Basic Usage
        Command-Line Options
        Examples
    Output Formats
    Filtering Options
    Logging
    Notifications
    Sample Outputs
    Dependencies
    Contributing
    License
    About

Overview

The DHCP Lease Parser is a shell script designed to parse BSD dhcpcd DHCP lease files (/var/db/dhcpd.leases). It provides formatted output, filtering options, logging, and notifications for leases nearing expiration. This tool aids network administrators in managing and monitoring DHCP leases efficiently.
Features

    Accurate Date Handling: Converts lease dates to epoch time for precise comparisons.
    Multiple Output Formats: Supports table (default), CSV, and JSON outputs.
    Filtering Options: Filter leases by IP range, MAC address, or hostname.
    Logging: Logs script executions, errors, and notifications.
    Notifications: Sends desktop notifications for leases approaching expiration.
    Flexible Configuration: Specify custom lease files, log files, and notification thresholds.
    Help and About Information: Provides --help and --about options for user guidance.

Prerequisites

    Shell Environment: Compatible with Bourne shell (sh).
    GNU Awk (gawk): Required for advanced date parsing.
    Notify-send (Optional): For desktop notifications on Linux systems.

Installation

    Clone the Repository:

git clone https://github.com/yourusername/dhcp-lease-parser.git
cd dhcp-lease-parser

Make the Script Executable:

chmod +x dhcp_lease_parser.sh

Install Dependencies:

    On BSD:

pkg install gawk

On Linux (Debian/Ubuntu):

        sudo apt-get update
        sudo apt-get install gawk libnotify-bin

        Note: notify-send is optional. If not installed, notifications will be logged instead.

Usage
Basic Usage

Parse the default DHCP lease file and display active leases in a table format.

./dhcp_lease_parser.sh

Command-Line Options
Short	Long	Description	Default
-f	--file FILE	Specify the DHCP lease file path.	/var/db/dhcpd.leases
-o	--output FORMAT	Specify output format: table (default), csv, json.	table
	--filter-ip RANGE	Filter leases by IP range (e.g., 192.168.1.100-192.168.1.200).	None
	--filter-mac MAC	Filter leases by MAC address (e.g., aa:bb:cc:dd:ee:ff).	None
	--filter-hostname NAME	Filter leases by hostname.	None
	--notify	Enable notifications for leases nearing expiration.	Disabled
	--threshold SECONDS	Set notification threshold in seconds (e.g., 86400 for 1 day).	86400 (1 day)
	--log FILE	Specify a log file path.	/var/log/dhcp_lease_parser.log
	--help	Display the help message.	
	--about	Display information about the script.	
Examples

    Default Usage:

./dhcp_lease_parser.sh

Specify a Custom Lease File:

./dhcp_lease_parser.sh --file /path/to/custom/dhcpd.leases

Change Output Format to CSV:

./dhcp_lease_parser.sh --output csv

Change Output Format to JSON:

./dhcp_lease_parser.sh --output json

Filter by IP Range:

./dhcp_lease_parser.sh --filter-ip 192.168.1.100-192.168.1.200

Filter by MAC Address:

./dhcp_lease_parser.sh --filter-mac aa:bb:cc:dd:ee:ff

Filter by Hostname:

./dhcp_lease_parser.sh --filter-hostname mydevice

Enable Notifications for Leases Nearing Expiration:

./dhcp_lease_parser.sh --notify

    Custom Notification Threshold (e.g., 12 hours):

    ./dhcp_lease_parser.sh --notify --threshold 43200

Specify a Custom Log File:

./dhcp_lease_parser.sh --log /path/to/custom.log

Display Help Message:

./dhcp_lease_parser.sh --help

Display About Information:

./dhcp_lease_parser.sh --about

Combined Options Example:

    ./dhcp_lease_parser.sh --file /var/db/dhcpd.leases --output json --filter-ip 192.168.1.100-192.168.1.150 --notify --threshold 7200

        Description: Parses a custom lease file, outputs in JSON format, filters leases within the specified IP range, and sends notifications for leases expiring within the next 2 hours.

Output Formats
Table Format (Default)

A human-readable table with aligned columns.

./dhcp_lease_parser.sh

Output:

IP              HW Address          Lease Start           Lease End             Hostname
192.168.1.100   aa:bb:cc:dd:ee:ff   2025/01/03 12:34:56 UTC   2025/01/03 14:34:56 UTC   mydevice
192.168.1.101   11:22:33:44:55:66   2025/01/03 13:00:00 UTC   2025/01/03 15:00:00 UTC   anotherdevice

CSV Format

Comma-Separated Values suitable for spreadsheets and data processing.

./dhcp_lease_parser.sh --output csv

Output:

IP,HW Address,Lease Start,Lease End,Hostname
"192.168.1.100","aa:bb:cc:dd:ee:ff","2025/01/03 12:34:56 UTC","2025/01/03 14:34:56 UTC","mydevice"
"192.168.1.101","11:22:33:44:55:66","2025/01/03 13:00:00 UTC","2025/01/03 15:00:00 UTC","anotherdevice"

JSON Format

Structured JSON output for API integrations and data processing.

./dhcp_lease_parser.sh --output json

Output:

[
{"ip":"192.168.1.100","mac":"aa:bb:cc:dd:ee:ff","start_time":"2025/01/03 12:34:56 UTC","end_time":"2025/01/03 14:34:56 UTC","hostname":"mydevice"},
{"ip":"192.168.1.101","mac":"11:22:33:44:55:66","start_time":"2025/01/03 13:00:00 UTC","end_time":"2025/01/03 15:00:00 UTC","hostname":"anotherdevice"}
]

Filtering Options

Enhance the relevance of your lease data by applying filters.
Filter by IP Range

Include only leases within a specific IP range.

./dhcp_lease_parser.sh --filter-ip 192.168.1.100-192.168.1.200

Filter by MAC Address

Include only leases with a specific MAC address.

./dhcp_lease_parser.sh --filter-mac aa:bb:cc:dd:ee:ff

Filter by Hostname

Include only leases with a specific hostname.

./dhcp_lease_parser.sh --filter-hostname mydevice

Logging

Maintain a log of script executions, errors, and notifications.

    Default Log File: /var/log/dhcp_lease_parser.log

    Specify a Custom Log File:

    ./dhcp_lease_parser.sh --log /path/to/custom.log

    Log Contents Include:
        Script start and completion messages
        Errors (e.g., unreadable lease files)
        Notifications about lease expirations

    Note: Ensure the script has write permissions to the specified log file.

Notifications

Receive alerts when leases are nearing expiration.

    Enable Notifications:

./dhcp_lease_parser.sh --notify

Set Notification Threshold (in seconds):

    ./dhcp_lease_parser.sh --notify --threshold 43200  # 12 hours

    Notification Mechanism:
        Desktop Notifications: Uses notify-send on Linux systems.
        Fallback: Logs the notification if notify-send is unavailable.

    Customize Notifications:
        Modify the send_notification function in the script to integrate other notification methods (e.g., email, Slack).

Sample Outputs
Table Format

IP              HW Address          Lease Start           Lease End             Hostname
192.168.1.100   aa:bb:cc:dd:ee:ff   2025/01/03 12:34:56 UTC   2025/01/03 14:34:56 UTC   mydevice
192.168.1.101   11:22:33:44:55:66   2025/01/03 13:00:00 UTC   2025/01/03 15:00:00 UTC   anotherdevice

CSV Format

IP,HW Address,Lease Start,Lease End,Hostname
"192.168.1.100","aa:bb:cc:dd:ee:ff","2025/01/03 12:34:56 UTC","2025/01/03 14:34:56 UTC","mydevice"
"192.168.1.101","11:22:33:44:55:66","2025/01/03 13:00:00 UTC","2025/01/03 15:00:00 UTC","anotherdevice"

JSON Format

[
{"ip":"192.168.1.100","mac":"aa:bb:cc:dd:ee:ff","start_time":"2025/01/03 12:34:56 UTC","end_time":"2025/01/03 14:34:56 UTC","hostname":"mydevice"},
{"ip":"192.168.1.101","mac":"11:22:33:44:55:66","start_time":"2025/01/03 13:00:00 UTC","end_time":"2025/01/03 15:00:00 UTC","hostname":"anotherdevice"}
]

Dependencies

Ensure the following dependencies are installed on your system:

    GNU Awk (gawk): Advanced features for parsing and date handling.

        Installation on BSD:

pkg install gawk

Installation on Linux (Debian/Ubuntu):

    sudo apt-get install gawk

Notify-send (Optional): For sending desktop notifications on Linux systems.

    Installation on Debian/Ubuntu:

        sudo apt-get install libnotify-bin

    Standard Unix Utilities:
        awk, sed, date

Contributing

Contributions are welcome! Please follow these steps:

    Fork the Repository.

    Create a Feature Branch:

git checkout -b feature/YourFeature

Commit Your Changes:

git commit -m "Add YourFeature"

Push to the Branch:

    git push origin feature/YourFeature

    Open a Pull Request.

Please ensure your code adheres to the project's coding standards and includes appropriate documentation.
License

This project is licensed under the BSD-3 License.
About

dhcp_lease_parser.sh is an enhanced DHCP lease parser script designed to assist network administrators in managing and monitoring DHCP leases on BSD and other Unix-like systems. It offers robust features such as multiple output formats, filtering options, logging, and notifications, making it a versatile tool for network management.

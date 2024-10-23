#!/bin/bash
script_name=$(basename "$0")

# Extract the filename without the extension
filename="${script_name%.*}"

if ! grep -q "alias $filename" ~/.bashrc; then
    echo "Adding '$filename' alias to ~/.bashrc"

    # Append the alias to ~/.bashrc
    echo "alias $filename='$script_name'" >> ~/.bashrc

    # Reload the bashrc file to make the alias immediately available
    source ~/.bashrc
    echo "Alias '$filename' added successfully."
else
    echo "'$filename' alias already exists in ~/.bashrc."
fi

# Variables
ODOO_SERVICE=$1    # Odoo service name passed as the first argument
MODULE_NAME=$2     # Module name passed as the second argument

# Color codes
GREEN="\e[32m"
RED="\e[31m"
NC="\e[0m" # No Color

# Check if service name and module name are provided
if [ -z "$ODOO_SERVICE" ] || [ -z "$MODULE_NAME" ]; then
    echo "Usage: $filename <odoo_service> <module_name>"
    exit 1
fi

SERVICE_FILE_PATH=$(systemctl show -p FragmentPath $ODOO_SERVICE | cut -d'=' -f2)

if [ -z "$SERVICE_FILE_PATH" ]; then
    echo "Could not retrieve the service file path for $ODOO_SERVICE."
    exit 1
fi

if [ ! -f "$SERVICE_FILE_PATH" ]; then
    echo "Service file for $ODOO_SERVICE not found!"
    exit 1
fi

EXEC_START=$(grep -oP 'ExecStart=\K.*' "$SERVICE_FILE_PATH")

if [ -z "$EXEC_START" ]; then
    echo "No ExecStart line found in the service file."
    exit 1
fi

# Prepare the command to update the module
ODOO_ONELINE="$EXEC_START -u $MODULE_NAME --stop-after-init"

# Stop Odoo service
sudo systemctl stop $ODOO_SERVICE

# Execute the command to update the module and suppress output
$ODOO_ONELINE

# Start Odoo service
sudo systemctl start $ODOO_SERVICE
echo
echo -e "${GREEN}Module '$MODULE_NAME' has been successfully updated.${NC}"
echo


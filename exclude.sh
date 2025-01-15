#!/bin/bash

# Check for required arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <tagName> <tagValue> [--subscription <subscriptionID>]"
    exit 1
fi

# Variables
tagName=$1
tagValue=$2
specific_subscription=""

# Check for optional --subscription flag
if [ "$3" == "--subscription" ]; then
    if [ -n "$4" ]; then
        specific_subscription=$4
        echo "Processing only subscription: $specific_subscription"
    else
        echo "Error: Missing subscription ID after --subscription"
        exit 1
    fi
fi

# Counters
count_vms=0
count_subscript=0

# Function to process VMs in a subscription
process_subscription() {
    local subscription=$1
    ((count_subscript++))
    echo "Processing subscription: $subscription (${count_subscript} of ${total_subscriptions})"

    # Get all VMs with the specific tag in the subscription
    mapfile -t vms < <(az vm list --subscription "$subscription" --query "[?tags.$tagName=='$tagValue'].id" -o tsv)
    total_vms=${#vms[@]}

    if [ $total_vms -eq 0 ]; then
        echo "No VMs found with tag $tagName=$tagValue in subscription $subscription."
        return
    fi

    # Loop through each VM and remove it from all maintenance configurations
    for vm in "${vms[@]}"; do
        ((count_vms++))
        echo "Processing VM: $vm (${count_vms} of $total_vms in this subscription)"

        # Get all maintenance configurations for the VM
        mapfile -t maintenanceConfigs < <(az maintenance configuration-assignment list --resource-id "$vm" --query "[].name" -o tsv)

        # Remove the VM from each maintenance configuration
        for config in "${maintenanceConfigs[@]}"; do
            echo "Removing maintenance configuration $config from $vm"
            az maintenance configuration-assignment delete --resource-id "$vm" --name "$config"
        done
    done
}

# Process the specified subscription or all subscriptions
if [ -n "$specific_subscription" ]; then
    total_subscriptions=1
    process_subscription "$specific_subscription"
else
    mapfile -t subscriptions < <(az account list --query "[].id" -o tsv --all)
    total_subscriptions=${#subscriptions[@]}
    
    for subscription in "${subscriptions[@]}"; do
        process_subscription "$subscription"
    done
fi

echo "VMs with tag $tagName=$tagValue have been excluded from all maintenance configurations across all subscriptions."

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

# Enable Maintenance Extension
az extension add --name maintenance

# Counters
count_resources=0
count_subscript=0

# Function to process VMs and Arc-enabled machines in a subscription
process_subscription() {
    echo "This will take a long time, it will go through each connected resource. Be patient, be kind, do not CTRL-C me please"
    local subscription=$1
    ((count_subscript++))
    echo "Processing subscription: $subscription (${count_subscript} of ${total_subscriptions})"

    # Get all VMs and Arc-enabled machines with the specific tag in the subscription
    mapfile -t resources < <(
        az resource list --subscription "$subscription" --query "[?tags.$tagName=='$tagValue'].id" -o tsv
    )
    total_resources=${#resources[@]}

    if [ $total_resources -eq 0 ]; then
        echo "No resources found with tag $tagName=$tagValue in subscription $subscription."
        return
    fi

    # Loop through each resource and remove it from all maintenance configurations
    for resource_id in "${resources[@]}"; do
        ((count_resources++))
        echo "Processing resource: $resource_id (${count_resources} of $total_resources in this subscription)"

        # Get all maintenance configurations for the resource
        mapfile -t maintenanceConfigs < <(
            az maintenance configuration-assignment list --resource-id "$resource_id" --query "[].name" -o tsv
        )

        # Remove the resource from each maintenance configuration
        for config in "${maintenanceConfigs[@]}"; do
            echo "Removing maintenance configuration $config from $resource_id"
            az maintenance configuration-assignment delete --resource-id "$resource_id" --name "$config"
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

echo "Resources with tag $tagName=$tagValue have been excluded from all maintenance configurations across all subscriptions."

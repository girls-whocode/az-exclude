#!/bin/bash
# Written by Jessica Brown v2.3.4
# Version includes ability to use arguments:
#    ./exclude <tagName> <tagValue> # These are required
# --subscription <ID> is optional

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

# Check if the maintenance extension is installed
if ! az extension show --name maintenance &>/dev/null; then
    echo "Installing Azure Maintenance extension..."
    az extension add --name maintenance
else
    echo "Azure Maintenance extension is already installed."
fi

# Counters
count_resources=0
count_subscript=0
count_configs_removed=0

# Function to process resources in a subscription
process_subscription() {
    local subscription=$1
    ((count_subscript++))
    echo "Processing subscription: $subscription (${count_subscript} of ${total_subscriptions})"

    # Get all resources with the specific tag in the subscription
    mapfile -t resources < <(
        az resource list --subscription "$subscription" --query "[?tags.$tagName=='$tagValue'].{id:id, resourceGroup:resourceGroup, name:name, type:type}" -o tsv
    )
    total_resources=${#resources[@]}

    if [ $total_resources -eq 0 ]; then
        echo "No resources found with tag $tagName=$tagValue in subscription $subscription."
        return
    fi

    # Loop through each resource and remove it from all maintenance configurations
    for resource in "${resources[@]}"; do
        ((count_resources++))
        read -r resource_id resource_group resource_name resource_type <<<"$resource"

        echo "Processing resource: $resource_name (${count_resources} of $total_resources in this subscription)"

        # Check if the resource is an Arc-enabled machine
        if [[ "$resource_type" == "Microsoft.HybridCompute/machines" ]]; then
            echo "This is an Arc-enabled machine. Checking for maintenance assignments."

            # Get all maintenance assignments for the Arc-enabled machine
            mapfile -t maintenanceConfigs < <(
                az maintenance assignment list \
                --provider-name Microsoft.HybridCompute \
                --resource-group "$resource_group" \
                --resource-name "$resource_name" \
                --resource-type machines \
                --query "[].name" -o tsv
            )

            if [ ${#maintenanceConfigs[@]} -eq 0 ]; then
                echo "No maintenance assignments found for $resource_name"
                continue
            fi

            # Remove the Arc-enabled machine from each maintenance configuration
            for config in "${maintenanceConfigs[@]}"; do
                echo "Removing maintenance configuration $config from $resource_name"
                az maintenance assignment delete \
                    --provider-name Microsoft.HybridCompute \
                    --resource-group "$resource_group" \
                    --resource-name "$resource_name" \
                    --resource-type machines \
                    --name "$config"

                ((count_configs_removed++))
            done

        else
            echo "Skipping non-Arc resource: $resource_name"
        fi
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

# Final Summary
if [ $count_configs_removed -eq 0 ]; then
    echo "No maintenance assignments found to remove."
else
    echo "Total maintenance configurations removed: $count_configs_removed"
fi

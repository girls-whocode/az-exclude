# **Azure VM Maintenance Configuration Exclusion Script Documentation**

## **Prerequisites**
To run this script successfully, ensure you have the following Azure roles and permissions assigned:

| **Role**                        | **Resource**                      | **Resource Type**       | **Membership** |
|---------------------------------|-----------------------------------|------------------------|----------------|
| Azure Update Manager Contributor | Computershare                     | Management Group        | Direct         |
| Azure Update Manager Contributor | CPU-CTS-APIM-Corp-UAT-001         | Subscription            | Direct         |
| Contributor                     | CPU-CTS-Online-Prod-001           | Subscription            | Direct         |
| Virtual Machine User Login      | Computershare                     | Management Group        | Direct         |

## **Accessing Azure Cloud Shell**
1. In the **Azure Portal**, click on the **Cloud Shell** icon in the top blue bar (it looks like a terminal window).
2. Select **Bash** as the shell type.
3. Choose **No storage account required** and click **Apply**.

Once the shell is ready, proceed to create and run the script.

---

## **Creating and Saving the Script**
1. In the Cloud Shell, type the following command to open a text editor:
   ```bash
   nano exclude.sh
   ```
2. Copy and paste the script into the editor.
3. Save and exit the editor by pressing **CTRL+O**, then **Enter**, followed by **CTRL+X**.

4. Make the script executable:
   ```bash
   chmod +x exclude.sh
   ```

5. Run the script:
   ```bash
   ./exclude.sh <tagName> <tagValue> [--subscription <subscriptionID>]
   ```

---

## **Script Options Explained**
### **Required Arguments:**
- **`<tagName>`**: The name of the tag you want to filter resources by.
- **`<tagValue>`**: The value of the tag you want to filter resources by.

### **Optional Argument:**
- **`--subscription <subscriptionID>`**: Specify a particular subscription to target. If this option is not provided, the script will process **all subscriptions** available to your account.

### **Example Usage:**
#### **Run for All Subscriptions:**
```bash
./exclude.sh Comments patchingFalse
```
This will find all resources with the tag `Comments=patchingFalse` across all subscriptions and remove them from maintenance configurations.

#### **Run for a Specific Subscription:**
```bash
./exclude.sh Comments patchingFalse --subscription 72984e2c-183d-883c-721e-679354286185
```
This will find all resources with the tag `Comments=patchingFalse` in the specified subscription and remove them from maintenance configurations.

---

## **Script Breakdown**
### **Version: v2.3.4**
Written by: **Jessica Brown**

### **Key Features:**
- Dynamically detects resources with a specific tag.
- Identifies **Arc-enabled machines** and removes their maintenance configurations.
- Processes either a specific subscription or all subscriptions.
- Provides a final summary of removed maintenance configurations.

### **Script Logic:**
1. **Argument Validation:**
   The script requires at least two arguments (`tagName` and `tagValue`). It checks if the optional `--subscription` argument is provided.

2. **Azure Maintenance Extension Check:**
   The script ensures the **`maintenance`** Azure CLI extension is installed.

3. **Resource Processing:**
   The script loops through resources in the specified subscriptions, identifying those with the specified tag.

4. **Arc-Enabled Machine Handling:**
   For **Arc-enabled machines**, the script lists and removes maintenance configurations using the **`az maintenance assignment`** commands.

5. **Final Summary:**
   The script outputs the total number of maintenance configurations removed. If none were removed, it displays a message: *"No maintenance assignments found to remove."*

---

## **Script Output Examples**
### **Example Output: No Maintenance Assignments Found**
```bash
Azure Maintenance extension is already installed.
Processing subscription: 72984e2c-183d-883c-721e-679354286185 (1 of 1)
Processing resource: watadadocm03.americas.cshare.net (1 of 1 in this subscription)
This is an Arc-enabled machine. Checking for maintenance assignments.
No maintenance assignments found for watadadocm03.americas.cshare.net
No maintenance assignments found to remove.
```

### **Example Output: Maintenance Assignments Removed**
```bash
Azure Maintenance extension is already installed.
Processing subscription: 72984e2c-183d-883c-721e-679354286185 (1 of 1)
Processing resource: watadadocm03.americas.cshare.net (1 of 1 in this subscription)
This is an Arc-enabled machine. Checking for maintenance assignments.
Removing maintenance configuration NightlyUpdates from watadadocm03.americas.cshare.net
Removing maintenance configuration WeeklyReboots from watadadocm03.americas.cshare.net
Total maintenance configurations removed: 2
```

---

## **Troubleshooting**
If you encounter any issues, ensure that:
1. **You have the necessary Azure roles and permissions.**
2. **The `maintenance` Azure CLI extension is installed.**
3. **The correct `tagName` and `tagValue` are used.**

### **Common Errors:**
| **Error**                             | **Cause**                                            | **Solution**                                          |
|--------------------------------------|----------------------------------------------------|------------------------------------------------------|
| "No resources found with tag"        | Incorrect `tagName` or `tagValue`                  | Verify the tag name and value in Azure Portal.       |
| "Error: Missing subscription ID"     | Missing value after `--subscription`               | Provide a valid subscription ID.                    |
| "No maintenance assignments found"  | No matching maintenance configurations to remove   | Confirm the resource has maintenance configurations. |

---

## **Maintenance and Versioning**
**Version:** v2.3.4  
**Author:** Jessica Brown  
**Changelog:**
- **v2.3.4**: Added argument handling and improved output messaging.
- **v2.3.3**: Enhanced error handling.
- **v2.3.2**: Initial release with subscription filtering support.

---

## **Conclusion**
This script is designed to streamline the process of identifying and removing maintenance configurations from Azure resources, particularly **Arc-enabled machines**. By following this guide, users can efficiently manage maintenance schedules across their Azure environment.


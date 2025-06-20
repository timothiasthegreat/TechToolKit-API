# TechToolKit-API

TechToolKit-API is an Azure Functions-based project written in PowerShell. It provides functionality to interact with Azure Blob Storage, including listing blobs and generating SAS URLs for secure access.  This repo is designed to be a part of the TechToolKit project, which pairs with TechToolKit-SWA to provide a simple interface to download files/tools stored in an Azure Blob.

---

## Functions

### **ListTools Function**

- **Trigger**: HTTP GET  
- **Description**: Lists all blobs in the specified Azure Blob Storage container.  
- **Environment Variables**:  
  - `AZURE_STORAGE_ACCOUNT_NAME`  
  - `AZURE_STORAGE_ACCOUNT_KEY`  
  - `AZURE_STORAGE_CONTAINER_NAME`  

### **GetSASUrl Function**

- **Trigger**: HTTP GET or POST  
- **Description**: Generates a SAS URL for a specific blob in Azure Blob Storage.  
- **Environment Variables**:  
  - `AZURE_STORAGE_ACCOUNT_NAME`  
  - `AZURE_STORAGE_ACCOUNT_KEY`  
  - `AZURE_STORAGE_CONTAINER_NAME`  

### **SetTags Function**

- **Trigger**: HTTP POST  
- **Description**: Sets tags on specified blobs in Azure Blob Storage. Existing tags are replaced with those provided in the request body.  
- **Environment Variables**:  
  - `AZURE_STORAGE_ACCOUNT_NAME`  
  - `AZURE_STORAGE_ACCOUNT_KEY`  
  - `AZURE_STORAGE_CONTAINER_NAME`  

### **NewTool Function**

- **Trigger**: HTTP POST  
- **Description**: Uploads a file to Azure Blob Storage. Checks for existing blobs with the same name and either overwrites them or returns a conflict message based on the query parameter.  
- **Environment Variables**:  
  - `AZURE_STORAGE_ACCOUNT_NAME`  
  - `AZURE_STORAGE_ACCOUNT_KEY`  
  - `AZURE_STORAGE_CONTAINER_NAME`  

---

## Prerequisites

To set up and deploy this project, ensure the following tools are installed:

- **Azure Subscription**: Required to deploy and run the functions.
- **PowerShell**: Ensure PowerShell is installed on your system.
- **Azure CLI**: Install the Azure CLI for deployment and management.
- **VS Code**: Recommended IDE with the Azure Functions and PowerShell extensions.

---

## Setup

1. Clone the repository:

   ```sh
   git clone https://github.com/your-repo/TechToolKit-API.git
   cd TechToolKit-API
   ```

2. Create an Azure Storage Account and Blob Container if you haven't already.
3. Create an Azure Function App in your Azure Subscription.
4. Set the required environment variables in your Function App:
   - `AZURE_STORAGE_ACCOUNT_NAME`
   - `AZURE_STORAGE_ACCOUNT_KEY`
   - `AZURE_STORAGE_CONTAINER_NAME`
5. Deploy the functions using the Azure Functions Core Tools or directly from VS Code, or link the repository to your Function App in Azure.  <https://learn.microsoft.com/en-us/azure/azure-functions/functions-how-to-github-actions?tabs=windows%2Cdotnet&pivots=method-portal>
6. Retrieve the function URLs from the Azure portal or from the output of the deployment command for use in the SWA.

---

## License

This project is licensed under the MIT License.

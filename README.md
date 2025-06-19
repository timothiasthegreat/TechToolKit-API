# TechToolKit-API

TechToolKit-API is an Azure Functions-based project written in PowerShell. It provides functionality to interact with Azure Blob Storage, including listing blobs and generating SAS URLs for secure access.

---

## Features

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

2. Configure environment variables:
   - Set the required Azure Storage account details in your environment.

---

## Deployment

### **Automated Deployment**

This project uses GitHub Actions for CI/CD. On every push to the `main` branch, the workflow defined in `.github/workflows/main_techtoolkit-api.yml` will build and deploy the project to Azure.

### **Manual Deployment**

1. Login to Azure:

   ```sh
   az login
   ```

2. Deploy the functions:

   ```sh
   func azure functionapp publish <FunctionAppName>
   ```

---

## License

This project is licensed under the MIT License.

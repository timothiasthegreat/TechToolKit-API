param($Request, $TriggerMetadata)

Write-Host "PowerShell HTTP trigger function processed a request to generate SAS URL."

# Get blob name from query or body
$blobName = $Request.Query.blobName
if (-not $blobName) {
    $blobName = $Request.Body.blobName
}

if (-not $blobName) {
    Push-OutputBinding -Name Response -Value @{
        StatusCode = 400
        Body = "Please pass a 'blobName' in the query string or in the request body."
    }
    return
}

# Use environment variables for configuration
$storageAccountName = $env:AZURE_STORAGE_ACCOUNT_NAME
$storageAccountKey  = $env:AZURE_STORAGE_ACCOUNT_KEY
$containerName      = $env:AZURE_STORAGE_CONTAINER_NAME

# Import Az.Storage module if not already imported
if (-not (Get-Module -ListAvailable -Name Az.Storage)) {
    Import-Module Az.Storage
}

# Create storage context
$context = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

# Set SAS token expiration (e.g., 1 hour from now)
$expiryTime = (Get-Date).ToUniversalTime().AddHours(1)

# Generate SAS token for the blob (read-only)
$sasToken = New-AzStorageBlobSASToken `
    -Container $containerName `
    -Blob $blobName `
    -Permission r `
    -Context $context `
    -ExpiryTime $expiryTime `
    -FullUri
Write-Information "Generated SAS token for blob '$blobName': $sasToken"
if (-not $sasToken) {
    Write-Information "Failed to generate SAS token for blob '$blobName'."
    Push-OutputBinding -Name Response -Value @{
        StatusCode = 500
        Body = "Failed to generate SAS token."
    }
    return
}

Push-OutputBinding -Name Response -Value @{
    StatusCode = 200
    Body = "{""sasUrl"":""$sasToken""}"
}
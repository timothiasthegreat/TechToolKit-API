using namespace System.Net
using namespace System.IO

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Retrieve storage account details from environment variables
$storageAccountName = $env:AZURE_STORAGE_ACCOUNT_NAME
$storageAccountKey = $env:AZURE_STORAGE_ACCOUNT_KEY
$containerName = $env:AZURE_STORAGE_CONTAINER_NAME

if (-not $storageAccountName -or -not $storageAccountKey -or -not $containerName) {
    Write-Error "Missing storage account configuration in local.settings.json"
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::InternalServerError
        Body = "Storage account configuration is missing."
    })
    return
}

# Check if a file is provided in the request body
if (-not $Request.Body) {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::BadRequest
        Body = "No file provided in the request body."
    })
    return
}

# Parse the file from the request body
$fileContent = $Request.Body
$fileName = $Request.Query.FileName
$overwrite = $Request.Query.Overwrite

if (-not $fileName) {
    $fileName = "uploaded-file-" + (Get-Date -Format "yyyyMMddHHmmss") + ".txt"
}

# Create the Blob Storage context
$context = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

# Check if the blob already exists
$existingBlob = Get-AzStorageBlob -Container $containerName -Context $context | Where-Object { $_.Name -eq $fileName }

if ($existingBlob) {
    if ($overwrite -eq "yes") {
        Write-Host "Blob with name '$fileName' exists. Overwriting as 'overwrite=yes' is specified."
    } else {
        Write-Host "Blob with name '$fileName' already exists. Returning conflict message."
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::Conflict
            Body = "A blob with the name '$fileName' already exists. Use 'overwrite=yes' in the query to replace it."
        })
        return
    }
}

# Upload the file to the Blob Storage container
try {
    Set-AzStorageBlobContent -Container $containerName -FileContent $fileContent -Blob $fileName -Context $context
    Write-Host "File uploaded successfully to blob storage."

    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body = "File uploaded successfully as $fileName."
    })
} catch {
    Write-Error "Failed to upload file to blob storage: $_"
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::InternalServerError
        Body = "Failed to upload file to blob storage."
    })
}

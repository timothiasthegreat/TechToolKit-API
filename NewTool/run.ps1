using namespace System.Net
using namespace System.IO
using namespace Newtonsoft.Json

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

# Parse the file and tags from the request body
$fileContent = $Request.Body
$fileName = $Request.Query.FileName
$tagsJson = $Request.Query.Tags

if (-not $fileName) {
    $fileName = "uploaded-file-" + (Get-Date -Format "yyyyMMddHHmmss") + ".txt"
}

# Parse tags if provided
$tags = @{}
if ($tagsJson) {
    try {
        $tags = ConvertFrom-Json -InputObject $tagsJson
    } catch {
        Write-Error "Invalid JSON format for tags: $_"
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::BadRequest
            Body = "Invalid JSON format for tags."
        })
        return
    }
}

# Create the Blob Storage context
$context = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

# Upload the file to the Blob Storage container
try {
    $blob = Set-AzStorageBlobContent -Container $containerName -FileContent $fileContent -Blob $fileName -Context $context
    Write-Host "File uploaded successfully to blob storage."

    # Apply tags to the blob
    if ($tags.Count -gt 0) {
        $blobUri = $blob.ICloudBlob.Uri.AbsoluteUri
        Set-AzStorageBlobTag -Blob $fileName -Container $containerName -Tags $tags -Context $context
        Write-Host "Tags applied successfully to blob."
    }

    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body = "File uploaded successfully as $fileName with tags."
    })
} catch {
    Write-Error "Failed to upload file or apply tags to blob storage: $_"
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::InternalServerError
        Body = "Failed to upload file or apply tags to blob storage."
    })
}

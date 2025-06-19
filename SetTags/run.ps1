using namespace System.Net
using namespace Newtonsoft.Json

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

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

# Parse the JSON body of the request
try {
    $requestBody = $Request.Body | ConvertFrom-Json
} catch {
    Write-Error "Invalid JSON format in request body: $_"
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::BadRequest
        Body = "Invalid JSON format in request body."
    })
    return
}

# Validate the request body
if (-not $requestBody -or $requestBody.Count -eq 0) {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::BadRequest
        Body = "Request body must contain an array of blob names and tags."
    })
    return
}

# Create the Blob Storage context
$context = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

# Process each blob in the request body
foreach ($blobEntry in $requestBody) {
    if (-not $blobEntry.Name -or -not $blobEntry.Tags) {
        Write-Error "Each entry must contain 'Name' and 'Tags'."
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::BadRequest
            Body = "Each entry must contain 'Name' and 'Tags'."
        })
        return
    }

    try {
        # Set tags on the blob
        Set-AzStorageBlobTag -Blob $blobEntry.Name -Container $containerName -Tags $blobEntry.Tags -Context $context
        Write-Host "Tags successfully set for blob: $($blobEntry.Name)"
    } catch {
        Write-Error "Failed to set tags for blob $($blobEntry.Name): $_"
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::InternalServerError
            Body = "Failed to set tags for blob $($blobEntry.Name)."
        })
        return
    }
}

# Respond with success
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = "Tags successfully updated for all blobs."
})

<# Example Request Body
[
  {
    "Name": "example-blob-1.txt",
    "Tags": {
      "Project": "TechToolKit",
      "Environment": "Production"
    }
  },
  {
    "Name": "example-blob-2.txt",
    "Tags": {
      "Project": "TechToolKit",
      "Environment": "Development"
    }
  }
] #>
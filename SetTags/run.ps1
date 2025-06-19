using namespace System.Net

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

Write-Host "Storage account details retrieved successfully."
Write-Host "Storage Account Name: $storageAccountName"
Write-Host "Container Name: $containerName"

# Validate the request body
if (-not $Request.Body -or $Request.Body.Count -eq 0) {
    Write-Error "Request body is empty or invalid."
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::BadRequest
        Body = "Request body must contain an array of blob names and tags."
    })
    return
}

Write-Host "Request body validated successfully."

# Create the Blob Storage context
try {
    $context = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey
    Write-Host "Azure Storage context created successfully."
} catch {
    Write-Error "Failed to create Azure Storage context: $_"
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::InternalServerError
        Body = "Failed to create Azure Storage context."
    })
    return
}

# Process each blob in the request body
foreach ($blobEntry in $Request.Body) {
    if (-not $blobEntry.Name -or -not $blobEntry.Tags) {
        Write-Error "Invalid blob entry. Each entry must contain 'Name' and 'Tags'."
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::BadRequest
            Body = "Each entry must contain 'Name' and 'Tags'."
        })
        return
    }

    Write-Host "Processing blob: $($blobEntry.Name)"

    try {
        # Set tags on the blob
        Set-AzStorageBlobTag -Blob $blobEntry.Name -Container $containerName -Tag $blobEntry.Tags -Context $context
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

Write-Host "All blobs processed successfully."

# Respond with success
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = "Tags successfully updated for all blobs."
})

<# Example Request Body
[{
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
}] #>
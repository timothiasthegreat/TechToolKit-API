param($Request, $TriggerMetadata)

Write-Information "PowerShell HTTP trigger function processed a request."

function Get-BlobListWithTagsAsJson {
    param(
        [string]$StorageAccountName,
        [string]$StorageAccountKey,
        [string]$ContainerName
    )

    Write-Information "Initializing Azure Storage context..."
    $context = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey

    Write-Information "Retrieving blobs from container: $ContainerName"
    $blobs = Get-AzStorageBlob -Container $ContainerName -Context $context

    if (-not $blobs) {
        Write-Error "No blobs found in container: $ContainerName"
        return @()
    }

    Write-Information "Found $($blobs.Count) blobs in container: $ContainerName"

    $blobDetails = @()
    foreach ($blob in $blobs) {
        Write-Information "Processing blob: $($blob.Name)"
        try {
            $tags = Get-AzStorageBlobTag -Blob $blob.Name -Container $ContainerName -Context $context
            if ($tags.Tags) {
                Write-Information "Tags retrieved for blob: $($blob.Name) - $($tags)"
            } else {
                Write-Warning "No tags found for blob: $($blob.Name)"
            }
            $blobDetails += @{
                Name = $blob.Name
                Tags = $tags
            }
        } catch {
            Write-Error "Failed to retrieve tags for blob: $($blob.Name) - $_"
        }
    }

    Write-Information "Completed processing blobs. Returning JSON response."
    return ($blobDetails | ConvertTo-Json -Depth 10)
}

Write-Information "Request received: $($Request | Format-List | Out-String)"

$storageAccountName = $env:AZURE_STORAGE_ACCOUNT_NAME
$storageAccountKey = $env:AZURE_STORAGE_ACCOUNT_KEY
$containerName = $env:AZURE_STORAGE_CONTAINER_NAME

Write-Information "Storage Account Name: $storageAccountName"
Write-Information "Container Name: $containerName"

if (-not $Request) {
    Write-Error "Request is null or invalid."
    Push-OutputBinding -Name Response -Value @{
        StatusCode = 400
        Body = "Request is null or invalid."
    }
    return
}

if ($Request.Method -eq "GET") {
    if (-not $storageAccountName -or -not $storageAccountKey -or -not $containerName) {
        Write-Error "Storage account information is missing from environment variables."
        Push-OutputBinding -Name Response -Value @{
            StatusCode = 500
            Body = "Storage account information is missing from environment variables."
        }
        return
    }

    try {
        Write-Information "Listing blobs with tags in container: $containerName"
        $jsonBlobs = Get-BlobListWithTagsAsJson -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey -ContainerName $containerName
        Write-Information "Blob list with tags: $jsonBlobs"
        Push-OutputBinding -Name Response -Value @{
            StatusCode = 200
            Body = $jsonBlobs
            Headers = @{ "Content-Type" = "application/json" }
        }
    } catch {
        Write-Error "Failed to list blobs with tags: $_"
        Push-OutputBinding -Name Response -Value @{
            StatusCode = 500
            Body = "Failed to list blobs with tags: $_"
        }
    }
    return
}
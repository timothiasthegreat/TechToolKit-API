# Removed: using namespace System.Net

param($Request, $TriggerMetadata)

Write-Information "PowerShell HTTP trigger function processed a request."

function Get-BlobListWithTagsAsJson {
    param(
        [string]$StorageAccountName,
        [string]$StorageAccountKey,
        [string]$ContainerName
    )

    if (-not (Get-Module -ListAvailable -Name Az.Storage)) {
        Import-Module Az.Storage
    }

    $context = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
    $blobs = Get-AzStorageBlob -Container $ContainerName -Context $context

    $blobDetails = @()
    foreach ($blob in $blobs) {
        $tags = Get-AzStorageBlobTag -Blob $blob.Name -Container $ContainerName -Context $context
        $blobDetails += @{
            Name = $blob.Name
            Tags = $tags.Tags
        }
    }

    return ($blobDetails | ConvertTo-Json -Depth 10)
}

$Request | Format-List | Out-String | Write-Information

$storageAccountName = $env:AZURE_STORAGE_ACCOUNT_NAME
$storageAccountKey = $env:AZURE_STORAGE_ACCOUNT_KEY
$containerName = $env:AZURE_STORAGE_CONTAINER_NAME
Write-Information "Storage Account Name: $storageAccountName"
Write-Information "Container Name: $containerName"

if (-not $Request) {
    Push-OutputBinding -Name Response -Value @{
        StatusCode = 400
        Body = "Request is null or invalid."
    }
    return
}

if ($Request.Method -eq "GET") {
    if (-not $storageAccountName -or -not $storageAccountKey -or -not $containerName) {
        Write-Information "Storage account information is missing from environment variables."
        Push-OutputBinding -Name Response -Value @{
            StatusCode = 500
            Body = "Storage account information is missing from environment variables."
        }
        return
    }

    try {
        Write-Information "Listing blobs with tags in container: $containerName"
        $jsonBlobs = Get-BlobListWithTagsAsJson -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey -ContainerName $containerName
        Push-OutputBinding -Name Response -Value @{
            StatusCode = 200
            Body = $jsonBlobs
            Headers = @{ "Content-Type" = "application/json" }
        }
    } catch {
        Push-OutputBinding -Name Response -Value @{
            StatusCode = 500
            Body = "Failed to list blobs with tags: $_"
        }
        Write-Information "Failed to list blobs with tags: $_"
    }
    return
}
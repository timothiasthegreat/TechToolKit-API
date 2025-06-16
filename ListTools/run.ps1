# Removed: using namespace System.Net

param($Request, $TriggerMetadata)

Write-Information "PowerShell HTTP trigger function processed a request."

function Get-BlobListAsJson {
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
    $blobNames = $blobs | Select-Object -ExpandProperty Name
    return ($blobNames | ConvertTo-Json)
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
        Write-Information "Listing blobs in container: $containerName"
        $jsonBlobs = Get-BlobListAsJson -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey -ContainerName $containerName
        Push-OutputBinding -Name Response -Value @{
            StatusCode = 200
            Body = $jsonBlobs
            Headers = @{ "Content-Type" = "application/json" }
        }
    } catch {
        Push-OutputBinding -Name Response -Value @{
            StatusCode = 500
            Body = "Failed to list blobs: $_"
        }
        Write-Information "Failed to list blobs: $_"
    }
    return
}
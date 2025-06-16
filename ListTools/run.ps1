using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Information "PowerShell HTTP trigger function processed a request."

# Interact with query parameters or the body of the request.
function Get-BlobListAsJson {
    param(
        [string]$StorageAccountName,
        [string]$StorageAccountKey,
        [string]$ContainerName
    )

    # Ensure Az.Storage module is available
    if (-not (Get-Module -ListAvailable -Name Az.Storage)) {
        Import-Module Az.Storage
    }

    $context = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
    $blobs = Get-AzStorageBlob -Container $ContainerName -Context $context
    $blobNames = $blobs | Select-Object -ExpandProperty Name
    return ($blobNames | ConvertTo-Json)
}
$Request | Format-List | Out-String | Write-Information
# Read storage info from environment variables
$storageAccountName = $env:AZURE_STORAGE_ACCOUNT_NAME
$storageAccountKey = $env:AZURE_STORAGE_ACCOUNT_KEY
$containerName = $env:AZURE_STORAGE_CONTAINER_NAME
Write-Information "Storage Account Name: $storageAccountName"
Write-Information "Container Name: $containerName"
# Check if the request is a GET request and if the query parameter 'ListBlobs' is present
if (-not $Request) {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::BadRequest
        Body = "Request is null or invalid."
    })
    return
}
if ($Request.Method -eq "GET") {
    if (-not $storageAccountName -or -not $storageAccountKey -or -not $containerName) {
         Write-Information "Storage account information is missing from environment variables."
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::InternalServerError
            Body = "Storage account information is missing from environment variables."
        })
        return
    }

    try {
        Write-Information "Listing blobs in container: $containerName"
        # Call the function to get blob list as JSON
        $jsonBlobs = Get-BlobListAsJson -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey -ContainerName $containerName
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK
            Body = $jsonBlobs
            Headers = @{ "Content-Type" = "application/json" }
        })
    } catch {
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::InternalServerError
            Body = "Failed to list blobs: $_"
        })
        Write-Information "Failed to list blobs: $_"
    }
    return
}

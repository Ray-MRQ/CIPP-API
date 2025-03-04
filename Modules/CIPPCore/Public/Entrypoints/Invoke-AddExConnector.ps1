using namespace System.Net

Function Invoke-AddExConnector {
    <#
    .FUNCTIONALITY
    Entrypoint
    #>
    [CmdletBinding()]
    param($Request, $TriggerMetadata)

    $APIName = $TriggerMetadata.FunctionName
    Write-LogMessage -user $request.headers.'x-ms-client-principal' -API $APINAME -message 'Accessed this API' -Sev 'Debug'

    $ConnectorType = ($Request.body.PowerShellCommand | ConvertFrom-Json).cippConnectorType
    $RequestParams = $Request.Body.PowerShellCommand | ConvertFrom-Json | Select-Object -Property * -ExcludeProperty GUID, cippConnectorType, comments

    $Tenants = ($Request.body | Select-Object Select_*).psobject.properties.value
    $Result = foreach ($Tenantfilter in $tenants) {
        try {
            $GraphRequest = New-ExoRequest -tenantid $Tenantfilter -cmdlet "New-$($ConnectorType)connector" -cmdParams $RequestParams 
            "Successfully created transport rule for $Tenantfilter."
            Write-LogMessage -user $request.headers.'x-ms-client-principal' -API $APINAME -tenant $Tenantfilter -message "Created Connector for $($Tenantfilter)" -sev 'Info'
        }
        catch {
            "Could not create created transport rule for $($Tenantfilter): $($_.Exception.message)"
            Write-LogMessage -user $request.headers.'x-ms-client-principal' -API $APINAME -tenant $Tenantfilter -message "Could not create Connector for $($Tenantfilter): $($_.Exception.message)" -sev 'Error'
        }
    }


    # Associate values to output bindings by calling 'Push-OutputBinding'.
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK
            Body       = @{Results = @($Result) }
        })

}

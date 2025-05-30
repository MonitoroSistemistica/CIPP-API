using namespace System.Net

Function Invoke-ListUserGroups {
    <#
    .FUNCTIONALITY
        Entrypoint
    .ROLE
        Identity.User.Read
    #>
    [CmdletBinding()]
    param($Request, $TriggerMetadata)

    $APIName = $Request.Params.CIPPEndpoint
    $Headers = $Request.Headers
    Write-LogMessage -headers $Headers -API $APIName -message 'Accessed this API' -Sev 'Debug'

    # Interact with query parameters or the body of the request.
    $TenantFilter = $Request.Query.tenantFilter
    $UserID = $Request.Query.userId
    $URI = "https://graph.microsoft.com/beta/users/$UserID/memberOf/$/microsoft.graph.group?`$select=id,displayName,mailEnabled,securityEnabled,groupTypes,onPremisesSyncEnabled,mail,isAssignableToRole&`$orderby=displayName asc"
    Write-Host $URI

    $GraphRequest = New-GraphGetRequest -uri $URI -tenantid $TenantFilter -noPagination $true -Verbose | Select-Object id,
    @{ Name = 'DisplayName'; Expression = { $_.displayName } },
    @{ Name = 'MailEnabled'; Expression = { $_.mailEnabled } },
    @{ Name = 'Mail'; Expression = { $_.mail } },
    @{ Name = 'SecurityGroup'; Expression = { $_.securityEnabled } },
    @{ Name = 'GroupTypes'; Expression = { $_.groupTypes -join ',' } },
    @{ Name = 'OnPremisesSync'; Expression = { $_.onPremisesSyncEnabled } },
    @{ Name = 'IsAssignableToRole'; Expression = { $_.isAssignableToRole } },
    @{ Name = 'calculatedGroupType'; Expression = {
            if ($_.mailEnabled -and $_.securityEnabled) { 'Mail-Enabled Security' }
            if (!$_.mailEnabled -and $_.securityEnabled) { 'Security' }
            if ($_.groupTypes -contains 'Unified') { 'Microsoft 365' }
            if (([string]::isNullOrEmpty($_.groupTypes)) -and ($_.mailEnabled) -and (!$_.securityEnabled)) { 'Distribution List' }
        }
    }


    # Associate values to output bindings by calling 'Push-OutputBinding'.
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK
            Body       = @($GraphRequest)
        })

}

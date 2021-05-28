<#
.SYNOPSIS
Get child sitemap URLs of a given sitemap

.DESCRIPTION
Get child sitemap URLs of a given sitemap

.PARAMETER Uri
Uri of sitemap

.PARAMETER InputObject
Uri of sitemap

.EXAMPLE
$sitemaps = Get-Sitemaps -Uri https://example.com/sitemap.xml

.NOTES
Sitemap should be formatted according to https://www.sitemaps.org/protocol.html
#>
function Get-Sitemaps {
    [CmdletBinding(DefaultParameterSetName='default')]
    param (
        [Parameter(ParameterSetName='default')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Uri
    ,
        [Parameter(ParameterSetName='pipeline',ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [object]
        $InputObject
    )

    process {
        if ($InputObject) {
            $Uri = $InputObject
        }

        $statusCode = 0
        try {
            $res = Invoke-WebRequest -uri $Uri -UseBasicParsing
            $statusCode = $res.StatusCode
        }catch {
            # Catch 50x exceptions
            if (Get-Member $_.Exception -Name Response) {
                $statusCode = $_.Exception.Response.StatusCode.Value__
            }

            # Write non-http errors
            Write-Error -ErrorRecord $_
        }
        if ($statusCode -eq 200) {
            try {
                $contentInXML = $res.Content -as [xml]
                if ($null -eq $contentInXml) {
                    Write-Error "Sitemap is in not valid XML."
                }

                # Return the child sitemaps
                $contentInXML.sitemapindex.sitemap.loc
            }catch {
                Write-Error -ErrorRecord $_
            }
        }
    }
}

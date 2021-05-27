<#
.SYNOPSIS
Get URLs from a given sitemap

.DESCRIPTION
Get URLs from a given sitemap

.PARAMETER Uri
Uri of sitemap

.PARAMETER InputObject
Uri of sitemap

.EXAMPLE
$urls = Get-SitemapUrls -Uri https://example.com/sitemap.xml

.NOTES
#>
function Get-SitemapUrls {
    [CmdletBinding(DefaultParameterSetName='default')]
    param (
        [Parameter(ParameterSetName='default')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Uri
    ,
        [Parameter(ParameterSetName='pipeline')]
        [ValidateNotNullOrEmpty()]
        [object]
        $InputObject
    )

    process {
        if ($InputObject) {
            $Uri = $InputObject
        }

        try {
            $res = Invoke-WebRequest -Uri $Uri -UseBasicParsing
            $statusCode = $res.StatusCode
        }catch {
            # Catch 50x exceptions
            if (Get-Member $_.Exception -Name Response) {
                $statusCode = $_.Exception.Response.StatusCode.Value__
            }

            # Write non-http errors
                Write-Error -ErrorRecord $_
        }

        if ($statusCode -and $statusCode -eq 200) {
            try {
                $contentInXML = $res.Content -as [xml]
                if ($null -eq $contentInXml) {
                    Write-Error "Sitemap is in not valid XML."
                }

                # Return the urls
                $contentInXML.urlset.url.loc
            }catch {
                Write-Error -ErrorRecord $_
            }
        }

    }
}

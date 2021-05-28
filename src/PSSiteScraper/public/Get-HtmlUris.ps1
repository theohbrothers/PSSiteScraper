<#
.SYNOPSIS
Manually parses html to get uris for a specific tag-attribute pairing.

.DESCRIPTION
Manually parses html to get uris for a specific tag-attribute pairing.

.PARAMETER Html
HTML string

.PARAMETER Tag
HTML tag to search. If empty, searches all tags.

.PARAMETER Attribute
HTML attribute of the HTML tag to search. If empty, searches all attributes of the HTML tag.

.PARAMETER UriScheme
Scheme of the URIs. If empty, by default this is 'https'

.PARAMETER InputObject
HTML string

.EXAMPLE
# Get URIs from all tags' attributes of given HTML
Get-HtmlUris -Html $html

.EXAMPLE
# Get URIs from all tags' attributes of given HTML of scheme 'foo'. E.g. URI 'foo://bar/baz'
Get-HtmlUris -Html $html -UriScheme foo

.EXAMPLE
# Get URIs from all <a> tag's attributes of given HTML
Get-HtmlUris -Html $html -Tag a -UriScheme https

.EXAMPLE
# Get URIs from all <img> tag's 'srcset' attribute of given HTML
Get-HtmlUris -Html $html -Tag img -Attribute srcset -UriScheme https

.NOTES
#>
function Get-HtmlUris {
    [CmdletBinding(DefaultParameterSetName='default')]
    param (
        [Parameter(ParameterSetName='default')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Html
    ,
        [Parameter()]
        [string]
        $Tag
    ,
        [Parameter()]
        [string]
        $Attribute
    ,
        [Parameter()]
        [string]
        $UriScheme
    ,
        [Parameter(ParameterSetName='pipeline',ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string]
        $InputObject
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'pipeline') {
            $html = $InputObject
        }
        if ($Tag -eq '' -and $Attribute -eq '') {
            # Any tag
            $tagRegex = '^[\w-]+'
            # Any attribute
            $attributeValueRegex = "\s[^=]+=(?:`"([^`"]*)`"|'([^']*)')"
        }
        if ($Tag) {
            # This tag
            $tagRegex = "^$( [regex]::Escape($Tag) )\s+"
            # Any attribute
            $attributeValueRegex = "\s[^=]+=(?:`"([^`"]*)`"|'([^']*)')"
        }
        if ($Tag -and $Attribute) {
            # This tag
            $tagRegex = "^$( [regex]::Escape($Tag) )"
            # This attribute
            $attributeRegex = [regex]::Escape($Attribute)
            $attributeValueRegex = "\s$attributeRegex=(?:`"([^`"]*)`"|'([^']*)')"
        }

        # Strip off trailing '://'. E.g. 'https://' becomes 'https'
        $UriScheme = $UriScheme -replace ':\/\/.*', ''
        $UriSchemeRegex = if ($UriScheme) { [regex]::Escape($UriScheme) } else { '[^\s]+' }
        $UriRegex = "(${UriSchemeRegex}:/\/[^\s]*)"

        $uris = [System.Collections.ArrayList]@()

        # E.g. <a
        $tagLines = @(
            $Html.split('<') | Where-Object { $_ -match "^$tagRegex"}
        )

        foreach ($line in $tagLines) {
            # Get attribute value
            # href="https://theohbrothers.com" -> theohbrothers.com
            $matches = [regex]::Matches( $line, $attributeValueRegex )
            if ($matches.success) {
                foreach ($match in $matches) {
                    if ($match.success) {
                        $attValue = if ($match.Groups.Count -eq 2) {
                            $match.Groups[1].Value
                        }elseif ($match.Groups.Count -eq 3) {
                            if ($match.Groups[2].Value) { $match.Groups[2].Value } else { $match.Groups[1].Value }
                        }
                    }
                    # in the case of comma-delimited values e.g. <img srcset>, split values
                    $split = $attValue.Split(',') # for <img srcset="https://example.com/1.jpg 150w, https://example.com/2.jpg 250w" />

                    foreach ($value in $split) {
                        if ($UriRegex) {
                            if ($value -match $UriRegex) {
                                $value = $matches[1]
                            }else {
                                continue
                            }
                        }

                        if (!$uris.Contains($matches[1])) {
                            $uris.Add($value) > $null
                        }
                    }
                }
            }
        }

        # Unwrap the arraylist
        $uris
    }
}

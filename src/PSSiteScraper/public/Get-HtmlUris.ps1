# Manually parses html to get uris for a specific tag-attribute pairing.
 # Param 1: string containing html
 # Param 2: string of html tag e.g. img
 # Param 3: string of html tag's attribute e.g. src
 # Param 4: [System.Collections.ArrayList] arraylist to store uris ( Passed by reference. Powershell has issues with returning empty arrays. See notes at top of file. )
 # Return: -
#
<#<#
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

.PARAMETER InputObject
HTML string

.EXAMPLE
Get-HtmlUris -Html $html -Tag a -Attribute href

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
        [Parameter(ParameterSetName='pipeline')]
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
            $attributeRegex = "\s[^=]+=(?:`"([^`"]*)`"|'([^']*)')"
        }
        if ($Tag) {
            # This tag
            $tagRegex = "^$( [regex]::Escape($Tag) )\s+"
            # Any attribute
            $attributeRegex = "\s[^=]+=(?:`"([^`"]*)`"|'([^']*)')"
        }
        if ($Tag -and $Attribute) {
            # This tag
            $tagRegex = "^$( [regex]::Escape($Tag) )"
            # This attribute
            $attributeRegex = "\s$( [regex]::Escape($Attribute) )=(?:`"([^`"]*)`"|'([^']*)')"
        }

        $uris = [System.Collections.ArrayList]@()

        # E.g. <img
        $tagLines = @(
            $Html.split('<') | Where-Object { $_ -match "^$tagRegex"}
        )

        foreach ($line in $tagLines) {
            # Get attribute value
            # data-src="https://theohbrothers.com" -> theohbrothers.com
            $matches = [regex]::Matches( $line, $attributeRegex )
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
                    $split = $attValue.Split(',') # for <img srcset="http://tob.com/1.jpg 150w, http://tob.com/2.jpg 250w, ..."

                    foreach ($value in $split) {
                        if (!$uris.Contains($value)) {
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

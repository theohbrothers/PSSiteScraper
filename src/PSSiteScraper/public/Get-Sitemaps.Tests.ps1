$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Get-Sitemaps" -Tag 'Unit' {

    Context 'Behavior' {

        It 'Gets one child sitemaps' {
            $uri = 'https://example.com/sitemap.xml'
            function Invoke-WebRequest {
                [pscustomobject]@{
                    StatusCode = 200
                    Content = @'
<sitemapindex>
    <sitemap>
        <loc>https://example.com/sitemap-child.xml</loc>
    </sitemap>
</sitemapindex>
'@
                }
            }

            $result = Get-Sitemaps -Uri $uri
            $result | Should -Be 'https://example.com/sitemap-child.xml'
        }

        It 'Gets multiple child sitemaps' {
            $uri = 'https://example.com/sitemap.xml'
            function Invoke-WebRequest {
                [pscustomobject]@{
                    StatusCode = 200
                    Content = @'
<sitemapindex>
    <sitemap>
        <loc>https://example.com/sitemap-child1.xml</loc>
        <loc>https://example.com/sitemap-child2.xml</loc>
    5</sitemap>
</sitemapindex>
'@
                }
            }

            $result = Get-Sitemaps -Uri $uri
            $result | Should -Be 'https://example.com/sitemap-child1.xml', 'https://example.com/sitemap-child2.xml'
        }

        It 'Shows error message' {
            $uri = 'https://example.com/sitemap.xml'
            function Invoke-WebRequest {
                Write-Error 'foo'
            }
            function Get-Member { $false }

            # Error stream
            $err = Get-Sitemaps -Uri $uri -ErrorAction Continue 2>&1
            $err | ? { $_ -is [System.Management.Automation.ErrorRecord] } | % { $_.Exception.Message } | Should -Be "foo"

            # Exception
            { Get-Sitemaps -Uri $uri -ErrorAction Stop } | Should -Throw 'foo'
        }

    }

}

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Get-SitemapUris" -Tag 'Unit' {

    Context 'Parameters' {

        It 'Receives pipeline input' {
            $uri = 'https://example.com/sitemap.xml'
            function Invoke-WebRequest {
                [pscustomobject]@{
                    StatusCode = 200
                    Content = @'
<urlset>
    <url>
        <loc>https://example.com/foo</loc>
    </url>
</urlset>
'@
                }
            }

            $result = $uri | Get-SitemapUris
            $result | Should -Be 'https://example.com/foo'
        }

    }

    Context 'Behavior' {

        It 'Gets one URL from sitemap' {
            $uri = 'https://example.com/sitemap.xml'
            function Invoke-WebRequest {
                [pscustomobject]@{
                    StatusCode = 200
                    Content = @'
<urlset>
    <url>
        <loc>https://example.com/foo</loc>
    </url>
</urlset>
'@
                }
            }

            $result = Get-SitemapUris -Uri $uri
            $result | Should -Be 'https://example.com/foo'
        }

        It 'Gets multiple URLs from sitemap' {
            $uri = 'https://example.com/sitemap.xml'
            function Invoke-WebRequest {
                [pscustomobject]@{
                    StatusCode = 200
                    Content = @'
<urlset>
    <url>
        <loc>https://example.com/foo</loc>
        <loc>https://example.com/foo2</loc>
    </url>
</urlset>
'@
                }
            }

            $result = Get-SitemapUris -Uri $uri
            $result | Should -Be 'https://example.com/foo', 'https://example.com/foo2'

        }

        It 'Handles errors' {
            $uri = 'https://example.com/sitemap.xml'
            function Invoke-WebRequest {
               throw 'foo'
            }
            function Get-Member { $false }

            # Error stream
            $err = Get-SitemapUris -Uri $uri -ErrorAction Continue 2>&1
            $err | ? { $_ -is [System.Management.Automation.ErrorRecord] } | % { $_.Exception.Message } | Should -Be "foo"

            # Exception
            { Get-SitemapUris -Uri $uri -ErrorAction Stop } | Should -Throw 'foo'
        }

    }

}

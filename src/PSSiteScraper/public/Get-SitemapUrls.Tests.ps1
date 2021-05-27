$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Get-SitemapUrls" -Tag 'Unit' {

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

            $result = Get-SitemapUrls -Uri $uri
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

            $result = Get-SitemapUrls -Uri $uri
            $result | Should -Be 'https://example.com/foo', 'https://example.com/foo2'

        }

        It 'Shows error message' {
            $uri = 'https://example.com/sitemap.xml'
            function Invoke-WebRequest {
                Write-Error 'foo'
            }
            function Get-Member { $false }

            # Error stream
            $err = Get-SitemapUrls -Uri $uri -ErrorAction Continue 2>&1
            $err | ? { $_ -is [System.Management.Automation.ErrorRecord] } | % { $_.Exception.Message } | Should -Be "foo"

            # Exception
            { Get-SitemapUrls -Uri $uri -ErrorAction Stop } | Should -Throw 'foo'
        }

    }

}

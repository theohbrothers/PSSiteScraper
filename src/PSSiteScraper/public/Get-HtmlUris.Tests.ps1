$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Get-HtmlUris" -Tag 'Unit' {

    Context 'Parameters' {

        It 'Receives pipeline input' {
            $html = '<a href="bar://example.com"></a>'

            $result = $html | Get-HtmlUris
            $result | Should -Be 'bar://example.com'
        }

    }

    Context 'Behavior' {

        $html = '<a href="bar://example.com"><img src="https://example.com/0.jpg" data-srcset="https://example.com/1.jpg 150w, https://example.com/2.jpg 250w" /></a>'

        It 'Gets all URIs from all attributes of all tags' {
            $result = Get-HtmlUris -Html $html
            $result | Should -Be 'bar://example.com', 'https://example.com/0.jpg', 'https://example.com/1.jpg', 'https://example.com/2.jpg'
        }

        It 'Gets URIs of specified URI scheme from all attributes of all tags' {
            $uriScheme = 'bar'

            $result = Get-HtmlUris -Html $html -UriScheme $uriScheme
            $result | Should -Be 'bar://example.com'
        }

        It 'Gets URIs from all attributes of a given tag'  {
            $tag = 'a'

            $result = Get-HtmlUris -Html $html -Tag $tag
            $result | Should -Be 'bar://example.com'
        }

        It 'Gets URIs from a given attribute of a given tag'  {
            $tag = 'a'
            $attribute = 'href'

            $result = Get-HtmlUris -Html $html -Tag $tag -Attribute $attribute
            $result | Should -Be 'bar://example.com'
        }

        It 'Gets URIs from a given attribute (with multiple values) of a given tag'  {
            $tag = 'img'
            $attribute = 'data-srcset'

            $result = Get-HtmlUris -Html $html -Tag $tag -Attribute $attribute
            $result | Should -Be 'https://example.com/1.jpg', 'https://example.com/2.jpg'
        }

    }

}

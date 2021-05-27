$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Get-HtmlUris" -Tag 'Unit' {

    Context 'Behavior' {

        It 'Gets all URIs from all attributes of all tags' {
            $html = '<a href="https://example.com"></a>'

            $result = Get-HtmlUris -Html $html
            $result | Should -Be 'https://example.com'
        }

        It 'Gets URIs from all attributes of a given tag'  {
            $html = '<a href="https://example.com"></a>'
            $tag = 'a'

            $result = Get-HtmlUris -Html $html -Tag $tag
            $result | Should -Be 'https://example.com'
        }

        It 'Gets URIs from a given attribute of a given tag'  {
            $html = '<a href="https://example.com"></a>'
            $tag = 'a'
            $attribute = 'href'

            $result = Get-HtmlUris -Html $html -Tag $tag -Attribute $attribute
            $result | Should -Be 'https://example.com'
        }

    }

}

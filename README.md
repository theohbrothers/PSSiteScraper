# PSSiteScraper

Cmdlets for scraping a site.

## Agenda

- Get a site's sitemaps
- Get a site's published URLs from sitemaps
- Get URIs from HTML

## Usage

```powershell
Import-Module PSSiteScraper

# Get child sitemaps of a parent sitemap.
Get-Sitemaps -Uri https://example.com/sitemap.xml

# Get URLs from a sitemap
Get-SitemapUris -Uri https://example.com/sitemap-child.xml

# Get URIs from all tags' attributes of given HTML
Get-HtmlUris -Html $html
# Get URIs from all tags' attributes of given HTML of scheme 'foo'. E.g. URI 'foo://bar/baz'
Get-HtmlUris -Html $html -UriScheme foo
# Get URIs from all <a> tag's attributes of given HTML
Get-HtmlUris -Html $html -Tag a -UriScheme https
# Get URIs from all <img> tag's 'srcset' attribute of given HTML
Get-HtmlUris -Html $html -Tag img -Attribute srcset -UriScheme https
```

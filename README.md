# PSSiteScraper

[![github-actions](https://github.com/theohbrothers/PSSiteScraper/workflows/ci-master-pr/badge.svg)](https://github.com/theohbrothers/PSSiteScraper/actions)
[![github-release](https://img.shields.io/github/v/release/theohbrothers/PSSiteScraper?style=flat-square)](https://github.com/theohbrothers/PSSiteScraper/releases/)
[![powershell-gallery-release](https://img.shields.io/powershellgallery/v/PSSiteScraper?logo=powershell&logoColor=white&label=PSGallery&labelColor=&style=flat-square)](https://www.powershellgallery.com/packages/PSSiteScraper/)

Cmdlets for scraping a site.

## Agenda

- Get a site's sitemaps
- Get a site's published URLs from sitemaps
- Get URIs from HTML

## Install

Open [`powershell`](https://docs.microsoft.com/en-us/powershell/scripting/windows-powershell/install/installing-windows-powershell?view=powershell-5.1) or [`pwsh`](https://github.com/powershell/powershell#-powershell) and type:

```powershell
Install-Module -Name PSSiteScraper -Repository PSGallery -Scope CurrentUser -Verbose
```

If prompted to trust the repository, hit `Y` and `enter`.

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

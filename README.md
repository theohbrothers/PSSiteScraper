# site-scraper-warmer
This Powershell script has the ability to retrieve and output all of a site's URIs by scraping the sitemap of a website,  and gives an option to warm the site automatically or manually through generated curls.

## Features:
- Retrieve links from all sitemaps, starting with the main sitemap
- Scrape retrieved links for uris found in tags: <code>&lt;a href&gt;, &lt;img src&gt;, &lt;img srcset&gt;, &lt;link rel&gt;, &lt;script src&gt;</code>
- Output each uri group to files:
  - sitemaps
  - links from all sitemaps
  - <code>&lt;a href&gt;</code>
  - <code>&lt;img src&gt;</code>
  - <code>&lt;img srcset&gt;</code>
  - <code>&lt;link rel&gt;</code>
  - <code>&lt;script src&gt;</code>
- Output curls for each uri group to files:
  - <code>&lt;a href&gt;</code>
  - <code>&lt;img src&gt;</code>
  - <code>&lt;img srcset&gt;</code>
  - <code>&lt;link rel&gt;</code>
  - <code>&lt;script src&gt;</code>
- Choice whether to warm site with the above uris as part of script.

## Requirements:
- Powershell v3
- Windows environment
- User with read/write/modify permissions on script and searched directories.

## Installation/usage:
- Open the <code>site-scraper-warmer.ps1</code> in your favourite text editor and configure the script settings at the top of the script (instructions are included).
- Right click on the script in explorer and select <code>Run with Powershell</code>. (should be present on Windows 7 and up)
- Alternatively, open command prompt in the script directory, and run <code>Powershell .\site-scraper-warmer.ps1</code>

## NOTE:
- By default, script directory (where you run the script) needs <b>write permission</b>. All created files/folders will reside in the script directory.

## Background: 
- Sysadmins may need a list of their sitemaps, or links from those sitemaps. This scripts generates them in seconds.
- Sysadmins may also need a list of all uris, in order to warm their site (i.e. "preload the cache") especially so if they use Content Delivery Networks (CDNs).
- Search Engine Optimization (SEO) often involves preloading of the website's cache, so that it is served faster to visitors. This script does this automatically; alternatively site warming can be achieved through using the curls generated in a separate file for portability.
- Warming sites may be easier using curls rather than Powershell's Invoke-WebRequest which relies on Internet Explorer and its security settings. This script generates curls in a separate file.
- Website owners might need a list of urls if they intend to migrate their site (e.g. changing a domain name, migrating to another site etc.).


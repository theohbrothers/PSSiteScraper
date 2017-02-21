# site-scraper-warmer
This Powershell script has the ability to retrieve and output all of a site's URIs by scraping its sitemap for links, followed by parsing HTML of those links, and gives an option to warm the site automatically or manually through generated curls.

## Features:
- Retrieve links from sitemaps, starting with the main sitemap.
- Output sitemaps and links as list and curls in individual files.
- Choice whether to scrape retrieved links for URI found in tags: <code>&lt;a href&gt;, &lt;img src&gt;, &lt;img srcset&gt;, &lt;link rel&gt;, &lt;script src&gt;</code>
- URIs are domain-specific (i.e. same domain as the sitemaps).
- Output each URI group to files:
  - <code>&lt;a href&gt;</code>
  - <code>&lt;img src&gt;</code>
  - <code>&lt;img srcset&gt;</code>
  - <code>&lt;link rel&gt;</code>
  - <code>&lt;script src&gt;</code>
- Output curls for each URI group to files:
  - <code>&lt;a href&gt;</code>
  - <code>&lt;img src&gt;</code>
  - <code>&lt;img srcset&gt;</code>
  - <code>&lt;link rel&gt;</code>
  - <code>&lt;script src&gt;</code>
- Choice whether to warm site with the above URIs as part of script.

## Requirements:
- <a href="https://github.com/PowerShell/PowerShell#get-powershell" target="_blank">Powershell v3</a>
- Windows / *nix environment
- User with read/write/modify permissions on script directory.

## Installation/usage:
- Open the <code>site-scraper-warmer.ps1</code> in your favourite text editor and configure the script settings at the top of the script (instructions are included).
- WinNT:
  - Right click on the script in explorer and select <code>Run with Powershell</code>. (should be present on Windows 7 and up)
  - Alternatively, open command prompt in the script directory, and run <code>Powershell .\site-scraper-warmer.ps1</code>
- *nix:
  - Run <code>powershell ./site-scraper-warmer.ps1</code>
  
## FAQ
Q: Help! I am getting an error <code>'File C:\Users\User\rmdups\rmdups.ps1 cannot be loaded because the execution of scripts is disabled on this system. Please see "get-help about_signing" for more details.'</code>
- You need to allow the execution of unverified scripts. Open Powershell as administrator, type <code>Set-ExecutionPolicy Unrestricted -Force</code> and press ENTER. Try running the script again. You can easily restore the security setting back by using <code>Set-ExecutionPolicy Undefined -Force</code>.

Q: Help! Upon running the script I am getting a warning <code>'Execution Policy change. The execution policy helps protect you from scripts that you do not trust. Changing the execution policy might expose you to the security risks described in the about_Execution_Policies help topic at http://go.microsoft.com/?LinkID=135170. Do you want to change the execution policy?</code>
- You need to allow the execution of unverified scripts. Type <code>Y</code> for yes and press enter. You can easily restore the security setting back opening Powershell as administrator, and using the code <code>Set-ExecutionPolicy Undefined -Force</code>.

Q: Help! I am getting a Internet Explorer popup warning that <code>'Content within this application coming from the website listed below is being blocked by Internet Explorer Enhanced Security Configuration.'</code>
- On Windows Servers, this is a known issue with IE Enhanced Security Configuration (ESC); the only way around this is to turn off IE ESC. The script uses IE's HTML parsing engine to get uris, which might involve running <code>&lt;script&gt;</code> tags that IE ESC attempts to protect your system from. 

## Known issues
- If Internet Explorer Enhanced Security Configuration (ESC) is enabled, popups will block the execution of the script; the only way around this is to turn off IE ESC. The script uses IE's html parsing engine to get uris, which might involve running <code>&lt;script&gt;</code> tags that IE ESC attempts to protect your system from. 

## NOTE:
- By default, script directory (where you run the script) needs <b>read, execute, write permissions</b>. All created files/folders will reside in the script directory.

## Background: 
																													
- Website owners may want warm their site (i.e. "preload the cache") from a remote client especially so if they use Content Delivery Networks (CDNs).
- Search Engine Optimization (SEO) typically involves optimizing a website's load times, which can drastically decrease if the website has preloaded its cache. This script can be configured to do this automatically; alternatively site warming can be achieved through using the curls generated in separate files for portability.
- Website owners might want a list of links of all their resources (blog posts, media, etc.) if they intend to migrate their site (e.g. changing a domain name).. This script can search for all of those and output them as a list.
- Website owners may simply need a list of their sitemaps, or links from those sitemaps.

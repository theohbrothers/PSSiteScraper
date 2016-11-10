# site-scraper-warmer
This Powershell script has the ability to retrieve and output all of a site's URIs by scraping the sitemap of a website,  and gives an option to warm the site automatically or manually through generated curls.

## Features:
- Retrieve links from all sitemaps, starting with the main sitemap
- Scrape retrieved links for URI found in tags: <code>&lt;a href&gt;, &lt;img src&gt;, &lt;img srcset&gt;, &lt;link rel&gt;, &lt;script src&gt;</code>
- URIs are domain-specific (i.e. same domain as the sitemaps).
- Output each URI group to files:
  - sitemaps
  - links from all sitemaps
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
- Choice whether to warm site with the above uris as part of script.


## Requirements:
- Powershell v3
- Windows environment
- User with read/write/modify permissions on script and searched directories.

## Installation/usage:
- Open the <code>site-scraper-warmer.ps1</code> in your favourite text editor and configure the script settings at the top of the script (instructions are included).
- Right click on the script in explorer and select <code>Run with Powershell</code>. (should be present on Windows 7 and up)
- Alternatively, open command prompt in the script directory, and run <code>Powershell .\site-scraper-warmer.ps1</code>

## FAQ
Q: Help! I am getting an error <code>'File C:\Users\User\rmdups\rmdups.ps1 cannot be loaded because the execution of scripts is disabled on this system. Please see "get-help about_signing" for more details.'</code>
- You need to allow the execution of unverified scripts. Open Powershell as administrator, type <code>Set-ExecutionPolicy Unrestricted -Force</code> and press ENTER. Try running the script again. You can easily restore the security setting back by using <code>Set-ExecutionPolicy Undefined -Force</code>.

Q: Help! Upon running the script I am getting a warning <code>'Execution Policy change. The execution policy helps protect you from scripts that you do not trust. Changing the execution policy might expose you to the security risks described in the about_Execution_Policies help topic at http://go.microsoft.com/?LinkID=135170. Do you want to change the execution policy?</code>
- You need to allow the execution of unverified scripts. Type <code>Y</code> for yes and press enter. You can easily restore the security setting back opening Powershell as administrator, and using the code <code>Set-ExecutionPolicy Undefined -Force</code>.

Q: Help! I am getting a Internet Explorer popup warning that <code>'Content within this application coming from the website listed below is being blocked by Internet Explorer Enhanced Security Configuration.'</code>
- This is a known issue with IE Enhanced Security Configuration (ESC); the only way around this is to turn off IE ESC. The script uses IE's html parsing engine to get uris, which might involve running <code>&lt;script&gt;</code> tags that IE ESC attempts to protect your system from. 

## Known issues
- If Internet Explorer Enhanced Security Configuration (ESC) is enabled, popups will block the execution of the script; the only way around this is to turn off IE ESC. The script uses IE's html parsing engine to get uris, which might involve running <code>&lt;script&gt;</code> tags that IE ESC attempts to protect your system from. 

## NOTE:
- By default, script directory (where you run the script) needs <b>write permission</b>. All created files/folders will reside in the script directory.

## Background: 
- Sysadmins may need a list of their sitemaps, or links from those sitemaps. This scripts generates them in seconds.
- Sysadmins may also need a list of all uris, in order to warm their site (i.e. "preload the cache") especially so if they use Content Delivery Networks (CDNs).
- Search Engine Optimization (SEO) often involves preloading of the website's cache, so that it is served faster to visitors. This script does this automatically; alternatively site warming can be achieved through using the curls generated in a separate file for portability.
- Warming sites may be easier using curls rather than Powershell's Invoke-WebRequest which relies on Internet Explorer and its security settings. This script generates curls in a separate file.
- Website owners might need a list of their site's urls if they intend to migrate their site (e.g. changing a domain name).


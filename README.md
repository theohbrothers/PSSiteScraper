# Scrape-Warm-Site
This Powershell script has the ability to retrieve and output all of a site's URIs by scraping its sitemap for links, followed by parsing HTML of those links, and gives an option to warm the site automatically or manually through generated curls.

## Features:
- Starting with a site's parent sitemap, scrape for child sitemaps and get all links
- Output sitemaps and links as list and curls in individual files
- Choice whether to scrape links for URIs found in <i>any tag-attribute combination</i> you want. E.g. <code>&lt;a href&gt;, &lt;img src&gt;, &lt;img srcset&gt;, &lt;img data-src&gt;, &lt;img data-srcset&gt;, &lt;link rel&gt;, &lt;script src&gt;</code>
- URIs are domain-specific (i.e. same domain as the sitemaps and links)
- Output each tag-attribute's URIs to files
- Output each tag-attribute's URIs as curls to files
- Choice whether to warm site with the above URIs as part of script

## Requirements:
- A sitemap formatted in the <a href="https://www.sitemaps.org/protocol.html" target="_blank">Sitemap protocol format</a>, populated with links
- <a href="https://github.com/PowerShell/PowerShell#get-powershell" target="_blank">Powershell v3</a>
- Windows / *nix environment
- User with read/write/modify permissions on script directory

## Installation/usage:
- Open the <code>config.ps1</code> in your favourite text editor and configure scripts settings
- WinNT:
  - Right click on the script in explorer and select <code>Run with Powershell</code>. (should be present on Windows 7 and up)
  - Alternatively, open command prompt in the script directory, and run <code>Powershell .\Scrape-Warm-Site.ps1</code>
- *nix:
  - Run <code>powershell ./Scrape-Warm-Site.ps1</code> or <code>pwsh ./Scrape-Warm-Site.ps1</code> depending on which version of powershell you're running.
  
## FAQ 

### WinNT
Q: Help! I am getting an error <code>'File C:\...Scrape-Warm-Site.ps1 cannot be loaded because the execution of scripts is disabled on this system. Please see "get-help about_signing" for more details.'</code>
- You need to allow the execution of unverified scripts. Open Powershell as administrator, type <code>Set-ExecutionPolicy Unrestricted -Force</code> and press ENTER. Try running the script again. You can easily restore the security setting back by using <code>Set-ExecutionPolicy Undefined -Force</code>.

Q: Help! Upon running the script I am getting an error <code>File C:\...Scrape-Warm-Site.ps1 cannot be loaded. The file 
C:\...\Scrape-Warm-Site.ps1 is not digitally signed. You cannot run 
this script on the current system. For more information about running scripts and setting 
execution policy, see about_Execution_Policies at http://go.microsoft.com/fwlink/?LinkID=135170.</code>
- You need to allow the execution of unverified scripts. Open Powershell as administrator, type <code>Set-ExecutionPolicy Unrestricted -Force</code> and press ENTER. Try running the script again. You can easily restore the security setting back by using <code>Set-ExecutionPolicy Undefined -Force</code>.

Q: Help! Upon running the script I am getting a warning <code>'Execution Policy change. The execution policy helps protect you from scripts that you do not trust. Changing the execution policy might expose you to the security risks described in the about_Execution_Policies help topic at http://go.microsoft.com/?LinkID=135170. Do you want to change the execution policy?</code>
- You need to allow the execution of unverified scripts. Type <code>Y</code> for yes and press enter. You can easily restore the security setting back opening Powershell as administrator, and using the code <code>Set-ExecutionPolicy Undefined -Force</code>.

### *nix
Nil

## Known issues
Nil

## Additional Information
- By default, script directory (where you run the script) needs <b>read, execute, write permissions</b>. All created files/folders will reside in the script directory.

## Background: 								
- Website owners may want to warm their site (i.e. "preload the cache") from a remote client especially so if they use Content Delivery Networks (CDNs).
- Search Engine Optimization (SEO) typically involves optimizing a website's load times, and one of the most effective means of doing so is to preload or 'warm' the web cache. This script can be configured to do this automatically; alternatively site warming can be achieved through using the curls generated in separate files for portability.
- Website owners might want a list of links of all their resources (blog posts, media, etc.) if they intend to migrate their site (e.g. changing a domain name). This script can search for all of those and output them as a list.
- Website owners may simply need a list of their sitemaps, or links from those sitemaps.

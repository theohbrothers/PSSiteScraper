################# configure script settings #################
# NOTES:
#  - If you are getting blank error codes while running the script, 
#    try and disable TLS1.2 at the bottom of the config file.
#

# Protocol of your web end.
# Use either https:// or http://
# Default: https://
$desired_protocol = "https://"

# Domain (may be a subdomain or subsubdomain)
# domain should only contain letters, numbers, -, and . 
# NOTE: do not include trailing slash
$domain = "theohbrothers.com"

# Sitemap file name
# NOTE: do not include preceding slash.
$main_sitemap_uri = "sitemap.xml"

# Fully generated sitemap uri
# NOTE: unless you know what you're doing, leave this as default
# Default: "$desired_protocol$domain/$main_sitemap_uri"
$sitemap = "$desired_protocol$domain/$main_sitemap_uri"

# Tag-attribute combinations where uris should be searched (Comma-delimited, order doesn't matter)
# NOTE: best left in their default values.
# NOTE: if you would like to add another combination, append it to the string (ensure you add a comma before each entry)
$tag_attribute_combos = "a href, img src, img data-src, img srcset, img data-srcset, link href, script src, img data-noscript, ...custom "

# Data files and directories
# NOTE: best left in their default values.
$sitemaps_dir = "sitemaps"
$sitemaps_file = "sitemaps"
$links_dir = "links"
$links_file = "links"
$sitemaps_links_file_extension = ".txt"
$html_dir = "html"
$uri_sets_dir = "uri_sets"
$uri_sets_file_extension = ".txt"
$curls_dir = "curls"

# Whether the script should stop at just retreiving sitemaps links, or continue to get all uris from all those links
# 0 - retrieve links and continue to get all their uris
# 1 - retrieve links only
# Default: 0
$mode_sitemap_links_only = 0

# Whether all outputted sitemaps, links, uri sets, and curls should have their protocol replaced with the desired protocol (of your web end) as above, or left unchanged
# 0 - do not replace the protocol
# 1 - replace the protocol 
# Default: 0
$mode_output_force_protocol = 0

# 0 - do not warm site
# 1 - warm a_href uris only
# 2 - warm all uris (a_href, img_src, img_srcset, link_href, script_src)
# Default: 0
$mode_warm = 0

# Whether to save each to-be-parsed HTML document as a .html file
# 0 - do not save HTML
# 1 - save HTML
# Default: 0
$mode_save_html = 0

# Whether to warm site with all retrieved uris
# 0 - do not warm site
# 1 - warm a_href uris only
# 2 - warm all uris (a_href, img_src, img_srcset, link_href, script_src)
# Default: 0
$mode_warm = 0

# OS for manually executable generated curls scripts 
# 0 - *nix  -- curls generated as shell (.sh) scripts
# 1 - WinNT -- curls generated as batch (.bat) scripts
# Default: 0
$OS_WinNT = 0

# Debug mode
# 0 - turn off debugging.
# >=1, values are additive. Enter then sum of the values corresponding to the outputs you want:
#   1 - Performance metrics
#   2 - Operations (General)
#   4 - Operations (Verbose)
# Default: 0
$debug = 0

# suppress errors / progress
# NOTE: do not edit
# Default: 'silentlycontinue'
#$ErrorActionPreference = 'silentlycontinue'
$progressPreference = 'silentlyContinue'  # Hides download progress of Invoke-WebRequest

# Enforce TLS1.2 throughout script
# Comment out - enable Powershell to self-select its TLS protocol (1.0-1.2).
# Uncomment - force TLS1.2. Best practice, and future-proof. 
# Default: [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
############################################################# 

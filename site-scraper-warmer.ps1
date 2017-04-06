############### configure script settings ##########
# protocol
# Use either https:// or http://
# Default: https://
$desired_protocol = "https://"

# domain (may be a subdomain or subsubdomain)
# domain should only contain letters, numbers, -, and . 
# NOTE: do not include trailing slash
$domain = "theohbrothers.com"

# sitemap file name
# NOTE: do not include preceding slash.
$main_sitemap_uri = "sitemap.xml"

# fully generated sitemap uri
# NOTE: unless you know what you're doing, leave this as default
# Default: "$desired_protocol$domain/$main_sitemap_uri"
$sitemap = "$desired_protocol$domain/$main_sitemap_uri"

# tag-attribute combinations where uris should be searched (Comma-delimited, order doesn't matter)
# NOTE: best left in their default values.
# NOTE: if you would like to add another combination, append it to the string (ensure you add a comma before each entry)
$tag_attribute_combos = "a href, img src, img data-src, img srcset, img data-srcset, link href, script src, img data-noscript, ...custom "

# data files and directories
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

# whether the script should stop at just retreiving sitemaps links, or continue to get all uris from all those links
# 0 - retrieve links and continue to get all their uris
# 1 - retrieve links only
# Default: 0
$mode_sitemap_links_only = 0

# whether to save each to-be-parsed HTML document as a .html file
# 0 - do not save HTML
# 1 - save HTML
# Default: 0
$mode_save_html = 0

# whether to warm site with all retrieved uris
# 0 - do not warm site
# 1 - warm a_href uris only
# 2 - warm all uris (a_href, img_src, img_srcset, link_href, script_src)
# Default: 0
$mode_warm = 0

# the OS for manually executable generated curls scripts 
# 0 - *nix  -- curls generated as shell (.sh) scripts
# 1 - WinNT -- curls generated as batch (.bat) scripts
# Default: 0
$OS_WinNT = 0

# debug mode
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
############################################################# 

# includes
. ./functions.ps1

# Get script directory, set as cd
$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
#Set-Location $scriptDir
cd $scriptDir
Write-Host "Script directory: $scriptDir" -ForegroundColor Green

# check if desired protocol is valid
if ($desired_protocol -match '^https?:\/\/$' -eq $false) { Write-Host "Invalid protocol! Use either of the following:`n`thttps://`n`thttp://"; pause; exit }

# check if domain is valid
if ($domain -match '^[A-z\-\.]+$' -eq $false) { Write-Host 'Invalid domain! should only contain letters, numbers, -, and .' ; pause; exit }

# check modes and OS
if (($mode_sitemap_links_only -gt 1) -or ($mode_sitemap_links_only -lt 0)) { Write-Host "Invalid `$mode_sitemap_links_only! Use integer values from 0 to 1." -ForegroundColor Yellow; pause; exit}
if (($mode_save_html -gt 1) -or ($mode_save_html  -lt 0)) { Write-Host "Invalid `$mode_save_html! Use integer values from 0 to 1." -ForegroundColor Yellow; pause; exit}
if (($mode_warm -gt 2) -or ($mode_warm -lt 0)) { Write-Host "Invalid `$mode_warm! Use integer values from 0 to 2." -ForegroundColor Yellow;	pause; exit}
if (($OS_WinNT -gt 1) -or ($OS_WinNT -lt 0)) { Write-Host "Invalid `$OS_WinNT! Use integer values from 0 to 1." -ForegroundColor Yellow; pause; exit}

# check for write permissions in script directory
Try { [io.file]::OpenWrite('test').close(); Remove-Item 'test'}
Catch { Write-Warning "Script directory has to be writeable to output to files!" }

Write-Host "`n`n[Scraping sitemap(s) for links ...]" -ForegroundColor Cyan
# get main sitemap as xml object
# Invoke-WebRequest without using -UseBasicParsing parameter might run <script> tags that trigger IE Enhanced Security Configuration (IE ESC) errors resulting in powershell crashes.
# By using -UseBasicParsing, we skip DOM parsing with IE, no IE ESC errors are triggered
$http_response = Invoke-WebRequest -uri $sitemap -UseBasicParsing
if ($http_response.StatusCode -ne 200) { Write-Host "Could not reach main sitemap: $sitemap." -ForegroundColor yellow; pause; exit } else { Write-Host "Main sitemap reached: $sitemap" -ForegroundColor Green }
[xml]$contentInXML = $http_response.Content # (New-Object System.Net.WebClient).DownloadString($sitemap) 
if ($debug -band 4) { Format-XML -InputObject $contentInXML }

# parse main sitemap to get sitemaps as xml objects
$sitemaps = $contentInXML.sitemapindex.sitemap.loc

if ($debug -band 1) { $measure_get_total_miliseconds = 0; $measure_parse_total_miliseconds = 0; }

# get links in sitemaps
$links = @()
foreach ($s in $sitemaps) {
  $measure_get = Measure-Command {
    # Invoke-WebRequest without using -UseBasicParsing parameter might run <script> tags that trigger IE Enhanced Security Configuration (IE ESC) errors resulting in powershell crashes.
    # By using -UseBasicParsing, we skip DOM parsing with IE, no IE ESC errors are triggered
	$http_response = Invoke-WebRequest -uri $s -UseBasicParsing
    # (New-Object System.Net.WebClient).DownloadString($s) # 
    if ($http_response.StatusCode -ne 200) { Write-Host "Could not reach child sitemap: $sitemap." -ForegroundColor yellow; continue } else { Write-Host "Child sitemap reached: $s" -ForegroundColor Green }
	[xml]$contentInXML = $http_response.Content
	if ($debug -band 4) { Format-XML -InputObject $contentInXML }
	$links += $contentInXML.urlset.url.loc
	$i++
  }
  if ($debug -band 1) {
    $measure_get_total_miliseconds += $measure_get.TotalMilliseconds
    Write-Host "`tgetting link $s took" $measure_get.Milliseconds "ms" -ForegroundColor DarkCyan
  }
}

# add main sitemap to sitemaps collection
$sitemaps = ($sitemaps + $sitemap) | Sort-Object

# print sitemaps and links
Write-Host " `n>Sitemaps (total: $($sitemaps.count)):" -ForegroundColor Green
foreach ($s in $sitemaps) { Write-Host $s }
Write-Host "`n>Links (total: $($links.count))" -ForegroundColor Green
foreach ($l in $links) { Write-Host $l }

# output sitemap and links to files
if ( !(Test-Path $sitemaps_dir) ) { New-Item $sitemaps_dir -ItemType directory | Out-Null }
if ( !(Test-Path $links_dir) ) { New-Item $links_dir -ItemType directory | Out-Null }
$sitemaps | Out-File "$sitemaps_dir/$sitemaps_file$sitemaps_links_file_extension" -Encoding utf8
$links | Out-File "$links_dir/$links_file$sitemaps_links_file_extension"  -Encoding utf8
Write-Host "`n> $($sitemaps.count) sitemaps in $sitemaps_dir/$sitemaps_file$sitemaps_links_file_extension" -ForegroundColor Green
Write-Host "> $($links.count) links in $links_dir/$links_file$sitemaps_links_file_extension" -ForegroundColor Green

# tell user we are going to write curls commands for all uri sets 
Write-Host "`n`n[Writing curls for sitemaps and links...]" -ForegroundColor Cyan

# map sitemaps/links sets to names
$mapping_sitemaps_links_sets_to_names = [ordered]@{  $sitemaps_file = $sitemaps 
                                                    $links_file = $links   }

# output sitemaps/links as curls
# edit: Note: when using constructor, Hashtable will NULL if any key is empty. Using .Add() will not add a key-value pair if the key is empty.
output_curls $mapping_sitemaps_links_sets_to_names $curls_dir $OS_WinNT

# continue further only if user wants to
if ($mode_sitemap_links_only -eq 1) { pause; exit }

# build a hashtable of desired uri sets 
$desired_uri_sets = get_desired_uri_sets $tag_attribute_combos

# show the user the uri sets we will search for
Write-Host "`n`n[Desired uri sets]" -ForegroundColor Cyan
$desired_uri_sets

# scrape count
$i = 0

# map uri sets to their names
$mapping_uri_sets_to_names = [ordered]@{} # hashtable: [string] uri_set_name => [System.Collections.ArrayList] uri_set
$desired_uri_sets.GetEnumerator() | % {
    $tag = $_.key
    $attrs = $_.value
    foreach ($attr in $attrs) {
        $mapping_uri_sets_to_names."$($tag)_$($attr)" = New-Object System.Collections.ArrayList
    }
}

# tell user we are going to scrape all site's links for uri sets
Write-Host "`n`n[Scraping site's links to get desired uri sets ...]" -ForegroundColor Cyan

# create directory to store .html, if not existing
if ($mode_save_html -eq 1 -and !(Test-Path $html_dir)) { New-Item -path $html_dir -ItemType directory | Out-Null }

# scrape links and parse HTML to uris for our desired uri sets
foreach ($l in $links) {
  $measure_get = Measure-Command {
	$i++

    # scrape, while warming the link
    # Invoke-WebRequest without using -UseBasicParsing parameter might run <script> tags that trigger IE Enhanced Security Configuration (IE ESC) errors resulting in powershell crashes.
    # By using -UseBasicParsing, we skip DOM parsing with IE, no IE ESC errors are triggered
	$http_response = Invoke-WebRequest -uri $l -UseBasicParsing

    if ($http_response.StatusCode -ne 200)  { Write-Host "`n>Could not reach link: $l" -ForegroundColor yellow; continue } else { Write-Host "`n>Link $i reached: $l" -ForegroundColor Green }
    $html = $http_response.Content
	# output HTML to .html
	if ($mode_save_html -eq 1) { $html | Out-File "$html_dir/$i.html" -Encoding utf8 }

  } ## end measure_get ##

  if ($debug -band 1) {
    $measure_get_total_miliseconds += $measure_get.TotalMilliseconds
    Write-Host "`tgetting link $i took" $measure_get.Milliseconds "ms" -ForegroundColor DarkCyan
  }

  $measure_parse = Measure-Command {
    # for each desired uri set (e.g. a href, img src, img data-src ...), parse HTML to get uris 
    $desired_uri_sets.GetEnumerator() | % {
        $tag = $_.key
        $attrs = $_.value
        foreach ($attr in $attrs) {
          $measure_each_parse = Measure-Command {
            $key = "$($tag)_$($attr)"
            # pass uri set by reference 
            get_uris $html $tag $attr $mapping_uri_sets_to_names.$key # e.g. $uri_set = get_uris $html 'a' 'href' [arraylist]@()
            
            <# Unused. We passed Arraylist by reference, so we don't have returned arrays that are empty.  
            # the following lines ensures that return is an arrayList. Powershell has issues with returning empty arrays / single-item arrays. Empty arrays returned as $NULL, and single-item arrays returned as [String]. See https://surroundingthecode.wordpress.com/2011/12/12/powershell-nulls-empty-arrays-single-element-arrays/
            if ($mapping_uri_sets_to_names.$key -eq $NULL) { 
                $mapping_uri_sets_to_names.$key = New-Object System.Collections.ArrayList 
                Write-Host "Return value is null. Creating new ArrayList for key $key"
            }elseif ($mapping_uri_sets_to_names.$key -ne $NULL -and $mapping_uri_sets_to_names.$key.GetType().Name -imatch 'String') { 
                $single_uri = [String]$mapping_uri_sets_to_names.$key
                $mapping_uri_sets_to_names.$key = New-Object System.Collections.ArrayList
                $mapping_uri_sets_to_names.$key.Add($single_uri) | Out-Null
                Write-Host 'Return value is a single value. Creating new ArrayList'
            }#>

            if ($debug -band 2) { Write-Host "Tag: $tag $attr, in mapping: $($tag)_$($attr)" -ForegroundColor Gray}
          if ($debug -band 1) { Write-Host "`t parse <$tag $attr> took" $measure_each_parse.Milliseconds "ms" -ForegroundColor DarkCyan }
          } ## end measure_each_parse ##
        }
    }
  } ## end measure_parse ##
  
  if ($debug -band 1) {
    $measure_parse_total_miliseconds += $measure_parse.TotalMilliseconds
    Write-Host "`tparsing link $i took" $measure_parse.Milliseconds "ms" -ForegroundColor DarkCyan
  }
}

# tell user we successfully retrieved all uri sets from our site's links
Write-Host "`n> Successfully retrieved all uri sets from site's links." -ForegroundColor Green

# debug - any empty uri sets?
if ($debug -band 2) { 
    Write-Host "`n`n[Debug - Listing empty uri sets ...]" -ForegroundColor Gray
    $mapping_uri_sets_to_names.GetEnumerator() | % {
        $uri_set_name = $_.key
        $uri_set = $_.value
        if ($uri_set.Count -eq 0) { Write-Host "$uri_set_name set is empty" -ForegroundColor Gray }
    }
}

# debug - show individual uri sets' contents
if ($debug -band 4) { 
    Write-Host "`n`n[Debug - Showing individual uri set's content ...]" -ForegroundColor Cyan
    $mapping_uri_sets_to_names.GetEnumerator() | % {
        Write-Host "`n ---- $($_.key) ----"
        $_.value
    }
}

# replace protocol with our desired for all uris
foreach ($key in $($mapping_uri_sets_to_names.keys)) {
    $mapping_uri_sets_to_names[$key] = replace_protocol $mapping_uri_sets_to_names.$key
}

# tell user we are going to write all uri sets to individual files
Write-Host "`n`n[Writing all uri sets to their files...]" -ForegroundColor Cyan

# output uri sets to files
output_uri_sets $mapping_uri_sets_to_names $uri_sets_dir $uri_sets_file_extension

# tell user we successfully wrote all uri sets to their files
Write-Host "`n> Successfully output all uri sets to their files." -ForegroundColor Green

# tell user we are going to write curls commands for all uri sets 
Write-Host "`n`n[Writing curls for all uri sets to their files...]" -ForegroundColor Cyan

# output curls uri sets to files
output_curls $mapping_uri_sets_to_names $curls_dir $OS_WinNT

# tell user we successfully wrote curls commands for all uri sets
Write-Host "`n> Successfully wrote curls commands for all uri sets." -ForegroundColor Green

# 0 - do not warm
# 1 - warm all in a_href uri set (excluding previously scraped)
# 2 - warm all uri sets
if ($mode_warm -eq 1) {
	# tell user we are going to warm only a_href uri set
	Write-Host "`n`n[Warming only a_href uri set ...] " -ForegroundColor Cyan

	Compare-Object $mapping_uri_sets_to_names.('a_href') $links_to_scrape | where {$_.sideindicator -eq "<="} | foreach {
        $uri = $_.InputObject
        Write-Host " Warming $uri"
        $res = ''
        # [next line currently bugged. Can't warm images on *nix]
        #$res = Invoke-WebRequest -uri $uri -ErrorAction SilentlyContinue -ErrorVariable Err
        # [temp fix on next line]
        $res = Invoke-WebRequest $uri -UseBasicParsing
        if ($res.StatusCode -ne '200') { Write-Host "Could not reach $uri" -ForegroundColor yellow; }
	}

    # warm all a_hrefs that hasn't been scraped earlier
	Write-Host "> Successfully warmed all a_href uris" -ForegroundColor Green
}elseif ($mode_warm -eq 2) {
    # tell user we are going to warm all uri sets
    Write-Host "`n`n[Warming all uri sets ...] " -ForegroundColor Cyan
    
    $mapping_uri_sets_to_names.GetEnumerator() | % { 
        $uri_set_name = $_.key
        $uri_set = $_.value
        Write-Host "> Warming $uri_set_name uri set ... " -ForegroundColor Green
        $uri_set | foreach {
            Write-Host " Warming $_"
            $res = ''
            $res = Invoke-WebRequest $_ -UseBasicParsing
            if ($res.StatusCode -ne '200') { Write-Host "Could not reach $_" -ForegroundColor yellow; }
         }
    }
	Write-Host "`n> Successfully warmed all uri sets" -ForegroundColor Green
}else {}
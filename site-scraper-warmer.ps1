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

# data files and directories
# NOTE: best left in their default values.
$sitemaps_file = "sitemaps.txt"
$links_file = "links.txt"
$html_dir = "html"
$uri_sets_dir = "uri_sets"
$a_href_file = "a_href.txt"
$img_src_file = "img_src.txt"
$img_srcset_file = "img_srcset.txt"
$link_rel_file = "link_rel.txt"
$script_src_file = "script_src.txt"
$curls_dir = "curls"
$curls_sitemaps_file = "sitemaps.bat"
$curls_links_file = "links.bat"
$curls_a_href_file = "a_href.bat"
$curls_img_src_file = "img_src.bat"
$curls_img_srcset_file = "img_srcset.bat"
$curls_link_rel_file = "link_rel.bat"
$curls_script_src_file = "script_src.bat"

# whether the script should stop at just retreiving sitemaps links, or continue to get all uris from all those links
# 0 - retrieve links and continue to get all their uris
# 1 - retrieve links only
# Default: 0
$mode_sitemap_links_only = 0

# whether to warm site with all retrieved uris
# 0 - do not warm site
# 1 - warm a_href uris only
# 2 - warm all uris (a_href, img_src, img_srcset, link_rel, script_src)
# Default: 0
$mode_warm = 0

# debug mode
# 0 - turn off debugging.
# 1 - turn on debugging. 
# Default: 0
$debug = 0
############################################################# 

############### functions ###############
# checks if uri belongs to our domain
function isofdomain([string]$str) {
	# generate domain regex
	$regex_str = '(?:https?:)?\/\/' + $domain.replace('.', '\.') + '\/'
	[bool]$cond1 = $str -match $regex_str
	[bool]$cond2 = $str -match '#' # don't include
	if ( $cond1 -and !$cond2 ){
		return $true
	}else {
		return $false
	}
}

# replace protocol with our desired
function replace_protocol([array]$array) {
	#Write-Host $array.Count
	for($i=0; $i -lt $array.count; $i++) {
		$uri = $array[$i]
		$captures = [regex]::Match( $uri, '^((?:https?:)?\/\/)' ) # capture protocol part including the //
		$prot = $captures.Groups[0].Value
		$array[$i] = $uri -replace $prot, $desired_protocol

	}
	<# using foreach from: http://stackoverflow.com/questions/34166023/powershell-modify-elements-of-array
	$array = $array | foreach {
		$captures = [regex]::Match( $_, '((?:https?:)?\/\/)' )
		$prot = $captures.Groups[0].Value
		$new_uri = $_ -replace $prot, 'http://'
		$_ = $new_uri
		$_
	}#>
}
function output_curls([hashtable]$hashtable, [string]$dir) { #hashtable: uri_set_array => uri_file_string
    # create directory to store curls, if not existing
    if (!(Test-Path $curls_dir)) {New-Item -ItemType directory $dir}

    $hashtable.GetEnumerator() | % { 
        $curls = @(":: $(Get-Date) `n:: -k to ignore ssl cert")
        $uri_set = $_.key
        $uri_set_curls_file = $_.value
        foreach ($l in $uri_set) {
	        $curls += 'curl -k -X GET ' + "`"$l`"" + ' > NUL'   ## ' > /dev/null'
        }
        $curls | Out-File "$curls_dir/$uri_set_curls_file" -Encoding utf8
        Write-Host "> $($uri_set.count) curls in $curls_dir\$uri_set_curls_file" -ForegroundColor Green
    } 
}
#########################################
# Get script directory, set as cd
$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
Set-Location $scriptDir
Write-Host "Script directory: $scriptDir" -ForegroundColor Green

# check if desired protocol is valid
if ($desired_protocol -match '^https?:\/\/$' -eq $false) { Write-Host "Invalid protocol! Use either of the following:`n`thttps://`n`thttp://"; pause; exit }

# check if domain is valid
if ($domain -match '^[A-z\-\.]+$' -eq $false) { Write-Host 'Invalid domain! should only contain letters, numbers, -, and .' ; pause; exit }

# check modes 
if(($mode_sitemap_links_only -gt 1) -or ($mode_sitemap_links_only -lt 0)) { Write-Host "Invalid `$mode_sitemap_links_only! Use integer values from 0 to 1." -ForegroundColor Yellow; pause; exit}
elseif(($mode_warm -gt 2) -or ($mode_warm -lt 0)) { Write-Host "Invalid `$mode_warm! Use integer values from 0 to 1." -ForegroundColor Yellow;	pause; exit}

# check for write permissions in script directory
Try { [io.file]::OpenWrite($sitemaps_file).close() }
Catch { Write-Warning "Script directory has to be writeable to output links to files!" }

Write-Host "`n`n[Scraping sitemap(s) for links ...]" -ForegroundColor Cyan
# get main sitemap as xml object
$http_response = ''
$http_response = Invoke-WebRequest -Uri $sitemap -UseBasicParsing
if($http_response.StatusCode -ne '200') { Write-Host "Could not reach main sitemap: $sitemap." -ForegroundColor yellow; pause; exit } else { Write-Host "Main sitemap reached: $sitemap" -ForegroundColor Green }
[xml]$contentInXML = $http_response.Content # (New-Object System.Net.WebClient).DownloadString($sitemap) #  
if($debug) { Format-XML -InputObject $contentInXML }

# parse main sitemap to get sitemaps as xml objects
$sitemaps = $contentInXML.sitemapindex.sitemap.loc

# get links in sitemaps
$links = @()
foreach ($s in $sitemaps) {
	Write-Host "> Retreiving $s"
	[xml]$contentInXML = ((Invoke-WebRequest -Uri $s -UseBasicParsing).Content)  # (New-Object System.Net.WebClient).DownloadString($s) # 
	if($debug) { Format-XML -InputObject $contentInXML }
	$links += $contentInXML.urlset.url.loc
	$i++
}

# print sitemaps and links
Write-Host " `n>Sitemaps (total: $($sitemaps.count)):" -ForegroundColor Green
foreach ($s in $sitemaps) { Write-Host $s }
Write-Host "`n>Links (total: $($links.count))" -ForegroundColor Green
foreach ($l in $links) { Write-Host $l }

# output sitemap and links to files
$sitemaps | Out-File $sitemaps_file -Encoding utf8
$links | Out-File $links_file  -Encoding utf8
Write-Host "`n> $($sitemaps.count) sitemaps in $sitemaps_file" -ForegroundColor Green
Write-Host "> $($links.count) links in $links_file" -ForegroundColor Green

# tell user we are going to write curls commands for all uri sets 
Write-Host "`n`n[Writing curls for sitemaps and links...]" -ForegroundColor Cyan

# output curls of sitemap and links to files
$hashtable0 = @{$sitemaps = $curls_sitemaps_file
                $links = $curls_links_file}
output_curls $hashtable0 $curls_dir

# continue further only if user wants to
if($mode_sitemap_links_only -eq 1) { pause; exit }

# tell user we are going to scrape all links for uri sets
Write-Host "`n`n[Scraping links to get uri sets ...]" -ForegroundColor Cyan

# scrape all links from our site for all uri sets
$links_to_scrape = Get-Content -Path $links_file
$a_href_all = @()
$link_rel_all = @()
$img_src_all = @()
$img_srcset_all = @()
$script_src_all = @()
$i = 0; # number of scrapes

# create directory to store .html, if not existing
if (!(Test-Path $html_dir)) {New-Item -ItemType directory $html_dir} # create html folder if not existing

# scrape links and parse .html to get uri sets: <a href>, <img src>, <img srcset>, <link rel>, <script src>
foreach ($l in $links_to_scrape) {
	$i++
	# Scrape, while warming the link
	$html = Invoke-WebRequest -uri $l #-UseBasicParsing
    
	# output html to file
	$html.Content | Out-File "$html_dir\$i.html" -Encoding utf8

	# parse html to get uri sets: <a href>, <img src>, <img srcset>, <link rel>, <script src>
	$html.links | foreach {
		$val = $_.href
		if(isofdomain($val)) {
			if (!$a_href_all.Contains($val)) {
				$a_href_all += $val
			}
		}
	}
	$html.Images | foreach {
		$val = $_.src
		if(isofdomain($val)) {
			if (!$img_src_all.Contains($val)) {
				$img_src_all += $val
			}
		}
	}
	$html.Images | foreach {
		# if no srcset, continue with next
		if(!$_.srcset) { <#Write-Host 'no srcset';#> return } # continue is return for powershell 
		
		# break up srcsets
		$val = $_.srcset
		$vals = $val.Split(',')
		$vals | foreach {
			$captures = [regex]::Match( $_, '((?:https?:)?\/\/' + $domain.replace('.', '\.') + '\/[^\s]+)' )
			$src = $captures.Groups[0].Value
			if(isofdomain($src)) {
				if (!$img_srcset_all.Contains($src)) {
					$img_srcset_all += $src
				}
			}
		}
	}
	$html.ParsedHtml.getElementsByTagName('link') | foreach {
		$val = $_.getAttributeNode('href').value
		if(isofdomain($val)) {
			if (!$link_rel_all.Contains($val)) {
				$link_rel_all += $val
			}
		}
	  
	}
	$html.ParsedHtml.getElementsByTagName('script') | foreach {
		$val = $_.getAttributeNode('src').value
		if(isofdomain($val)) {
			if (!$script_src_all.Contains($val)) {
				$script_src_all += $val
			}
		}
	   
	}

}
Write-Host "> Successfully retrieved all uri sets." -ForegroundColor Green
# map uri sets to files
$hashtable1=[ordered]@{  $a_href_all = $a_href_file;
						$img_src_all = $img_src_file;
						$img_srcset_all = $img_srcset_file;
						$link_rel_all = $link_rel_file; 
						$script_src_all = $script_src_file ;}
# replace protocol with our desired for all uris
$hashtable1.GetEnumerator() | % { 
   replace_protocol ($_.key)
}

# tell user we are going to write all uri sets to individual files
Write-Host "`n`n[Writing all uri sets to their files...]" -ForegroundColor Cyan

# create directory to store uri_sets, if not existing
if (!(Test-Path $uri_sets_dir)) {New-Item -ItemType directory $uri_sets_dir}

# output uri sets to files
$hashtable1.GetEnumerator() | % { 
   $uri_set = $_.key
   $uri_set_file = $_.value
   $uri_set | Out-File "$uri_sets_dir\$uri_set_file" -Encoding utf8
   Write-Host "> $($uri_set.count) uris in $uri_sets_dir\$uri_set_file" -ForegroundColor Green
}

# tell user we successfully wrote all uri sets to their files
Write-Host "`n> Successfully output all uri sets to their files." -ForegroundColor Green

# tell user we are going to write curls commands for all uri sets 
Write-Host "`n`n[Writing curls for all uri sets to their files...]" -ForegroundColor Cyan

# output curls uri sets to files
$hashtable2=[ordered]@{ $a_href_all = $curls_a_href_file;
                        $img_src_all = $curls_img_src_file;
                        $img_srcset_all = $curls_img_srcset_file;
                        $link_rel_all = $curls_link_rel_file; 
                        $script_src_all = $curls_script_src_file ;}
output_curls $hashtable2 $curls_dir

# tell user we successfully wrote curls commands for all uri sets
Write-Host "`n> Successfully wrote curls commands for all uri sets." -ForegroundColor Green

# 0 - do not warm
# 1 - warm all in a_href uri set (excluding previously scraped)
# 2 - warm all uri sets
if($mode_warm -eq 1) {
	# tell user we are going to warm only a_href uri set
	Write-Host "`n`n[Warming only a_href uri set ...] " -ForegroundColor Cyan

	# warm all a_hrefs that hasn't been scraped earlier
	Compare-Object $a_href_all $links_to_scrape | where {$_.sideindicator -eq "<="} | foreach {
		$tmp = Invoke-RestMethod -uri $_.InputObject # Invoke-WebRequest -uri $_.InputObject
	}
	Write-Host "> Successfully warmed all a_href uris" -ForegroundColor Green
}elseif($mode_warm -eq 2) {
	# tell user we are going to warm all uri sets
	Write-Host "`n`n[Warming all uri sets ...] " -ForegroundColor Cyan

	$hashtable1.GetEnumerator() | % { 
		$uri_set = $_.key
		$uri_set_file = $_.value
		Write-Host "> Warming $uri_set_file uri set ... " -ForegroundColor Green
		$uri_set | foreach {
			$tmp = Invoke-RestMethod -uri $_
		}
	}
	Write-Host "`n> Successfully warmed all uris sets" -ForegroundColor Green
}else {}

pause
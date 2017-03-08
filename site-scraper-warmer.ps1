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
$sitemaps_file = "sitemaps.txt"
$links_file = "links.txt"
$html_dir = "html"
$uri_sets_dir = "uri_sets"
$uri_sets_file_extension = ".txt"
$curls_dir = "curls"
$curls_sitemaps_file = "sitemaps"
$curls_links_file = "links"

# whether the script should stop at just retreiving sitemaps links, or continue to get all uris from all those links
# 0 - retrieve links and continue to get all their uris
# 1 - retrieve links only
# Default: 0
$mode_sitemap_links_only = 0

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
# 1 - turn on debugging. 
# Default: 0
$debug = 0

# suppress errors
# NOTE: do not edit
$ErrorActionPreference= 'silentlycontinue'
############################################################# 

############### functions ###############
# checks if uri is valid.
function uri_is_valid ([string]$str) {
	# don't include uri's with hash sign
    [bool]$cond1 = $str -match '#' 

    # include uris of our domain
    [bool]$cond2 = $str -match '^(?:https?:)?\/\/' + $domain.replace('.', '\.').replace('-', '\-') 

    if ( $cond1 ){
		return $false
	}
    if ( $cond2 ) {
        return $true
    }
    return $false
}

# manually parses html to get uris for a specific tag-attribute pairing.
 # Param 1: html string
 # Param 2: html tag e.g. img
 # Param 3: html tag's attribute e.g. src
 # Param 4: [System.Collections.ArrayList] arraylist to store uris
#
function get_uris ([string]$html_str, [string]$tag, [string]$attr, [System.Collections.ArrayList]$arraylist) {
    # split html by html tag opening char i.e. <
    $html_arr = $html_str.split('<')

    # for each line with tag of interest found, do
    $html_arr | where { $_ -match "^$tag "} | foreach { # e.g. <img 
        # capture attribute's value
        $attr_regex = $attr.replace('.', '\.').replace('-', '\-') 
        $regex = " $attr_regex=(?:`"([^`"]*)`"|'([^']*)')" # e.g. data\-src="(https://theohbrothers.com/)"
        $captures = [regex]::Match( $_, $regex ) 
        $attr_val = if($captures.Groups[1].value -ne '') {$captures.Groups[1].value} else {$captures.Groups[2].value}
        if($debug) { write-host "`n$_`nRegex:$regex`n Group 1 (double-quotes) found: $($captures.Groups[1].value -eq ''), Group 2 (single-quotes) found: $($captures.Groups[2].value -eq '') `n 1: $($captures.Groups[1].value)`n 2: $($captures.Groups[2].value)"; }

        # in the case of comma-delimited values e.g. <img srcset>, split values
        $attr_vals = $attr_val.Split(',') # for <img srcset="http://tob.com/1.jpg 150w, http://tob.com/2.jpg 250w, ..."
        
        # for each value, do
        $attr_vals | foreach {
            $regex = "((?:https?:)?\/\/[^\s`'`"]+)"  # matches uris
			$captures = [regex]::Match( $_, $regex)
			$val = $captures.Groups[0].Value

            # filter uris we want
			if (uri_is_valid ($val)) {
				if (!$arraylist.Contains($val)) {
					$null = $arraylist.Add($val) # assigning it to $null removes arraylist's Add()'s return value.
				}
			}
        } 
    }
    #return $array
}

# replaces protocol with our desired
 # Param 1: array or System.Collections.ArrayList
function replace_protocol($array) {
	#Write-Host $array.Count
	for($i=0; $i -lt $array.count; $i++) {
		$uri = $array[$i]
		$matches = [regex]::Match( $uri, '^((?:https?:)?\/\/)' ) # capture protocol part including the //
		$uri_protocol = $matches.Groups[1].Value
		$array[$i] = $uri -replace $uri_protocol, $desired_protocol
	}
	<# using foreach from: http://stackoverflow.com/questions/34166023/powershell-modify-elements-of-array
	$array = $array | foreach {
		$matches = [regex]::Match( $_, '((?:https?:)?\/\/)' )
		$uri_protocol = $matches.Groups[1].Value
		$new_uri = $_ -replace $uri_protocol, 'http://'
		$_ = $new_uri
		$_
	}#>
}
# ouputs curls to a file
 # Param 1: # hashtable of format: [System.Collections.ArrayList] uri_set => [string] uri_set_filename
 # Param 2: directory to write curl files 
 # Param 3: OS that curls will run on. 0: *nix; 1: WinNT
#
function output_curls($hashtable, [string]$dir, [int]$OS) {
    # create directory to store curls, if not existing
    if (!(Test-Path $dir)) {$null = New-Item -ItemType directory $dir} # Assigning it to $null removes the return value
    $commentChar = if($OS -eq 1) { "::" } else { "#" }
    $toNull = if($OS -eq 1) { " >NUL" } else { " > /dev/null " }
    $extension = if($OS -eq 1) { ".bat" } else { ".sh" }
    $hashtable.GetEnumerator() | % { 
        $curls = @("$commentChar $(Get-Date)", "$commentChar -k to ignore ssl cert")
        $uri_set = $_.key
        $uri_set_curls_file = $_.value
        foreach ($uri in $uri_set) {   
	        $curls += "curl -k -X GET $uri $toNull"
        }
        $curls | Out-File "$dir/$uri_set_curls_file$extension" -Encoding utf8
        Write-Host "> $($uri_set.count) curls in $dir/$uri_set_curls_file$extension" -ForegroundColor Green
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

# check modes and OS
if (($mode_sitemap_links_only -gt 1) -or ($mode_sitemap_links_only -lt 0)) { Write-Host "Invalid `$mode_sitemap_links_only! Use integer values from 0 to 1." -ForegroundColor Yellow; pause; exit}
elseif(($mode_warm -gt 2) -or ($mode_warm -lt 0)) { Write-Host "Invalid `$mode_warm! Use integer values from 0 to 2." -ForegroundColor Yellow;	pause; exit}
if (($OS_WinNT -gt 1) -or ($OS_WinNT -lt 0)) { Write-Host "Invalid `$OS_WinNT! Use integer values from 0 to 1." -ForegroundColor Yellow; pause; exit}

# check for write permissions in script directory
Try { [io.file]::OpenWrite($sitemaps_file).close() }
Catch { Write-Warning "Script directory has to be writeable to output links to files!" }

Write-Host "`n`n[Scraping sitemap(s) for links ...]" -ForegroundColor Cyan
# get main sitemap as xml object
$http_response = ''
$http_response = Invoke-WebRequest -Uri $sitemap -UseBasicParsing
if ($http_response.StatusCode -ne '200') { Write-Host "Could not reach main sitemap: $sitemap." -ForegroundColor yellow; pause; exit } else { Write-Host "Main sitemap reached: $sitemap" -ForegroundColor Green }
[xml]$contentInXML = $http_response.Content # (New-Object System.Net.WebClient).DownloadString($sitemap) #  
if ($debug) { Format-XML -InputObject $contentInXML }

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

# add main sitemap to sitemaps collection
$sitemaps = ($sitemaps + $sitemap) | Sort-Object

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
# edit: 2017 March - not using constructor anymore. Hashtable will NULL if any key is empty.)
<#$hashtable0 = [ordered]@{$sitemaps = $curls_sitemaps_file
                         $links = $curls_links_file}#>
$hashtable0 = [ordered]@{}
    $hashtable0.Add($sitemaps, $curls_sitemaps_file)
    $hashtable0.Add($links, $curls_links_file)
output_curls $hashtable0 $curls_dir $OS_WinNT

# continue further only if user wants to
if($mode_sitemap_links_only -eq 1) { pause; exit }

# determine uri_sets that should be search for
$uri_sets = [ordered]@{} # hashtable: [string]$tag => [array]$attributes
foreach ($combo in $tag_attribute_combos) {
    $split = $combo.split( @(',', ' ') ).trim() | ? {$_} # exclude empty values. 
   
    for($i=0; $i -lt $split.count; $i++) {
        # skip over odd numbers
        if($i % 2) { continue } 

        $tag  = $split[$i]
        $attr = $split[$i+1]

        
        # skip over invalid tags / attributes (may contain letters and dashes only)
        if($tag -match [regex]"^[A-Za-z\-]+" -eq $false -or $tag -match [regex]"^[A-Za-z\-]+" -eq $false) { continue }

        if($uri_sets.Contains($tag) -eq $false) {
            # first tag of its kind found, add the combination
            $uri_sets.Add($tag, [array]$attr) # e.g. 'a' => @('href'), e.g. 'img' => @('src')
        }
        else
        {
            # append more attributes for an existing tag
            $attrs = $uri_sets.($tag) # retrieve the existing attributes
            if($attrs.Contains($attr) -eq $false) {
                $attrs += $attr    # add new attribute for this tag
                $uri_sets.($tag) = $attrs #e.g. 'img' => @('src', 'srcset')
            }
        }
    }
}


# show the user the uri sets we will search for
Write-Host "`n`n[Uri sets to search for]" -ForegroundColor Cyan
$uri_sets 

# get all links of our site to scrape 
$links_to_scrape = Get-Content -Path $links_file -Encoding utf8

# scrape count
$i = 0;

# declare/reset the uri set variables e.g. $a_href_all, $img_src_all, $img_data-src_all, ...
$uri_sets.GetEnumerator() | % {
    $tag = $_.key
    $attrs = $_.value
    foreach ($attr in $attrs) {
        $new = New-Object System.Collections.ArrayList
        Set-Variable -Name "$($tag)_$($attr)_all" -Value $new
    }
}
# tell user we are going to scrape all site's links for uri sets
Write-Host "`n`n[Scraping site's links to get desired
 uri sets ...]" -ForegroundColor Cyan

# create directory to store .html, if not existing
if (!(Test-Path $html_dir)) {$null = New-Item -ItemType directory $html_dir; }  # Assigning it to $null removes the return value

# scrape links and parse .html to get uri sets: <a href>, <img src>, <img srcset>, <link href>, <script src>
foreach ($l in $links_to_scrape) {
	$i++
	# Scrape, while warming the link
	$html = Invoke-WebRequest -uri $l -UseBasicParsing
    
	# output html to file
	$html.Content | Out-File "$html_dir/$i.html" -Encoding utf8

	# parse html to get uri sets: <a href>, <img src>, <img srcset>, <link href>, <script src>
    # edit 2017 March - not using engine to parse html anymore
	<#$html.links | foreach {
		$val = $_.href
		if (uri_is_valid($val)) {
			if (!$a_href_all.Contains($val)) {
				$a_href_all += $val
			}
		}
	}
	$html.Images | foreach {
		$val = $_.src
		if (uri_is_valid($val)) {
			if (!$img_src_all.Contains($val)) {
				$img_src_all += $val
			}
		}
	}#>
    # use manual parsing of offline html for other uri sets (works on *nix without IE's parsing)
    $html = Get-Content "$html_dir/$i.html" -Raw -Encoding utf8
    $uri_sets.GetEnumerator() | % {
        $tag = $_.key
        $attrs = $_.value
        foreach ($attr in $attrs) {
            $uri_set = Get-Variable -Name "$($tag)_$($attr)_all" -ValueOnly # returns null if variable doesn't exist, or else returns an arraylist
            get_uris $html $tag $attr $uri_set         # e.g. $uri_set = get_uris $html 'a' 'href' $uri_set_all 
            # declare new variable with value
            Set-Variable -Name "$($tag)_$($attr)_all" -Value $uri_set  # e.g. $a_href_all = $uri_set, e.g. $img_src_all = $uri_set
            if($debug) { "$tag $attr $($tag)_$($attr)_all" }
        }
    }
}
# tell user we successfully retrieved all uri sets from our site's links
Write-Host "> Successfully retrieved all uri sets from site's links." -ForegroundColor Green

# debug - any empty uri sets?
if ($debug) { 
    Write-Host "`n`n[Debug - Checking for any empty uri sets ...]" -ForegroundColor Cyan
    $uri_sets.GetEnumerator() | % {
        $tag = $_.key
        $attrs = $_.value
        foreach ($attr in $attrs) {
            if( (Get-Variable -Name "$($tag)_$($attr)_all" -ValueOnly) -eq $NULL) { 
                Write-Host "$($tag)_$($attr)_all set is empty" -ForegroundColor Gray  
            }
        }
        
    }
}

# map uri sets to files 
# edit: 2017 March - not using constructor anymore. Hashtable will NULL if any key is empty.)
# using .Add() will not add a key-value pair if the key is empty.
$hashtable1 = [ordered]@{} # hashtable: [System.Collections.ArrayList] uri_set => [string] uri_set_filename_without_extension
$uri_sets.GetEnumerator() | % {
    $tag = $_.key
    $attrs = $_.value
    foreach ($attr in $attrs) {
        $uri_set = Get-Variable -Name "$($tag)_$($attr)_all" -ValueOnly 
        if($uri_set.count -eq 0) { $null = $uri_set.Add('') } # if uri_set is null, give it an empty value anyway. Assigning it to $null removes arraylist's Add()'s return value.
        $uri_set_filename = "$($tag)_$($attr)" # e.g. a_href
        $hashtable1.Add($uri_set, $uri_set_filename);
    }  
}

# debug - show individual uri sets' contents
if ($debug) { 
    Write-Host "`n`n[Debug - Showing individual uri set's content ...]" -ForegroundColor Cyan
    $hashtable1.GetEnumerator() | % {
        Write-Host "`n ---- $($_.value) ----"
        $_.key
    }
}

# replace protocol with our desired for all uris
$hashtable1.GetEnumerator() | % { 
   replace_protocol ($_.key)
}

# tell user we are going to write all uri sets to individual files
Write-Host "`n`n[Writing all uri sets to their files...]" -ForegroundColor Cyan

# create directory to store uri_sets, if not existing
if (!(Test-Path $uri_sets_dir)) {$null = New-Item -ItemType directory $uri_sets_dir}  # Assigning it to $null removes the return value

# output uri sets to files
$hashtable1.GetEnumerator() | % { 
   $uri_set = $_.key
   $uri_set_filename = $_.value
   $uri_set | Out-File "$uri_sets_dir/$uri_set_filename$uri_sets_file_extension" -Encoding utf8
   Write-Host "> $($uri_set.count) uris in $uri_sets_dir/$uri_set_filename$uri_sets_file_extension" -ForegroundColor Green
}

# tell user we successfully wrote all uri sets to their files
Write-Host "`n> Successfully output all uri sets to their files." -ForegroundColor Green

# tell user we are going to write curls commands for all uri sets 
Write-Host "`n`n[Writing curls for all uri sets to their files...]" -ForegroundColor Cyan

# output curls uri sets to files
output_curls $hashtable1 $curls_dir $OS_WinNT

# tell user we successfully wrote curls commands for all uri sets
Write-Host "`n> Successfully wrote curls commands for all uri sets." -ForegroundColor Green

# 0 - do not warm
# 1 - warm all in a_href uri set (excluding previously scraped)
# 2 - warm all uri sets
if($mode_warm -eq 1) {
	# tell user we are going to warm only a_href uri set
	Write-Host "`n`n[Warming only a_href uri set ...] " -ForegroundColor Cyan

	Compare-Object $a_href_all $links_to_scrape | where {$_.sideindicator -eq "<="} | foreach {
        $uri = $_.InputObject
        Write-Host " Warming $uri"
        $res = ''
        # [next line currently bugged. Can't warm images on *nix]
        #$res = Invoke-WebRequest -uri $uri -ErrorAction SilentlyContinue -ErrorVariable Err
        # [temp fix on next line]
        $res = curl $uri # curl is an alias to Invoke-WebRequest on winNT, but runs actual curl binary on *nix
        if($OS_WinNT -eq 1 -and $res.StatusCode -ne '200') { Write-Host "Could not reach $uri" -ForegroundColor yellow; }
	}

    # warm all a_hrefs that hasn't been scraped earlier
	Write-Host "> Successfully warmed all a_href uris" -ForegroundColor Green
}elseif($mode_warm -eq 2) {
	# tell user we are going to warm all uri sets
	Write-Host "`n`n[Warming all uri sets ...] " -ForegroundColor Cyan

	$hashtable1.GetEnumerator() | % { 
		$uri_set = $_.key
		$uri_set_file = $_.value
		Write-Host "> Warming $uri_set_file uri set ... " -ForegroundColor Green
		$uri_set | foreach {
            Write-Host " Warming $uri"
            $res = ''
            # [next line currently bugged. Can't warm images on *nix]
            #$res = Invoke-WebRequest -uri $_ -ErrorAction SilentlyContinue -ErrorVariable Err
            # [temp fix on next line]
            $res = curl $uri # curl is an alias to Invoke-WebRequest on winNT, but runs actual curl binary on *nix
            if($OS_WinNT -eq 1 -and $res.StatusCode -ne '200') { Write-Host "Could not reach $uri" -ForegroundColor yellow; }
		}
	}
	Write-Host "`n> Successfully warmed all uri sets" -ForegroundColor Green
}else {}
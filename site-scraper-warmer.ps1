# Get script directory, set as cd
$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
Set-Location $scriptDir
Write-Host "Script directory: $scriptDir" -ForegroundColor Green

# Includes
. .\config.ps1
. .\functions.ps1

# Check if desired protocol is valid 
if ($desired_protocol -match '^https?:\/\/$' -eq $false) { Write-Error "Invalid protocol! Use either of the following:`n`thttps://`n`thttp://"; exit }

# Check if domain is valid
if ($domain -match '^[A-z0-9\-\.]+$' -eq $false) { Write-Error 'Invalid domain! should only contain letters, numbers, -, and .' ; exit }

# Check modes and OS
if (($mode_sitemap_links_only -gt 1) -or ($mode_sitemap_links_only -lt 0)) { Write-Error "Invalid `$mode_sitemap_links_only! Use integer values from 0 to 1."; exit }
if (($mode_output_force_protocol -gt 1) -or ($mode_output_force_protocol -lt 0)) { Write-Error "Invalid `$mode_output_force_protocol! Use integer values from 0 to 1."; exit }
if (($mode_save_html -gt 1) -or ($mode_save_html  -lt 0)) { Write-Error "Invalid `$mode_save_html! Use integer values from 0 to 1."; exit }
if (($mode_warm -gt 2) -or ($mode_warm -lt 0)) { Write-Error "Invalid `$mode_warm! Use integer values from 0 to 2."; exit }
if (($OS_WinNT -gt 1) -or ($OS_WinNT -lt 0)) { Write-Error "Invalid `$OS_WinNT! Use integer values from 0 to 1."; exit }

# Check for write permissions in script directory
Try { New-Item '_test' | Out-Null; If (Test-Path '_test') { Remove-Item '_test' } }
Catch { Write-Error "Script directory has to be writeable to output to files!"; exit;}

# Get main sitemap as xml object
Write-Host "`n`n[Scraping sitemap(s) for links ...]" -ForegroundColor Cyan
# Invoke-WebRequest without using -UseBasicParsing parameter might run <script> tags that trigger IE Enhanced Security Configuration (IE ESC) errors resulting in powershell crashes.
# By using -UseBasicParsing, we skip IE's DOM parsing. No IE ESC errors are triggered
# (New-Object System.Net.WebClient).DownloadString($sitemap) 
Try {
    $res = ''
    $res = Invoke-WebRequest -uri $sitemap -UseBasicParsing
    $res_code = $res.StatusCode
}Catch {
    # Catch 50x exceptions 
    $res_code = $_.Exception.Response.StatusCode.Value__
    
    # Write non-http errors
    if (!$res_code) { Write-Error $_.Exception.Message }
}
if ($res_code -and $res_code -eq 200) { 
    # Sitemap not reachable. Exit
    Write-Host "Main sitemap reached: $sitemap" -ForegroundColor Green 
} else { 
    Write-Error "Could not reach main sitemap: $sitemap. Error code: $res_code. Ensure your config file points to a valid and existing sitemap."
    exit 
}
$contentInXML = $res.Content -as [xml] 
if ($contentInXML -eq $Null) { 
    # Returned resource not parsable as xml. Exit
    Write-Error "Cannot continue. Either the returned resource is an invalid sitemap (i.e. improperly formatted), or not a sitemap. In the latter case, ensure you modify the script config file to use the correct sitemap location."; 
    exit 
} 
if ($debug -band 4) { $contentInXML | Format-XML | Out-String | % { Write-Host $_.Trim() } }

# Populate our sitemaps collection
$sitemaps = New-Object System.Collections.ArrayList
# Add our parent sitemap
$sitemaps.Add($sitemap) | Out-Null
# Add our child sitemaps
$contentInXML.sitemapindex.sitemap.loc | foreach {
    # Add only non-empty links
    $sitemaps.Add($_) | Out-Null
}
# Sort sitemaps alphabetically
$sitemaps = $sitemaps | Sort-Object

if ($debug -band 1) { $measure_get_total_miliseconds = 0; $measure_parse_total_miliseconds = 0; }

# Get links from all sitemaps
$links = New-Object System.Collections.ArrayList
foreach ($s in $sitemaps) {
    $measure_get = Measure-Command {
        Try {
            $res = ''
            $res = Invoke-WebRequest -uri $s -UseBasicParsing
            $res_code = $res.StatusCode
        }Catch { 
            # Catch 50x exceptions 
            $res_code = $_.Exception.Response.StatusCode.Value__
            
            # Write non-http errors
            if (!$res_code) { Write-Error $_.Exception.Message }
        }
        if ($res_code -and $res_code -eq 200) { 
            Write-Host "Sitemap reached: $s" -ForegroundColor Green 
            $contentInXML = $res.Content -as [xml]
            if ($contentInXML -eq $Null) { 
                 # Returned resource not parsable as xml. Skip over it.
                 Write-Error "Skipping over an invalid sitemap: $s. Either the returned resource is an invalid sitemap (i.e. improperly formatted), or not a sitemap."
                 continue
            }
            if ($debug -band 4) { $contentInXML | Format-XML | Out-String | % { Write-Host $_.Trim() } }
            $contentInXML.urlset.url.loc | ? { $_ } | foreach {
                # Add only non-empty links
                $links.Add($_)
            }
        }else { 
            Write-Error "Could not reach sitemap: $s. Error code: $res_code" -ForegroundColor yellow; continue 
        }
    }
    if ($debug -band 1) {
        $measure_get_total_miliseconds += $measure_get.TotalMilliseconds
        Write-Host "`tgetting links from sitemap $s took $($measure_get.Milliseconds) ms" -ForegroundColor DarkCyan
    }
}

# Print sitemaps and links
Write-Host " `n>Sitemaps (total: $($sitemaps.count)):" -ForegroundColor Green
$sitemaps | foreach { Write-Host $_ }
Write-Host "`n>Links (total: $($links.count))" -ForegroundColor Green
$links | foreach { Write-Host $_ }

# Output sitemap and links to files
if ( !(Test-Path $sitemaps_dir) ) { New-Item $sitemaps_dir -ItemType directory | Out-Null }
if ( !(Test-Path $links_dir) ) { New-Item $links_dir -ItemType directory | Out-Null }
$sitemaps | Out-File "$sitemaps_dir/$sitemaps_file$sitemaps_links_file_extension" -Encoding utf8
$links | Out-File "$links_dir/$links_file$sitemaps_links_file_extension" -Encoding utf8
Write-Host "`n> $($sitemaps.count) sitemaps in $sitemaps_dir/$sitemaps_file$sitemaps_links_file_extension" -ForegroundColor Green
Write-Host "> $($links.count) links in $links_dir/$links_file$sitemaps_links_file_extension" -ForegroundColor Green

# Tell user we are going to write curls commands for all uri sets 
Write-Host "`n`n[Writing curls for sitemaps and links...]" -ForegroundColor Cyan

# Map sitemaps/links sets to names
# Note: when using constructor, Hashtable will NULL if any key is empty. Using .Add() will not add a key-value pair if the key is empty.
$mapping_sitemaps_links_sets_to_names = [ordered]@{  $sitemaps_file = $sitemaps 
                                                     $links_file = $links  }

# Output sitemaps/links as curls
output_curls $mapping_sitemaps_links_sets_to_names $curls_dir $OS_WinNT

# Continue further only if user wants to
if ($mode_sitemap_links_only -eq 1) { exit }

# Build a hashtable of desired uri sets 
$desired_uri_sets = get_desired_uri_sets $tag_attribute_combos

# Show the user the uri sets we will search for
Write-Host "`n`n[Desired uri sets]" -ForegroundColor Cyan
$desired_uri_sets | Format-List | Out-String | % { Write-Host $_.Trim() }

# Map uri sets to their names
$mapping_uri_sets_to_names = [ordered]@{} # hashtable: [string] uri_set_name => [System.Collections.ArrayList] uri_set
$desired_uri_sets.GetEnumerator() | % {
    $tag = $_.Key
    $attrs = $_.Value
    foreach ($attr in $attrs) {
        $mapping_uri_sets_to_names."$($tag)_$($attr)" = New-Object System.Collections.ArrayList
    }
}

# Get ready to scrape HTML
$i = 0

# Tell user we are going to scrape all site's links for desired uri sets
Write-Host "`n`n[Scraping site's links to get desired uri sets ...]" -ForegroundColor Cyan

# Create directory to store .html, if not existing
if ($mode_save_html -eq 1 -and !(Test-Path $html_dir)) { New-Item -path $html_dir -ItemType directory | Out-Null }

# Get and parse links' HTML for uris, populating desired uri sets
foreach ($l in $links) {
    $html = ''
    $measure_get = Measure-Command {
        $i++
       
        $res_code = 0
        $html = ''
        Try {
            # Scrape, while warming the link
            # Invoke-WebRequest without using -UseBasicParsing parameter might run <script> tags that trigger IE Enhanced Security Configuration (IE ESC) errors resulting in powershell crashes.
            # By using -UseBasicParsing, we skip DOM parsing with IE, no IE ESC errors are triggered
            $res = ''
            $res = Invoke-WebRequest -uri $l -UseBasicParsing
            $res_code = $res.StatusCode
            $html = $res.Content
        }Catch { 
            # Catch 50x exceptions 
            $res_code = $_.Exception.Response.StatusCode.Value__

            # Write non-http errors
            if (!$res_code) { Write-Error $_.Exception.Message }
        }
        if ($res_code -and $res_code -eq 200) { 
            Write-Host "`n>Link $i reached: $l" -ForegroundColor Green
            
            # Output HTML to .html
            if ($mode_save_html -eq 1) {
                $html | Out-File "$html_dir/$i.html" -Encoding utf8
            }
        }else {
            Write-Error "`n>Could not reach link: $l. Error code: $res_code";
            continue
        }
    } ## End measure_get ##

    if ($debug -band 1) {
        $measure_get_total_miliseconds += $measure_get.TotalMilliseconds
        Write-Host "`tgetting link $i took $($measure_get.Milliseconds) ms" -ForegroundColor DarkCyan
    }

    $measure_parse = Measure-Command {
        # For each desired uri set (e.g. <a href>, <img src>, <img data-src> ...), parse HTML to get uris 
        $desired_uri_sets.GetEnumerator() | % {
            $tag = $_.key
            $attrs = $_.value
            foreach ($attr in $attrs) {
                $measure_each_parse = Measure-Command {
                    # Key for this set will be in format <tag>_<attr>. E.g. 'a_href' or 'img_src'
                    $key = "$($tag)_$($attr)"
                    # Populate uri set
                    get_uris $html $tag $attr $mapping_uri_sets_to_names[$key]
                   
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

                    if ($debug -band 2) { Write-Host "Tag-Attribute combo: <$tag $attr>, key: $key. Uri set count: $($mapping_uri_sets_to_names[$key].Count)" -ForegroundColor Gray}
                } ## End measure_each_parse ##
                if ($debug -band 1) { Write-Host "`t parse <$tag $attr> took $($measure_each_parse.Milliseconds) ms" -ForegroundColor DarkCyan }
            }
        }
    } ## End measure_parse ##
    
    if ($debug -band 1) {
        $measure_parse_total_miliseconds += $measure_parse.TotalMilliseconds
        Write-Host "`tparsing link $i took" $measure_parse.Milliseconds "ms" -ForegroundColor DarkCyan
    }
}

# Tell user we successfully retrieved all uri sets from our site's links
Write-Host "`n> Successfully retrieved all uri sets from site's links." -ForegroundColor Green

# Debug - any empty uri sets?
if ($debug -band 2) { 
    Write-Host "`n`n[Debug - Listing empty uri sets ...]" -ForegroundColor Gray
    $mapping_uri_sets_to_names.GetEnumerator() | % {
        $uri_set_name = $_.Key
        $uri_set = $_.Value
        if ($uri_set.Count -eq 0) { Write-Host "$uri_set_name set is empty" -ForegroundColor Gray }
    }
}

# Debug - show individual uri sets' contents
if ($debug -band 4) { 
    Write-Host "`n`n[Debug - Showing individual uri set's content ...]" -ForegroundColor Cyan
    $mapping_uri_sets_to_names.GetEnumerator() | % {
        Write-Host "`n ---- $($_.Key) ----`n$($_.Value)"
        
    }
}

# Replace protocol with our desired for all uris, if desired
if ($mode_output_force_protocol) {
    foreach ($key in $($mapping_uri_sets_to_names.Keys)) {
        replace_protocol $mapping_uri_sets_to_names[$key] $desired_protocol
    }
}

# Tell user we are going to write all uri sets to individual files
Write-Host "`n`n[Writing all uri sets to their files...]" -ForegroundColor Cyan

# Output uri sets to files
output_uri_sets $mapping_uri_sets_to_names $uri_sets_dir $uri_sets_file_extension

# Tell user we successfully wrote all uri sets to their files
Write-Host "`n> Successfully output all uri sets to their files." -ForegroundColor Green

# Tell user we are going to write curls commands for all uri sets 
Write-Host "`n`n[Writing curls for all uri sets to their files...]" -ForegroundColor Cyan

# Output curls uri sets to files
output_curls $mapping_uri_sets_to_names $curls_dir $OS_WinNT

# Tell user we successfully wrote curls commands for all uri sets
Write-Host "`n> Successfully wrote curls commands for all uri sets." -ForegroundColor Green

# 0 - Do not warm
# 1 - Warm all in a_href uri set (excluding previously scraped)
# 2 - Warm all uri sets
if ($mode_warm -eq 1) {
	# tell user we are going to warm only a_href uri set
	Write-Host "`n`n[Warming only a_href uri set ...] " -ForegroundColor Cyan

	Compare-Object $mapping_uri_sets_to_names.('a_href') $links | where {$_.sideindicator -eq "<="} | foreach {
        $uri = $_.InputObject

        # Tell user we're warming this uri
        Write-Host " Warming $uri"
       
        $res_code = 0
        Try {
            $res = ''
            $res = Invoke-WebRequest $uri -UseBasicParsing
            $res_code = $res.StatusCode
        }Catch {
            # Catch 50x exceptions
            $res_code = $_.Exception.Response.StatusCode.Value__

            # Write non-http errors
            if (!$res_code) { Write-Error $_.Exception.Message }
        } 
        if ($res_code -and $res_code -eq 200) { 
            Write-Host " Successfully warmed." 
        }else  {
            Write-Error " Could not reach and warm uri: $uri. Error code: $res_code"; 
        }
	}

    # Warm all a_hrefs that hasn't been scraped earlier
	Write-Host "Successfully warmed all a_href uris" -ForegroundColor Green
}elseif ($mode_warm -eq 2) {
    # Tell user we are going to warm all uri sets
    Write-Host "`n`n[Warming all uri sets ...] " -ForegroundColor Cyan
    
    $mapping_uri_sets_to_names.GetEnumerator() | % { 
        $uri_set_name = $_.Key
        $uri_set = $_.Value

        # Tell user we are going to warm this uri set
        Write-Host " Warming $uri_set_name uri set ... " -ForegroundColor Green
        
        foreach ($uri in $uri_set) {
            # Tell user we're warming this uri
            Write-Host "  Warming $uri"
           
            $res_code = 0
            Try {
                $res = ''
                $res = Invoke-WebRequest $uri -UseBasicParsing
                $res_code = $res.StatusCode
            }Catch {
                # Catch 50x exceptions
                $res_code = $_.Exception.Response.StatusCode.Value__

                # Write non-http errors
                if (!$res_code) { Write-Error $_.Exception.Message }
            } 
            if ($res_code -and $res_code -eq 200) { 
                Write-Host "  Successfully warmed." 
            }else  {
                Write-Error " Could not reach and warm uri: $uri. Error code: $res_code" 
            }
         }
    }
	Write-Host "`n> Successfully warmed all uri sets" -ForegroundColor Green
}else {}
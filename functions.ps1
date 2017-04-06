############### functions ###############

# builds a hashtable containing unique tag(key)-attribute(value) combinations
 # Param 1: Comma-delimited string of tag attribute combinations. E.g. 'a href, img src, img data-src, img srcset, img data-src, link href, script src'
 # Return:  Hashtable of format: [string]$tag => [array]$attributes. E.g. @{ 'a' = @('href');  'img' = @('src', 'data-src', 'srcset', 'data-srcset'); 'link' = @('href'); 'script' = @('src'); }
function get_desired_uri_sets ([string]$tag_attribute_combos_comma_delimited) {
    $desired_uri_sets = [ordered]@{} 
    foreach ($combo in $tag_attribute_combos_comma_delimited) {
        $split = $combo.split(',').split(' ').trim() | ? {$_} # split to array, by both , and space. exclude empty values. 
   
        for($i=0; $i -lt $split.count; $i++) {
            # skip over odd numbers
            if ($i % 2) { continue } 

            $tag  = $split[$i]
            $attr = $split[$i+1]

            # skip over invalid tags / attributes (may contain letters and dashes only)
            if ($tag -match [regex]"^[A-Za-z\-]+" -eq $false -or $tag -match [regex]"^[A-Za-z\-]+" -eq $false) { continue }

            if ($desired_uri_sets.Contains($tag) -eq $false) {
                # first tag of its kind found, add the combination
                $desired_uri_sets.Add($tag, [array]$attr) # e.g. 'a' => @('href'), e.g. 'img' => @('src')
            }
            else
            {
                # append more attributes for an existing tag
                $attrs = $desired_uri_sets.($tag) # retrieve the existing attributes
                if ($attrs.Contains($attr) -eq $false) {
                    $attrs += $attr    # add new attribute for this tag
                    $desired_uri_sets.($tag) = $attrs #e.g. 'img' => @('src', 'srcset')
                }
            }
        }
    }
    $desired_uri_sets
}

# checks if uri is valid.
function uri_is_valid ([string]$str) {
	# don't include uri's with hash sign
    [bool]$cond1 = $str -match '#' 
    if ( $cond1 ){
		return $false
	}

    # include uris of our domain
    $domain_regex = $domain.replace('.', '\.').replace('-', '\-')
    [bool]$cond2 = $str -match "^(?:https?:)?\/\/$domain_regex"  
    if ( $cond2 ) {
        return $true
    }

    $false
}

# manually parses html to get uris for a specific tag-attribute pairing.
 # Param 1: html string
 # Param 2: html tag e.g. img
 # Param 3: html tag's attribute e.g. src
 # Param 4: [System.Collections.ArrayList] arraylist to store uris ( Pass by reference. Powershell has issues with returning empty arrays / single-item arrays. Empty arrays returned as $NULL, and single-item arrays returned as [String]. See https://surroundingthecode.wordpress.com/2011/12/12/powershell-nulls-empty-arrays-single-element-arrays/ )
#
function get_uris ([string]$html_str, [string]$tag, [string]$attr, [System.Collections.ArrayList]$arraylist) {
    # split html by html tag opening char i.e. <
    $html_arr = $html_str.split('<')

    # for each line with tag of interest found, do
    $html_arr | where { $_ -match "^$tag"} | foreach { # e.g. <img 
        # capture attribute's value
        $attr_regex = $attr.replace('.', '\.').replace('-', '\-') 
        $regex = "\s$attr_regex=(?:`"([^`"]*)`"|'([^']*)')" # e.g. data\-src="(https://theohbrothers.com/)"
        $captures = [regex]::Match( $_, $regex ) 
        $attr_val = if ($captures.Groups[1].value -ne '') {$captures.Groups[1].value} else {$captures.Groups[2].value}
        if ($debug -band 4) { write-host "`n$_`nRegex:$regex`n Group 1 (double-quotes) found: $($captures.Groups[1].value -eq ''), Group 2 (single-quotes) found: $($captures.Groups[2].value -eq '') `n 1: $($captures.Groups[1].value)`n 2: $($captures.Groups[2].value)"; }

        # in the case of comma-delimited values e.g. <img srcset>, split values
        $attr_vals = $attr_val.Split(',') # for <img srcset="http://tob.com/1.jpg 150w, http://tob.com/2.jpg 250w, ..."
        
        # for each value, do
        $attr_vals | foreach {
            $uri_regex = "((?:https?:)?\/\/[^\s`'`"]+)"  # matches uris
            $captures = [regex]::Match( $_, $uri_regex)
            $val = $captures.Groups[0].Value

            # filter uris we want
            if (uri_is_valid ($val)) {
	            if (!$arraylist.Contains($val)) {
		            $arraylist.Add($val) | Out-Null
	            }
            }
        } 
    }
    #$arraylist 
}

# replaces protocol with our desired
 # Param 1: array or System.Collections.ArrayList
function replace_protocol ($array) {
	for($i=0; $i -lt $array.count; $i++) {
		$uri = $array[$i]
		$matches = [regex]::Match( $uri, '^((?:https?:)?\/\/)' ) # capture protocol part including the //
        if ($matches.success -eq $false) { continue }
		$uri_protocol = $matches.Groups[1].Value
		$array[$i] = $uri -replace $uri_protocol, $desired_protocol
	}
    $array
	<# using foreach from: http://stackoverflow.com/questions/34166023/powershell-modify-elements-of-array
	$array = $array | foreach {
		$matches = [regex]::Match( $_, '((?:https?:)?\/\/)' )
		$uri_protocol = $matches.Groups[1].Value
		$new_uri = $_ -replace $uri_protocol, 'http://'
		$_ = $new_uri
		$_
	}#>
}

# outputs uris to file
# Param 1: # hashtable of format: [string] uri_set_name => [System.Collections.ArrayList] uri_set
# Param 2: directory to write curl files 
function output_uri_sets ($hashtable, [string]$dir, [string]$uri_sets_file_extension) {
    # create directory to store uri sets, if not existing
    if ( !(Test-Path $uri_sets_dir) ) { New-Item -Path $dir -ItemType directory | Out-Null }

    $hashtable.GetEnumerator() | % { 
        $uri_set_name = $_.key
        $uri_set = $_.value
        $uri_set | Out-File "$dir/$uri_set_name.txt" -Encoding utf8
        Write-Host "> $($uri_set.count) uris in $dir/$uri_set_name$uri_sets_file_extension" -ForegroundColor Green
    } 
}

# ouyputs curls to a file
 # Param 1: # hashtable of format: [string] uri_set_name => [System.Collections.ArrayList] uri_set
 # Param 2: directory to write curl files 
 # Param 3: OS that curls will run on. 0: *nix; 1: WinNT
#
function output_curls ($hashtable, [string]$dir, [int]$OS) {
    # create directory to store curls, if not existing
    if ( !(Test-Path $dir) ) { New-Item -Path $dir -ItemType directory | Out-Null }
    $commentChar = if ($OS -eq 1) { "::" } else { "#" }
    $toNull = if ($OS -eq 1) { " >NUL" } else { " > /dev/null " }
    $extension = if ($OS -eq 1) { ".bat" } else { ".sh" }
    $hashtable.GetEnumerator() | % { 
        $curls = @("$commentChar $(Get-Date)", "$commentChar -k to ignore ssl cert")
        $uri_set_name = $_.key
        $uri_set = $_.value
        $curls = New-Object System.Collections.ArrayList
        foreach ($uri in $uri_set) {   
	        $curls.Add("curl -k -X GET $uri $toNull") | Out-Null
        }
        $curls | Out-File "$dir/$uri_set_name$extension" -Encoding utf8
        Write-Host "> $($uri_set.count) curls in $dir/$uri_set_name$extension" -ForegroundColor Green
    } 
}
#########################################

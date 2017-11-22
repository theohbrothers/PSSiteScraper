############### functions ###############
# Notes:
#  Powershell has issues with returning empty arrays / single-item arrays. Empty arrays returned as $NULL, and single-item arrays returned as [String]. 
#   See https://surroundingthecode.wordpress.com/2011/12/12/powershell-nulls-empty-arrays-single-element-arrays/ )
#  
#  

# builds a hashtable containing unique tag(key)-attribute(value) combinations
 # Param 1: Comma-delimited string of tag attribute combinations. E.g. 'a href, img src, img data-src, img srcset, img data-src, link href, script src'
 # Return:  Hashtable of format: [string]$tag => [array]$attributes. E.g. @{ 'a' = @('href');  'img' = @('src', 'data-src', 'srcset', 'data-srcset'); 'link' = @('href'); 'script' = @('src'); }
#
function get_desired_uri_sets ([string]$tag_attribute_combos_comma_delimited) {
    $desired_uri_sets = [ordered]@{} 
    foreach ($combo in $tag_attribute_combos_comma_delimited) {
        # Split to array, by both ',' and ' '. Exclude empty values. 
        $split = $combo.split(',').split(' ').trim() | ? {$_} 
   
        for($i=0; $i -lt $split.count; $i++) {
            # Skip over odd numbers
            if ($i % 2) { continue } 

            $tag  = $split[$i]
            $attr = $split[$i+1]

            # Skip over invalid tags / attributes (may contain letters and dashes only)
            if ($tag -match [regex]"^[A-Za-z\-]+" -eq $false -or $tag -match [regex]"^[A-Za-z\-]+" -eq $false) { continue }

            if ($desired_uri_sets.Contains($tag) -eq $false) {
                # First tag of its kind found, add the combination
                $desired_uri_sets.Add($tag, [array]$attr) # e.g. 'a' => @('href'), e.g. 'img' => @('src')
            }
            else
            {
                # Append more attributes for an existing tag
                $attrs = $desired_uri_sets.($tag) # Retrieve the existing attributes
                if ($attrs.Contains($attr) -eq $false) {
                    $attrs += $attr    # Add new attribute for this tag
                    $desired_uri_sets.($tag) = $attrs # E.g. 'img' => @('src', 'srcset')
                }
            }
        }
    }
    $desired_uri_sets
}

# Checks if uri is valid.
 # Param 1: string containing uri
 # Return:  bool of whether uri matched conditions
#
function uri_is_valid ([string]$uri) {
	# Don't include uri's with hash sign
    [bool]$cond1 = $uri -match '#' 
    if ( $cond1 ){
		return $false
	}

    # Include uris of our domain
    $domain_regex = [regex]::Escape($domain)
    [bool]$cond2 = $uri -match "^(?:https?:)?\/\/$domain_regex"  
    if ( $cond2 ) {
        return $true
    }

    $false
}

# Manually parses html to get uris for a specific tag-attribute pairing.
 # Param 1: string containing html 
 # Param 2: string of html tag e.g. img
 # Param 3: string of html tag's attribute e.g. src
 # Param 4: [System.Collections.ArrayList] arraylist to store uris ( Passed by reference. Powershell has issues with returning empty arrays. See notes at top of file. )
 # Return: -
#
function get_uris ([string]$html_str, [string]$tag, [string]$attr, [System.Collections.ArrayList]$arraylist) {
    # split html by html tag opening char i.e. <
    $html_arr = $html_str.split('<')

    # for each line with tag of interest found, do
    $html_arr | where { $_ -match "^$tag"} | foreach { # e.g. <img 
        # capture attribute's value
        $attr_regex = [regex]::Escape($attr)
        $regex = "\s$attr_regex=(?:`"([^`"]*)`"|'([^']*)')" # e.g. data\-src="(https://theohbrothers.com/)"
        $captures = [regex]::Match( $_, $regex ) 
        $attr_val = if ($captures.Groups[1].value -ne '') {$captures.Groups[1].value} else {$captures.Groups[2].value} # E.g. "https://theohbrothers.com"
        if ($debug -band 4) { Write-host "`n$_`nRegex:$regex`n Group 1 (double-quotes) found: $($captures.Groups[1].success), Group 2 (single-quotes) found: $($captures.Groups[2].success) `n 1: $($captures.Groups[1].value)`n 2: $($captures.Groups[2].value)"; }

        # in the case of comma-delimited values e.g. <img srcset>, split values
        $attr_vals = $attr_val.Split(',') # for <img srcset="http://tob.com/1.jpg 150w, http://tob.com/2.jpg 250w, ..."
        
        # for each value, do
        $attr_vals | foreach {
            $uri_regex = "(?:https?:)?\/\/[^\s`'`"]+"  # matches uris
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

# Replaces protocol with our desired
 # Param 1: array or System.Collections.ArrayList containing uris ( Passed by reference. Powershell has issues with returning empty arrays. See notes at top of file. )
 # Param 2: string containing desired protocol. E.g. 'https://'
 # Return: -
#
function replace_protocol ($array, $desired_protocol) {
	for ($i=0; $i -lt $array.count; $i++) {
		$uri = $array[$i]
		$matches = [regex]::Match( $uri, '^((?:https?:)?\/\/)' ) # capture protocol part including the //
        if ($matches.success -eq $false) { continue }
		$uri_protocol = $matches.Groups[1].Value
		$array[$i] = $uri -replace $uri_protocol, $desired_protocol
	}
    #$array
	<# using foreach from: http://stackoverflow.com/questions/34166023/powershell-modify-elements-of-array
	$array = $array | foreach {
		$matches = [regex]::Match( $_, '((?:https?:)?\/\/)' )
		$uri_protocol = $matches.Groups[1].Value
		$new_uri = $_ -replace $uri_protocol, 'http://'
		$_ = $new_uri
		$_
	}#>
}

# Outputs uris to file
 # Param 1: hashtable of format: [string] uri_set_name => [System.Collections.ArrayList] uri_set
 # Param 2: directory to write curl files 
 # Return: -
#
function output_uri_sets ($hashtable, [string]$dir, [string]$uri_sets_file_extension) {
    # create directory to store uri sets, if not existing
    if ( !(Test-Path $uri_sets_dir) ) { New-Item -Path $dir -ItemType directory | Out-Null }

    $hashtable.GetEnumerator() | ForEach-Object { 
        $uri_set_name = $_.key
        $uri_set = $_.value
        $uri_set | Out-File "$dir/$uri_set_name.txt" -Encoding utf8
        Write-Host "> $($uri_set.count) uris in $dir/$uri_set_name$uri_sets_file_extension" -ForegroundColor Green
    }
}

# Outputs curls to a file
 # Param 1: # hashtable of format: [string] uri_set_name => [System.Collections.ArrayList] uri_set
 # Param 2: directory to write curl files 
 # Param 3: OS that curls will run on. 0: *nix; 1: WinNT
 # Return: -
function output_curls ($hashtable, [string]$dir, [int]$OS) {
    # create directory to store curls, if not existing
    if ( !(Test-Path $dir) ) { New-Item -Path $dir -ItemType directory | Out-Null }
    $commentChar = if ($OS -eq 1) { "::" } else { "#" }
    $toNull = if ($OS -eq 1) { " >NUL" } else { " > /dev/null " }
    $extension = if ($OS -eq 1) { ".bat" } else { ".sh" }
    $hashtable.GetEnumerator() | ForEach-Object { 
        $curls = New-Object System.Collections.ArrayList
        $curls.AddRange( @("$commentChar $(Get-Date)", "$commentChar -k to ignore ssl cert") )
        $uri_set_name = $_.key
        $uri_set = $_.value
        foreach ($uri in $uri_set) {   
	        $curls.Add("curl -k -X GET $uri $toNull") | Out-Null
        }
        $curls | Out-File "$dir/$uri_set_name$extension" -Encoding utf8
        Write-Host "> $($uri_set.count) curls in $dir/$uri_set_name$extension" -ForegroundColor Green
    }
}
#########################################

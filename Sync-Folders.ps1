function sync-folders
{

Param(  [Parameter(ValueFromPipeline=$true, Mandatory=$true)][string]$src,
	[Parameter(ValueFromPipeline=$true, Mandatory=$true)][string]$dest
)

Begin {

#color-legend
$color = {
	""
	"------------"
	"Color Legend"
	"------------"
	"Creation/Copy/Touch"
	"--"
	write-host "darkgreen : new directory created." -foreground darkgreen
	write-host "darkcyan : new file copied." -foreground darkcyan 
	write-host "darkgray : file touched." -foreground darkgray
	"-"
	"Deletion/OverWrite"
	"--"
	write-host "magenta : folder deleted." -foreground magenta 
	write-host "darkred : file deleted." -foreground darkred 
	write-host "cyan : file overwritten." -foreground cyan 
	"--"
	""
	#read-host "Have a read on our color legend so you get familiar with the console output. Press any key when you're ready."
}

#for updating modtimes
function touch
{
param( [datetime]$d,[Parameter(ValueFromPipeline=$true, Mandatory=$true)][string]$file = "" )

if ($d) {
	if(Test-Path $file) {
		(Get-ItemProperty $file).LastWriteTime = $d
	} else {
		echo $null > $file
	}

}else {
	if(Test-Path $file) {
		(Get-ItemProperty $file).LastWriteTime = get-date
	} else {
		echo $null > $file
	}
}
}# touch

# Removing old files from destination
function remove-oldfiles 
{
foreach($item in $dest_items) {
$name = $item.Name
$compare_item = $item.Fullname -replace $regex_dest_path,$src
	if($compare_item -ne ""){
		if(!(test-path -literalPath $compare_item)){
			if(!$item.PSIsContainer){
				Write-Host "$name does not exist in source, cleaning up." -foreground darkred
				Remove-Item -literalPath $item.Fullname
			} else {
				if ($(get-childitem $item.FullName).Count -ne 0) { 
					write-warning "Folder is not empty, set to remind later then skipping."
					set-variable -name iwashere -value $true -scope global
				} else {
					write-host "folder: $item is empty - deleted: $($item.FullName)" -foreground magenta
					remove-item -literalpath $item.FullName
				}
			}
		}
	}
}
}#remove-oldfiles

#copy items
function copy-files
{
foreach($item in $src_items) {
$name = $item.Name
$compare_item = $item.Fullname -replace $regex_src_path,$dest
if($compare_item -ne "") {
	if(test-path -literalPath $compare_item) {
		if(!$item.PSIsContainer) {
			if( $item.LastWriteTime -gt (Get-Item -literalPath $compare_item).LastWriteTime ) {
				if ( $item.length -eq (get-item -literalpath $compare_item).length) {
					# if (mod-times -match "touch"){
					Write-Host "Source and Destination have the same size/length for file: $name -touch switch is ON- touch performed." -foreground darkgray
					touch $compare_item -d ($item.lastwritetime)
					<#} 
					elseif (mod-times -match "overwrite") {
					Write-Host "Source and Destination have the same size/length for file: $name -overwrite switch ON- overwriting." -foreground darkgray
					Copy-Item -literalPath $item.Fullname -destination $compare_item -force
					}
					elseif (mod-times -match "ignore"){
					Write-Host "Source and Destination have the same size/length for file: $name -ignore switch ON- ignoring." -foreground darkgray
					}
					else {"why am i here?"} #>
				} else {
					Write-Host "Source location has a newer version $name" -foreground cyan
					Copy-Item -literalPath $item.Fullname -destination $compare_item -force
				}
			}else {
				#Write-Host "Skipping $name" -foreground gray
			}
		}
	}else {
		if($item.PSIsContainer)	{
			Write-Host "Copying $name - I am actually creating a directory!" -foreground darkgreen;
			New-Item $compare_item -type Directory | out-Null
		}else {
			Write-Host "Copying new file $name" -foreground darkcyan
			Copy-Item -literalPath $item.Fullname -destination $compare_item -force
		}
	}
}
}
} #copy-files



} #begin

Process {

& $color;

	# Make sure destination exists
	if(!(test-path -literalPath $dest)) {
		Write-Host "Creating destination directory.`n" -foregroundcolor green
		New-Item $dest -type Directory -force | out-Null
	}

	$regex_src_path = $src -replace "\\","\\" -replace "\:","\:" -replace "\(","\(" -replace "\)", "\)"
	$regex_dest_path = $dest -replace "\\","\\" -replace "\:","\:" -replace "\(","\(" -replace "\)", "\)"

	"Building list of items ...";""
	$src_items = Get-ChildItem $src -Recurse
	$dest_items = Get-ChildItem $dest -Recurse


"Checking for new items to copy ...";
"";
copy-files

"";
"Checking destination for older files..."
"";
remove-oldfiles;

}#Process

End {
	if ($iwashere -eq $true) {
		Write-Host "Marker to re-check folders that might have gotten emptied got set." -foreground darkred;
		"Checking destination for old AND empty folders ..."
		
		$dest_items = Get-ChildItem $dest -Recurse -Directory
		remove-oldfiles;
		
		rv iwashere -scope global -erroraction 0;
	} else { }
} #End

}

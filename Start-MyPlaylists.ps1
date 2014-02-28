
begin
{
# Plays my playlists on wmplayer - i'll add being able to choose playlists later, atm it will play ALL pl's on the playlist folder generated when you create a pl from wmplayer
# timer thing whilst playing using timespan and stopwatch
# references I used for this project are below
## http://blogs.technet.com/b/jamesone/archive/2008/10/21/powershell-and-windows-media-player-part-1.aspx
## http://stackoverflow.com/questions/17924310/powershell-system-windows-media-mediaplayer-register-objectevent
## http://stackoverflow.com/questions/10941756/powershell-show-elapsed-time

Add-Type -AssemblyName PresentationCore
# for playing
$MediaPlayer = New-Object System.Windows.Media.MediaPlayer
# for getting info
$wmp = New-object  –COM WMPlayer.OCX

<#
	This will be playlist based only for now. JUST the playlist file too. *.wpl...
#>

Function Open-media($file) {

$Mediaplayer.Open($file); 
#$wmp.controls.play()

}

### functions specific for com wmplayer

Function get-Playlist   
{param ($Name)

 if ($Name -eq $null) {$wmp.currentPlayList}

 else                 {$list=$wmp.playlistCollection.getByName($Name)
                       0..($list.count - 1)|foreach {$list.item($_) } }

}

<#

Next came Set-Playlist – I wanted to be able to do:
Set-PlayList $listObject or 
set-playlist “random” or 
get-Playlist “random” | set-playlist so this became a filter

#>

filter Set-Playlist

{param ($Playlist)   
 if ($playlist -eq $null)                {$playList=$_}

 if ($playlist -is [string])             {$playlist=get-playlist $playList}  
 if ($Playlist -is [system.__ComObject]) {$WMP.currentPlaylist = $playlist}
}

# Of Course I wanted to see the tracks in a play list so that became the next function – again set up to take Piped input, or a name or an object

filter get-MediaInPlaylist  
{param ($Playlist) 

 if ($playlist -eq $null)    {$playList=$_}

 if ($playlist -is [string]) {$playlist=Get-Playlist $playList}

 if ($playlist -eq $null)    {$playList=$wmp.currentPlayList}

 0..($Playlist.count - 1) | foreach {$playlist.item($_) }

 $playlist=$null

}

function get-media 

{param ($Name, [Switch]$album, [Switch]$artist)

 if ($artist)    {$wmp.mediaCollection.getByAuthor($Name)| get-MediaInPlaylist }

 elseif ($album) {$wmp.mediaCollection.getByAlbum($Name) | get-MediaInPlaylist }

 else            {$wmp.mediaCollection.GetByName($name)  | get-MediaInPlaylist }  
}


filter Append-Media

{param ($item , $Playlist) 

 if ($Item -eq $null) {$Item=$_}

 if ($playlist -is [string]) {$playlist=get-playlist $playList}

 if ($playlist -eq $null) {$playList=$wmp.currentPlayList}

 $playList.appendItem($item)

 $item=$null
} 

# make sure I could start with an empty list so did Reset-Media.
Function reset-media {$wmp.currentPlaylist=$wmp.newPlaylist("Playlist","") }

Function Start-media {

$Mediaplayer.Play(); 
#$wmp.controls.play()

}

Function Stop-media {

$Mediaplayer.Stop();
$Mediaplayer.Close();
#$wmp.controls.stop()

} 

Function Pause-media {

$Mediaplayer.Pause();
#$wmp.controls.pause()

} 


<#
$Time = [System.Diagnostics.Stopwatch]::StartNew()
while ($true) {
$CurrentTime = $Time.Elapsed
write-host $([string]::Format("`rTime: {0:d2}:{1:d2}:{2:d2}",
    $CurrentTime.hours, 
    $CurrentTime.minutes, 
    $CurrentTime.seconds)) -nonewline
sleep 1
if ($Host.UI.RawUI.KeyAvailable -and ("q" -eq $Host.UI.RawUI.ReadKey("IncludeKeyUp,NoEcho").Character)) {
    Write-Host "Exiting now"
    stop-media;
    break;
} elseif ($Host.UI.RawUI.KeyAvailable -and ("q" -eq $Host.UI.RawUI.ReadKey("IncludeKeyUp,NoEcho").Character)) {
    write-host "Pausing"
    pause-media;
} else {}
#>

}

Process {

$mod_ui = {
	$UI = (Get-Host).UI.RawUI;
	
 $buffersize = $UI.BufferSize
 $buffersize.width = 40
 $buffersize.height = 20

 $winsize = $UI.windowsize
 $winsize.width = 40
 $winsize.height = 20

	$UI.windowsize = $winsize
	$UI.WindowTitle="MediaPlayer"
	$UI.buffersize = $buffersize;
}

$PlaylistFolder = 'X:\music\Playlists'
$Playlists = Get-ChildItem -path $PlaylistFolder -filter *.wpl -recurse

foreach($file in $Playlists){
     clear-host;
     & $mod_ui;
     write-host "Playlist Name: $($file.BaseName)" -fore darkcyan;
     $wpl = $file.FullName

     Open-Media -file $wpl
     $MediaPlayer.Volume = 1
     
     $WPLInfo = $(get-MediaInPlaylist -Playlist $(get-Playlist -Name $file.BaseName)) 
     $WPLInfo | foreach { `
	start-media
	$song = $_.Name; $dur = $_.DurationString;
	write-host "`n`nCurrently Playing: $song" -fore darkgreen
	$span = new-timespan -seconds $($_.duration)
	$sw = [Diagnostics.Stopwatch]::StartNew()
		while ($sw.elapsed -lt $span){
			$timenow = $sw.elapsed
			write-host $([string]::Format("`rSong Elapsed[$dur]: {0:d2}:{1:d2}:{2:d2}",
				$timenow.hours,
				$timenow.minutes,
				$timenow.seconds)) -nonewline -fore darkgreen
			start-sleep -s 1
		
			if ($Host.UI.RawUI.KeyAvailable -and ("q" -eq $Host.UI.RawUI.ReadKey("IncludeKeyUp,NoEcho").Character)) {
	    			Write-Host "`n`nExiting now"
    				stop-media;
    				break;
			}
		} stop-media; break;
	}

     stop-media;
}
}

end {
stop-media;
}

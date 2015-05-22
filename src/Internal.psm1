function WriteMessage
{
    [CmdletBinding()]
    Param
    (
        # The Type of message you'd like, its just a prefix to the message.
        [Parameter(Mandatory=$true,Position=0)]
        [string]
        $Type,

        # The message to display
        [Parameter(Mandatory=$true,Position=1)]
        [string]
        $Message,
        
        # Color of the message, it will default to the hosts' verbose color.
        [Parameter(Position=2)]
        
        $ForegroundColor = $host.PrivateData.VerboseForegroundColor,
        # Background color of the message, it will default to the hosts' verbose color.
        [Parameter(Position=3)] 
        $BackgroundColor = $host.PrivateData.VerboseBackgroundColor
    )


    if($ForegroundColor -isnot [ConsoleColor]){ $ForegroundColor = ConvertColor $ForegroundColor }
    if($BackgroundColor -isnot [ConsoleColor])
    {
        # if its a transparent color
        if($BackgroundColor -eq "#00FFFFFF") {$BackgroundColor = $host.PrivateData.ConsolePaneBackgroundColor}
        $BackgroundColor = ConvertColor $BackgroundColor
    }

    #todo check to see if the preference is on or off
    
    Write-Host "$($Type.ToUpper()): $Message" -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor 
}


function ConvertColor($color)
{
    if($color -is [string]){ $color = [System.Windows.Media.Color]$color }
    [int]$bright = if($color.R -gt 128 -bor $color.G -gt 128 -bor $color.B -gt 128){8}else{0}
    [int]$r = if($color.R -gt 64){4}else{0}
    [int]$g = if($color.G -gt 64){2}else{0}
    [int]$b = if($color.B -gt 64){1}else{0}
    [consolecolor]($bright -bor $r -bor $g -bor $b)
}
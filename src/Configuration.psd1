@{
    HideZero = $true
    Before = PSObject @{
        Object = "["
        Foreground = (RgbColor "White")
        Background = (RgbColor $null)
    }
    Branch = PSObject @{
        Object = [char]0x03BB
        Foreground = (RgbColor "Yellow")
        Background = (RgbColor $null)
    }
    AheadBy = PSObject @{
        Foreground = (RgbColor "Yellow")
        Background = (RgbColor $null)
        Object = [char]0x25B2
    }
    BehindBy = PSObject @{
        Foreground = (RgbColor "Yellow")
        Background = (RgbColor $null)
        Object = [char]0x25BC
    }
    Index = PSObject @{
        Foreground = (RgbColor "Green")
        Background = (RgbColor $null)
    }
    Separator = PSObject @{
        Background = (RgbColor "DarkGreen")
        Foreground = (RgbColor "White")
        Object = " | "
    }
    Working = PSObject @{
        Foreground = (RgbColor "Green")
        Background = (RgbColor $null)
    }
    BeforeChanges = PSObject @{
        Object = "["
        Foreground = (RgbColor "White")
        Background = (RgbColor $null)
    }
    AfterChanges = PSObject @{
        Object = "]:"
        Foreground = (RgbColor "White")
        Background = (RgbColor $null)
    }
    StagedChanges = PSObject @{
        Object = ""
        Foreground = (RgbColor "White")
        Background = (RgbColor $null)
    }
    UnStagedChanges = PSObject @{
        Object = ""
        Foreground = (RgbColor "White")
        Background = (RgbColor $null)
    }
    AfterNoChanges = PSObject @{
        Object = "]:"
        Foreground = (RgbColor "White")
        Background = (RgbColor $null)
    }
    NoStatus = PSObject @{
        Object = ":"
        Foreground = (RgbColor "White")
        Background = (RgbColor $null)
    }
}
@{
    HideZero = $true
    Before = PSObject @{
        Object = "["
        Foreground = "White"
        Background = "Black"
    }
    Branch = PSObject @{
        Object = [char]0x03BB
        Foreground = "Yellow"
        Background = "Black"
    }
    AheadBy = PSObject @{
        Foreground = "Yellow"
        Background = "Black"
        Object = [char]0x25B2
    }
    BehindBy = PSObject @{
        Foreground = "Yellow"
        Background = "Black"
        Object = [char]0x25BC
    }
    Index = PSObject @{
        Foreground = "Green"
        Background = "Black"
    }
    Separator = PSObject @{
        Background = "DarkGreen"
        Foreground = "White"
        Object = " | "
    }
    Working = PSObject @{
        Foreground = "Green"
        Background = "Black"
    }
    BeforeChanges = PSObject @{
        Object = "["
        Foreground = "White"
        Background = "Black"
    }
    AfterChanges = PSObject @{
        Object = "]:"
        Foreground = "White"
        Background = "Black"
    }
    StagedChanges = PSObject @{
        Object = ""
        Foreground = "White"
        Background = "Black"
    }
    UnStagedChanges = PSObject @{
        Object = ""
        Foreground = "White"
        Background = "Black"
    }
    AfterNoChanges = PSObject @{
        Object = "]:"
        Foreground = "White"
        Background = "Black"
    }
    NoStatus = PSObject @{
        Object = ":"
        Foreground = "White"
        Background = "Black"
    }
}
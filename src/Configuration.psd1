@{
    Before = PSObject @{
        Object = "["
        Foreground = ConsoleColor White
        Background = ConsoleColor Black
    }
    Branch = PSObject @{
        Object = [char]0x03BB
        Foreground = ConsoleColor Yellow
        Background = ConsoleColor Black
    }
    AheadBy = PSObject @{
        Foreground = ConsoleColor Yellow
        Background = ConsoleColor Black
    }
    BehindBy = PSObject @{
        Foreground = ConsoleColor Yellow
        Background = ConsoleColor Black
    }
    Index = PSObject @{
        Foreground = ConsoleColor Green
        Background = ConsoleColor Black
    }
    Separator = PSObject @{
        Background = ConsoleColor DarkGreen
        Foreground = ConsoleColor White
        Object = " | "
    }
    Working = PSObject @{
        Foreground = ConsoleColor Green
        Background = ConsoleColor Black
    }
    After = PSObject @{
        Object = "]"
        Foreground = ConsoleColor White
        Background = ConsoleColor Black
    }
    HideZero = $true
}
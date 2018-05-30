$Prefix = "v?"
$TagPattern = "$Prefix(?<version>\d+\.\d+\.\d+(?:\d+\.)?)"

function Get-Log {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]$Root = $Pwd
    )
    end {
        $Path = [LibGit2Sharp.Repository]::Discover((Convert-Path $Root))
        if (!$Path) {
            Write-Warning "The path is not in a git repository!"
            return
        }

        try {
            $repo = New-Object LibGit2Sharp.Repository $Path

            # # We have to transform the object to keep the data around after .Dispose()
            # $repo.Head |
            #     Select-Object $BranchProperties |
            #     ForEach-Object { $_.PSTypeNames.Insert(0,"PSGit.Branch"); $_ }

            $Log = $repo.Commits | Select-Object Id,
            @{name = "Branch"; expr = { $c = $_; $repo.Branches.Where{$c.Id -eq $_.Tip.Id} }},
            @{name = "Tags"; expr = { $c = $_; $repo.Tags.Where{$c.Id -eq $_.Target.Id} }},
            Parents, Author,
            @{name = "Date"; expr = { $_.Author.When}},
            @{name = "Message"; expr = { $_.MessageShort}} |
                ForEach-Object { $_.PSTypeNames.Insert(0, "PSGit.Commit"), $_ }

            #Write-Verbose "Scanning $($Log.Count) commits"
            #while($commit | Where { $_.Branch -eq $null }) {
                foreach ($commit in $Log) {
                    #Write-Verbose ""
                    Write-Verbose "Commit $($commit.Id) Branch: $($commit.Branch.FriendlyName)"
                    $commit.Parents = $Log.Where{$_.Id -in $commit.Parents.Id}
                    foreach ($parent in $commit.Parents) {
                        #Write-Verbose "Parent $($parent.Id) Branch: $($parent.Branch.FriendlyName)"
                        if (!$parent.Branch) {
                            Write-Verbose "Update $($parent.Id) Branch: $($commit.Branch)"
                            $parent.Branch = $commit.Branch
                        }
                        # foreach($parent in $Log.Where{$_.Id -eq $p.Id}) {
                        #     if($parent.Children) {
                        #         $parent.Children += $commit
                        #     } else {
                        #         $parent | Add-Member -MemberType NoteProperty -Name Children -Value @($commit)
                        #     }
                        # }
                    }
                }
            #}
            $global:log = $Log

            $Commits = @($Log)
            [Array]::Reverse($Commits)

            [Version]$Version = "1.0.0"
            #Write-Verbose "Initially, Version is $Version`n"
            foreach ($Commit in $Commits) {
                if ($Commit.Tags.FriendlyName -match $TagPattern) {
                    [Version]$Version = $Matches["Version"]
                    $CommitsSinceVersionSource = 0
                    $BranchesSinceVersionSource = 0
                    #Write-Verbose "After considering Tags, version is $Version"
                } else {
                    # Find the previously tagged build version
                    $CommitsSinceVersionSource = 0
                    $Parents = $Commit

                    #Write-Verbose "Commit $($Commit.Id) Branch $($Commit.Branch)"
                    do {
                        $Parents = @($Parents)[0].Parents
                        $CommitsSinceVersionSource += 1
                        #Write-Verbose "Parent $(@($Parents)[0].Id) tags ($(@($Parents)[0].Tags.FriendlyName))"
                    } while ($Parents -and ($Parents.Tags.FriendlyName -notmatch $TagPattern))

                    # We are always building the NEXT version
                    if (@($Parents)[0].Tags.FriendlyName -match $TagPattern) {
                        [Version]$Version = $Matches["Version"]
                        $Version = [Version]::new($Version.Major, $Version.Minor + 1, 0, $CommitsSinceVersionSource)
                        #Write-Verbose "After considering history, version is $Version"
                    }

                    switch -regex ($Commit.Branch.FriendlyName) {
                        "master" {
                            $BranchesSinceVersionSource += 1
                            $Version = [Version]::new($Version.Major, $Version.Minor, $BranchesSinceVersionSource)
                        }
                        "features?" {
                            #Write-Verbose "Feature branch! (if it's the first commit, increment the counter: parent $($Commit.Parents[0].Branch.FriendlyName))"
                            if ($Commit.Parents[0].Branch.FriendlyName -eq "master") {
                                $BranchesSinceVersionSource += 1
                                $Commit.Branch | Add-Member -MemberType NoteProperty -Name "Version" -Value $BranchesSinceVersionSource
                            }
                            $Version = [Version]::new($Version.Major, $Version.Minor, $Commit.Branch.Version, $CommitsSinceVersionSource)
                        }
                        "releases?" {
                            if ($Commit.Branch.FriendlyName -match "releases?/$Prefix(?<version>\d+\.\d+\.\d+(?:\d+\.)?)") {
                                [Version]$Version = $Matches["Version"]
                            }
                        }
                    }
                    #Write-Verbose "After incrementing, version is $Version`n"
                }

                $Commit | Add-Member -MemberType NoteProperty -Name Version -Value $Version
                $Commit | Add-Member -MemberType NoteProperty -Name CommitsSinceVersionSource -Value $CommitsSinceVersionSource
                $Commit | Add-Member -MemberType NoteProperty -Name BranchesSinceVersionSource -Value $BranchesSinceVersionSource
            }
            $Log
        } finally {
            if ($null -ne $repo) {
                $repo.Dispose()
            }
        }
    }
}

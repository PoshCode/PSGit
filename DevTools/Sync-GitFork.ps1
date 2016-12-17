function Sync-GitFork
{
[cmdletbinding()]
param(
$Upstream = "upstream"
)
    #make sure the upstream remote is there
    if( (git remote) -notcontains $Upstream)
    {
        #could probably add it where to get the url from tho? no hard coding
        Write-Error "cant find upstream remote named $Upstream" -ErrorAction Stop
    }

    # check to see if they need to commit first
    Write-Verbose "Checking repo status"
    if(git status --porcelain)
    {
        Write-Error "Changes have been made, you should commit first, or discard. (discard: git checkout -- . )"
    }
    Write-Verbose "Gathering repo data"
    $branches = git branch --list
    $active = $branches | ? {$_ -match "^\*"} | %{$_ -replace "^[\s\*]+",""}
    $branches = $branches | % {$_ -replace "^[\s\*]+",""}
    $upstreamBranches = git branch -a

    Write-Verbose "fetching remote"
    git fetch $Upstream

    foreach($branch in $branches)
    {
        #make sure its a branch that the upstream has
        if($upstreamBranches | ? {$_ -match "$Upstream/$branch"})
        {
            Write-Verbose "working on $branch"
            git checkout $branch -q
            # make sure there are no major conflicts
            if(git diff --name-only --diff-filter=U $Upstream/$branch)
            {
                Write-Warning "Skipping $branch, conflicts found, please resolve."
            }
            else
            {
                # all is good, merge it!
                git merge $Upstream/$branch
            }
        }
        else
        {
            Write-Verbose "skipping $branch, no remote found"
        }
    }
    Write-Verbose "Switching you back to $active"
    git checkout $active -q
}
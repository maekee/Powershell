#This is a really nice function written by Tome Tanasovski
#https://powertoe.wordpress.com/2012/05/03/foreach-parallel/

Function ForEach-Parallel {
    param(
        [Parameter(Mandatory=$true,position=0)]
        [System.Management.Automation.ScriptBlock] $ScriptBlock,
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [PSObject]$InputObject,
        [Parameter(Mandatory=$false)]
        [int]$MaxThreads=5
    )
    BEGIN {
        $iss = [system.management.automation.runspaces.initialsessionstate]::CreateDefault()
        $pool = [Runspacefactory]::CreateRunspacePool(1, $maxthreads, $iss, $host)
        $pool.open()
        $threads = @()
        $ScriptBlock = $ExecutionContext.InvokeCommand.NewScriptBlock("param(`$_)`r`n" + $Scriptblock.ToString())
    }
    PROCESS {
        $powershell = [powershell]::Create().addscript($scriptblock).addargument($InputObject)
        $powershell.runspacepool=$pool
        $threads+= @{
            instance = $powershell
            handle = $powershell.begininvoke()
        }
    }
    END {
        $notdone = $true
        while ($notdone) {
            $notdone = $false
            for ($i=0; $i -lt $threads.count; $i++) {
                $thread = $threads[$i]
                if ($thread) {
                    if ($thread.handle.iscompleted) {
                        $thread.instance.endinvoke($thread.handle)
                        $thread.instance.dispose()
                        $threads[$i] = $null
                    }
                    else {
                        $notdone = $true
                    }
                }
            }
        }
    }
}

#This loop should take 255 seconds:
Measure-Command { (0..50) | ForEach-Parallel -MaxThreads 10 { Start-Sleep -Seconds 5 } }

#It takes a 30 seconds, increasing that to 25 for me takes 15 seconds.
#Of course it all depends on how much resources your machine has.

#enjoy your new parallelism

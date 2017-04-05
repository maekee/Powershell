## On Windows, named pipes operate in a server-client model and can make use of the
## Windows Universal Naming Convention (UNC) for both local and remote connections.
## Named pipes on Windows use what is known as the Named Pipe File System (NPFS).
## The NPFS is a hidden partition which functions just like any other; files are written,
## read and deleted using the same mechanisms as a standard Windows file system.
## So named pipes are actually just files on a hard drive which persist until there are no
## remaining handles to the file, at which point the file is deleted by Windows.
## The named pipe directory is located at: \\<machine_address>\pipe\<pipe_name>

Function Start-NamedPipeListeningServer {
    [CmdletBinding()]
    param( [Parameter(Mandatory=$false)][string]$PipeName = 'LetsTalk' )

    $PipeServerStream = New-Object System.IO.Pipes.NamedPipeServerStream($PipeName, [System.IO.Pipes.PipeDirection]::InOut)
    Write-Verbose 'Waiting for connections...'
    $PipeServerStream.WaitForConnection()
    Write-Verbose 'Connection Successful'
 
    $MessagesRecieved = @()
    $StreamReader = New-Object System.IO.StreamReader($PipeServerStream)
    while( ($CurrentMessage = $StreamReader.ReadLine()) -ne 'exit' ){
        Write-Verbose "Recieved message $CurrentMessage"
        $MessagesRecieved += $CurrentMessage
    }
    
    $MessagesRecieved
    
    #Cleaning up the streamreader and PipeServerStream
    $StreamReader.Dispose()
    $PipeServerStream.Dispose()
}

Function Send-StringOverNamedPipe {
    param(
        [Parameter(Mandatory=$true,Position=0)][string]$PipeServer,
        [Parameter(Mandatory=$false)][string]$PipeName = 'LetsTalk',
        [Parameter(Mandatory=$true,Position=1)][string[]]$Messages
    )

    $PipeClientStream = New-Object System.IO.Pipes.NamedPipeClientStream(
        $PipeServer,
        $PipeName,
        [System.IO.Pipes.PipeDirection]::InOut,
        [System.IO.Pipes.PipeOptions]::None,
        [System.Security.Principal.TokenImpersonationLevel]::Impersonation
    )

    $PipeClientStream.Connect()

    $StreamWriter = New-Object System.IO.StreamWriter($PipeClientStream)
    Foreach ($message in $Messages){ $StreamWriter.WriteLine($message) }
    
    $StreamWriter.WriteLine('exit')

    #Cleaning up StreamWriter and PipeClientStream
    $StreamWriter.Dispose()
    $PipeClientStream.Dispose()
}

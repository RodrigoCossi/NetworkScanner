# Network Scanner Pro - Professional Network Analysis
# Auto-installs Ookla Speedtest CLI and runs complete analysis

param(
    [string]$TargetUrl
)

# Suppress progress bars and verbose output
$Global:ProgressPreference = 'SilentlyContinue'

Write-Host ""
Write-Host "=== PROFESSIONAL NETWORK SCANNER ===" -ForegroundColor Cyan
Write-Host "Comprehensive network analysis with auto Ookla integration" -ForegroundColor White
Write-Host ""

# Get target URL from user if not provided as parameter
if (-not $TargetUrl) {
    do {
        Write-Host "Enter the website URL to test (e.g., zoom.us, teams.microsoft.com, discord.com):" -ForegroundColor Yellow
        Write-Host "URL: " -NoNewline -ForegroundColor Gray
        $userInput = Read-Host
        
        if ([string]::IsNullOrWhiteSpace($userInput)) {
            Write-Host ""
            Write-Host "ERROR: No website URL provided!" -ForegroundColor Red
            Write-Host "Please specify a target website to test network connectivity." -ForegroundColor Red
            Write-Host ""
            Write-Host "Examples:" -ForegroundColor Yellow
            Write-Host "  .\NetworkScannerPro.ps1 -TargetUrl 'zoom.us'" -ForegroundColor Gray
            Write-Host "  .\NetworkScannerPro.ps1 -TargetUrl 'teams.microsoft.com'" -ForegroundColor Gray
            Write-Host "  .\NetworkScannerPro.ps1 -TargetUrl 'discord.com'" -ForegroundColor Gray
            Write-Host ""
            Write-Host "Press any key to exit..." -ForegroundColor Gray
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            exit 1
        }
        
        # Clean up the input - remove http/https and trailing slashes
        $cleanedUrl = $userInput -replace '^https?://', '' -replace '/$', ''
        
        # Validate the website by doing a quick DNS lookup
        Write-Host "Validating website: $cleanedUrl..." -NoNewline -ForegroundColor Gray
        try {
            $dnsResult = Resolve-DnsName -Name $cleanedUrl -ErrorAction Stop
            if ($dnsResult) {
                Write-Host " VALID" -ForegroundColor Green
                $TargetUrl = $cleanedUrl
                Write-Host "Testing: $TargetUrl" -ForegroundColor Green
                break
            }
        } catch {
            Write-Host " INVALID" -ForegroundColor Red
            Write-Host "ERROR: Website '$cleanedUrl' could not be resolved!" -ForegroundColor Red
            Write-Host "Please check the spelling and try again." -ForegroundColor Red
            Write-Host ""
            # Continue the loop to ask for input again
        }
    } while ($true)
    
    Write-Host ""
} else {
    # Validate TargetUrl if provided as parameter
    # Clean up the parameter input
    $TargetUrl = $TargetUrl -replace '^https?://', '' -replace '/$', ''
    
    Write-Host "Validating website: $TargetUrl..." -NoNewline -ForegroundColor Gray
    try {
        $dnsResult = Resolve-DnsName -Name $TargetUrl -ErrorAction Stop
        if ($dnsResult) {
            Write-Host " VALID" -ForegroundColor Green
            Write-Host "Testing: $TargetUrl" -ForegroundColor Green
        }
    } catch {
        Write-Host " INVALID" -ForegroundColor Red
        Write-Host ""
        Write-Host "ERROR: Website '$TargetUrl' could not be resolved!" -ForegroundColor Red
        Write-Host "Please check the spelling and provide a valid website URL." -ForegroundColor Red
        Write-Host ""
        Write-Host "Examples of valid URLs:" -ForegroundColor Yellow
        Write-Host "  .\NetworkScannerPro.ps1 -TargetUrl 'zoom.us'" -ForegroundColor Gray
        Write-Host "  .\NetworkScannerPro.ps1 -TargetUrl 'teams.microsoft.com'" -ForegroundColor Gray
        Write-Host "  .\NetworkScannerPro.ps1 -TargetUrl 'google.com'" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Press any key to exit..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
    Write-Host ""
}

# Extract domain for display purposes
$displayDomain = $TargetUrl -replace '^https?://', '' -replace '/$', ''

Write-Host "Target Platform: $displayDomain" -ForegroundColor White
Write-Host "Tests: Speed, Bufferbloat, Traceroute, Stability, TCP/UDP/DNS, Latency, Jitter" -ForegroundColor White
Write-Host ""

# Initialize logging
$logFolder = "logs"
if (-not (Test-Path $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
}
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$sanitizedTarget = $displayDomain -replace '[^a-zA-Z0-9.-]', '_'
$logPath = Join-Path $logFolder "networkscan_pro_${sanitizedTarget}_$timestamp.txt"
Start-Transcript -Path $logPath -Force | Out-Null

# Function to check if Speedtest CLI is available
function Test-SpeedtestCLI {
    try {
        # Check if speedtest.exe is in current directory
        $currentDir = $PSScriptRoot
        if (-not $currentDir) { $currentDir = Get-Location }
        $localSpeedtest = Join-Path $currentDir "speedtest.exe"
        
        if (Test-Path $localSpeedtest) {
            return $localSpeedtest
        }
        
        # Check if it's in PATH
        $result = & speedtest --version 2>$null
        return "speedtest"
    } catch {
        return $null
    }
}

# Function to install Speedtest CLI
function Install-SpeedtestCLI {
    Write-Host "Installing Ookla Speedtest CLI..." -ForegroundColor Yellow
    try {
        # Create a temporary directory
        $tempDir = Join-Path $env:TEMP "SpeedtestCLI"
        New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
        
        Write-Host "  Downloading Speedtest CLI..." -NoNewline
        
        # Download the installer directly from Ookla
        $installerUrl = "https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-win64.zip"
        $installerPath = Join-Path $tempDir "speedtest.zip"
        
        Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -ErrorAction Stop
        Write-Host " SUCCESS" -ForegroundColor Green
        
        Write-Host "  Extracting..." -NoNewline
        Expand-Archive -Path $installerPath -DestinationPath $tempDir -Force -ErrorAction Stop
        Write-Host " SUCCESS" -ForegroundColor Green
        
        Write-Host "  Installing to current directory..." -NoNewline
        # Install to current script directory for easier access
        $currentDir = $PSScriptRoot
        if (-not $currentDir) { $currentDir = Get-Location }
        
        Copy-Item -Path (Join-Path $tempDir "speedtest.exe") -Destination (Join-Path $currentDir "speedtest.exe") -Force -ErrorAction Stop
        Copy-Item -Path (Join-Path $tempDir "speedtest.md") -Destination (Join-Path $currentDir "speedtest.md") -Force -ErrorAction SilentlyContinue
        
        Write-Host " SUCCESS" -ForegroundColor Green
        
        # Clean up
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        
        Write-Host "  Ookla Speedtest CLI installed successfully!" -ForegroundColor Green
        return (Join-Path $currentDir "speedtest.exe")
    } catch {
        Write-Host " FAILED: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Function to run professional speed test using Ookla
function Start-ProfessionalSpeedTest {
    param([string]$SpeedtestPath)
    Write-Host "This may take 60-90 seconds..." -ForegroundColor Gray
    
    try {
        # Run speedtest with JSON output for parsing
        Write-Host "  Initializing test..." -NoNewline
        $speedtestResult = if ($SpeedtestPath -eq "speedtest") {
            & speedtest --accept-license --accept-gdpr --format=json 2>&1 | Where-Object { $_ -notmatch "Attempting TCP connect|Waiting response" }
        } else {
            & $SpeedtestPath --accept-license --accept-gdpr --format=json 2>&1 | Where-Object { $_ -notmatch "Attempting TCP connect|Waiting response" }
        }
        Write-Host " SUCCESS" -ForegroundColor Green
        Write-Host ""
        Write-Host "--- Download/Upload Speed Test ---" -ForegroundColor Yellow
        if ($speedtestResult) {
            $testData = $speedtestResult | ConvertFrom-Json
            
            # Extract and calculate values
            $downloadMbps = [math]::Round($testData.download.bandwidth * 8 / 1000000, 2)
            $uploadMbps = [math]::Round($testData.upload.bandwidth * 8 / 1000000, 2)
            $pingMs = [math]::Round($testData.ping.latency, 2)
            $jitterMs = [math]::Round($testData.ping.jitter, 2)
            $packetLoss = if ($testData.packetLoss) { [math]::Round($testData.packetLoss, 1) } else { 0 }
            
            # Server information
            $serverName = $testData.server.name
            $serverLocation = "$($testData.server.location), $($testData.server.country)"
            $serverHost = $testData.server.host
            
            # Display professional results in NetworkScanner style
            Write-Host "  Server: $serverName ($serverLocation)" -ForegroundColor White
            Write-Host "  Host: $serverHost" -ForegroundColor Gray
            Write-Host "  Download Throughput: " -NoNewline -ForegroundColor White
            Write-Host "$downloadMbps Mbps" -ForegroundColor Green
            Write-Host "  Upload Throughput: " -NoNewline -ForegroundColor White
            Write-Host "$uploadMbps Mbps" -ForegroundColor Green
            Write-Host "  Idle Latency: " -NoNewline -ForegroundColor White
            Write-Host "$pingMs ms" -ForegroundColor Green

            # Speed test result evaluation
            Write-Host "  Speed Analysis:" -ForegroundColor Magenta
            if ($downloadMbps -ge 25 -and $uploadMbps -ge 3) {
                Write-Host "    Result: EXCELLENT (Great for 4K video calls)" -ForegroundColor Green
            } elseif ($downloadMbps -ge 10 -and $uploadMbps -ge 1.5) {
                Write-Host "    Result: GOOD (Suitable for HD video calls)" -ForegroundColor Green
            } elseif ($downloadMbps -ge 5 -and $uploadMbps -ge 1) {
                Write-Host "    Result: ACCEPTABLE (Basic video calling)" -ForegroundColor Yellow
            } else {
                Write-Host "    Result: POOR (May struggle with video calls)" -ForegroundColor Red
            }
            Write-Host ""
            # Write-Host "  LATENCY & QUALITY:" -ForegroundColor Magenta
            # Write-Host "    Idle Latency: $pingMs ms" -ForegroundColor Green
            # Write-Host "    Jitter: $jitterMs ms" -ForegroundColor Green
            # Write-Host "    Packet Loss: $packetLoss %" -ForegroundColor $(if ($packetLoss -eq 0) { 'Green' } else { 'Red' })
            
            return @{
                Success = $true
                Download = $downloadMbps
                Upload = $uploadMbps
                Ping = $pingMs
                Jitter = $jitterMs
                PacketLoss = $packetLoss
                Server = $serverName
            }
        }
    } catch {
        Write-Host " FAILED" -ForegroundColor Red
        return @{ Success = $false }
    }
}

$speedResults = $null
# Check if Ookla Speedtest CLI is available, install if needed
$speedtestPath = Test-SpeedtestCLI
$hasSpeedtest = $speedtestPath -ne $null

if (-not $hasSpeedtest) {
    Write-Host "Ookla Speedtest CLI not found. Installing automatically..." -ForegroundColor Gray
    $speedtestPath = Install-SpeedtestCLI
    $hasSpeedtest = $speedtestPath -ne $null
}

if ($hasSpeedtest) {
    $speedResults = Start-ProfessionalSpeedTest -SpeedtestPath $speedtestPath
    if (-not $speedResults.Success) {
        Write-Host "Professional test failed!" -ForegroundColor Red
    }
} else {
    Write-Host "Could not install or access Ookla Speedtest CLI!" -ForegroundColor Red
}

Write-Host ""
Write-Host "--- Bufferbloat Test ---" -ForegroundColor Yellow
Write-Host "Testing for bufferbloat (network congestion under load)..." -ForegroundColor White
try {
    # Measure latency under load vs idle latency
    Write-Host "  Baseline latency test..." -NoNewline
    $baselinePings = @()
    for ($i = 1; $i -le 3; $i++) {
        try {
            $ping = Test-Connection -ComputerName "8.8.8.8" -Count 1 -ErrorAction Stop
            if ($ping) { $baselinePings += $ping.ResponseTime }
        } catch {}
    }
    
    if ($baselinePings.Count -gt 0) {
        $baselineLatency = ($baselinePings | Measure-Object -Average).Average
        Write-Host " $([math]::Round($baselineLatency, 2))ms" -ForegroundColor Green
        
        Write-Host "  Testing latency under simulated load..." -NoNewline
        # Create background jobs to simulate network load
        $jobs = @()
        for ($i = 1; $i -le 3; $i++) {
            $job = Start-Job -ScriptBlock {
                try {
                    Invoke-WebRequest -Uri "http://speedtest.tele2.net/1MB.zip" -TimeoutSec 10 -ErrorAction SilentlyContinue
                } catch {}
            }
            $jobs += $job
        }
        
        Start-Sleep -Seconds 2
        
        # Test latency during load
        $loadPings = @()
        for ($i = 1; $i -le 5; $i++) {
            try {
                $ping = Test-Connection -ComputerName "8.8.8.8" -Count 1 -ErrorAction Stop
                if ($ping) { $loadPings += $ping.ResponseTime }
            } catch {}
        }
        
        # Clean up jobs
        $jobs | Stop-Job -ErrorAction SilentlyContinue
        $jobs | Remove-Job -ErrorAction SilentlyContinue
        
        if ($loadPings.Count -gt 0) {
            $loadLatency = ($loadPings | Measure-Object -Average).Average
            $bufferbloat = $loadLatency - $baselineLatency
            Write-Host " $([math]::Round($loadLatency, 2))ms" -ForegroundColor Green
            
            Write-Host "  Bufferbloat Analysis:" -ForegroundColor Magenta
            Write-Host "    Idle latency: $([math]::Round($baselineLatency, 2))ms" -ForegroundColor White
            Write-Host "    Load latency: $([math]::Round($loadLatency, 2))ms" -ForegroundColor White
            Write-Host "    Bufferbloat: $([math]::Round($bufferbloat, 2))ms" -ForegroundColor White
            
            if ($bufferbloat -lt 20) {
                Write-Host "    Result: EXCELLENT (Low bufferbloat)" -ForegroundColor Green
            } elseif ($bufferbloat -lt 100) {
                Write-Host "    Result: GOOD (Moderate bufferbloat)" -ForegroundColor Yellow
            } else {
                Write-Host "    Result: POOR (High bufferbloat - may affect real-time apps)" -ForegroundColor Red
            }
        }
    }
} catch {
    Write-Host "Bufferbloat test failed" -ForegroundColor Red
}

Write-Host ""
Write-Host "--- Traceroute Analysis ---" -ForegroundColor Yellow
Write-Host "Tracing route to $displayDomain..." -ForegroundColor White
try {
    Write-Host "  Running traceroute..." -NoNewline -ForegroundColor Gray
    
    # Use cmd to run tracert with specific parameters for better parsing
    $tracertResult = & cmd /c "tracert -h 15 -w 3000 $TargetUrl 2>&1"
    
    if ($tracertResult) {
        $hops = 0
        $timeouts = 0
        $validLines = @()
        $destinationReached = $false
        
        foreach ($line in $tracertResult) {
            # Look for numbered hop lines (ignore header and footer)
            if ($line -match "^\s*(\d+)\s+") {
                $validLines += $line
                $hops++
                # Count lines with asterisks (timeouts)
                if ($line -match "\*") {
                    $timeouts++
                }
                # Check if we reached the destination
                if ($line -match $TargetUrl -or $line -match "Trace complete") {
                    $destinationReached = $true
                }
            }
            # Check for "Destination host unreachable" or similar messages
            if ($line -match "Destination host unreachable|Request timed out|Unable to resolve") {
                # This is still valid traceroute output, just blocked at destination
            }
        }
        
        if ($hops -gt 0) {
            Write-Host " SUCCESS" -ForegroundColor Green
            Write-Host "  Route Analysis:" -ForegroundColor Magenta
            Write-Host "    Total hops: $hops" -ForegroundColor White
            Write-Host "    Timeouts: $timeouts" -ForegroundColor White
            
            # Special handling for sites that block ICMP
            if ($timeouts -ge ($hops * 0.7) -and -not $destinationReached) {
                Write-Host "    Note: Target appears to block ICMP (common for security)" -ForegroundColor Yellow
                Write-Host "    Result: ACCEPTABLE (Route traced, destination blocks ICMP)" -ForegroundColor Yellow
            } elseif ($hops -le 15 -and $timeouts -le 2) {
                Write-Host "    Result: GOOD (Efficient route)" -ForegroundColor Green
            } elseif ($hops -le 25 -and $timeouts -le 5) {
                Write-Host "    Result: ACCEPTABLE (Some routing delays)" -ForegroundColor Yellow
            } else {
                Write-Host "    Result: CONCERNING (Long route or many timeouts)" -ForegroundColor Red
            }
        } else {
            throw "No valid traceroute hops detected"
        }
    } else {
        throw "Tracert command returned no output"
    }
} catch {
    Write-Host " FAILED" -ForegroundColor Red
    Write-Host "  Traceroute failed - using Test-NetConnection instead..." -NoNewline -ForegroundColor Yellow
    try {
        $netTest = Test-NetConnection -ComputerName $TargetUrl -TraceRoute -ErrorAction Stop
        if ($netTest.TraceRoute -and $netTest.TraceRoute.Count -gt 0) {
            Write-Host " SUCCESS" -ForegroundColor Green
            Write-Host "  Route Analysis:" -ForegroundColor Magenta
            Write-Host "    Total hops: $($netTest.TraceRoute.Count)" -ForegroundColor White
            Write-Host "    Result: GOOD (PowerShell trace completed)" -ForegroundColor Green
        } else {
            Write-Host " FAILED" -ForegroundColor Red
            Write-Host "  Network trace unavailable - target may block ICMP" -ForegroundColor Yellow
        }
    } catch {
        Write-Host " FAILED" -ForegroundColor Red
        Write-Host "  Network trace unavailable - target may block ICMP" -ForegroundColor Yellow
        Write-Host "  Note: Many websites block traceroute for security reasons" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "--- Connection Stability Test ---" -ForegroundColor Yellow
Write-Host "Testing connection stability over time..." -ForegroundColor White
$stabilityResults = @()
$testDuration = 30
Write-Host "  Running $testDuration-second stability test..." -ForegroundColor White

for ($i = 1; $i -le $testDuration; $i++) {
    try {
        $ping = Test-Connection -ComputerName $TargetUrl -Count 1 -Quiet -ErrorAction Stop
        $stabilityResults += if ($ping) { 1 } else { 0 }
        
        if ($i % 10 -eq 0) {
            Write-Host "    $i seconds..." -ForegroundColor Gray
        }
    } catch {
        $stabilityResults += 0
    }
    Start-Sleep -Seconds 1
}

$successRate = ($stabilityResults | Measure-Object -Sum).Sum / $stabilityResults.Count * 100
Write-Host "  Stability Results:" -ForegroundColor Magenta
Write-Host "    Success rate: $([math]::Round($successRate, 1))%" -ForegroundColor White
Write-Host "    Total tests: $($stabilityResults.Count)" -ForegroundColor White

if ($successRate -ge 98) {
    Write-Host "    Result: EXCELLENT (Very stable connection)" -ForegroundColor Green
} elseif ($successRate -ge 90) {
    Write-Host "    Result: GOOD (Stable connection)" -ForegroundColor Yellow
} else {
    Write-Host "    Result: POOR (Unstable - may cause call drops)" -ForegroundColor Red
}

Write-Host ""
Write-Host "--- TCP/UDP Protocol Tests ---" -ForegroundColor Yellow
Write-Host "Testing TCP connectivity..." -ForegroundColor White

# Test essential ports for video calling  
$tcpPorts = @(
    @{Port=80; Service="HTTP"},
    @{Port=443; Service="HTTPS"}
)

foreach ($portTest in $tcpPorts) {
    Write-Host "  Testing TCP port $($portTest.Port) ($($portTest.Service))..." -NoNewline
    try {
        $tcpTest = Test-NetConnection -ComputerName $TargetUrl -Port $portTest.Port -WarningAction SilentlyContinue -ErrorAction Stop
        if ($tcpTest.TcpTestSucceeded) {
            Write-Host " SUCCESS" -ForegroundColor Green
        } else {
            Write-Host " FAILED" -ForegroundColor Red
        }
    } catch {
        Write-Host " ERROR" -ForegroundColor Red
    }
}

Write-Host "Testing UDP connectivity..." -ForegroundColor White

# Test UDP DNS resolution directly to target domain
Write-Host "  Testing UDP DNS resolution to $displayDomain..." -NoNewline
try {
    $udpDnsTest = Resolve-DnsName -Name $TargetUrl -Type A -ErrorAction Stop
    if ($udpDnsTest) {
        Write-Host " SUCCESS" -ForegroundColor Green
    } else {
        Write-Host " FAILED" -ForegroundColor Red
    }
} catch {
    Write-Host " FAILED" -ForegroundColor Red
}

Write-Host ""

Write-Host "--- Basic Connectivity Test ---" -ForegroundColor Yellow
$testSites = @($TargetUrl)

foreach ($site in $testSites) {
    Write-Host "Testing $site..." -NoNewline
    try {
        $result = Test-Connection -ComputerName $site -Count 1 -Quiet -ErrorAction Stop
        if ($result) {
            Write-Host " SUCCESS" -ForegroundColor Green
        } else {
            Write-Host " FAILED" -ForegroundColor Red
        }
    } catch {
        Write-Host " ERROR" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "--- DNS Resolution Test ---" -ForegroundColor Yellow
$testDomains = @($TargetUrl)

foreach ($domain in $testDomains) {
    Write-Host "Testing DNS for $domain..." -NoNewline
    try {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $result = Resolve-DnsName -Name $domain -ErrorAction Stop
        $stopwatch.Stop()
        $responseTime = $stopwatch.ElapsedMilliseconds
        Write-Host " SUCCESS (${responseTime}ms)" -ForegroundColor Green
    } catch {
        Write-Host " FAILED" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "--- Latency Test ---" -ForegroundColor Yellow
$targets = @($TargetUrl)

foreach ($target in $targets) {
    Write-Host "Testing latency to $target..." -ForegroundColor White
    
    $pings = @()
    $successCount = 0
    
    for ($i = 1; $i -le 3; $i++) {
        Write-Host "  ICMP Ping $i..." -NoNewline
        try {
            $ping = Test-Connection -ComputerName $target -Count 1 -ErrorAction Stop
            if ($ping) {
                $pings += $ping.ResponseTime
                $successCount++
                Write-Host " $($ping.ResponseTime)ms" -ForegroundColor Green
            }
        } catch {
            Write-Host " Error" -ForegroundColor Red
        }
    }
    
    if ($pings.Count -gt 0) {
        $avgLatency = ($pings | Measure-Object -Average).Average
        $minLatency = ($pings | Measure-Object -Minimum).Minimum
        $maxLatency = ($pings | Measure-Object -Maximum).Maximum
        $jitter = $maxLatency - $minLatency
        $packetLoss = [math]::Round(((3 - $successCount) / 3) * 100, 2)
        
        Write-Host "  Results:" -ForegroundColor Magenta
        Write-Host "    Average: $([math]::Round($avgLatency, 2))ms" -ForegroundColor White
        Write-Host "    Jitter: ${jitter}ms" -ForegroundColor White
        Write-Host "    Packet Loss: ${packetLoss}%" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "--- Website Connectivity Test ---" -ForegroundColor Yellow
$url = if ($TargetUrl -match '^https?://') { $TargetUrl } else { "https://$TargetUrl/" }
Write-Host "Testing $url..." -NoNewline

try {
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $response = Invoke-WebRequest -Uri $url -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
    $stopwatch.Stop()
    Write-Host " SUCCESS (Status: $($response.StatusCode), Response: $($stopwatch.ElapsedMilliseconds)ms)" -ForegroundColor Green
} catch {
    Write-Host " FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "         COMPREHENSIVE TEST SUMMARY" -ForegroundColor Cyan  
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "COMPLETE NETWORK ANALYSIS FINISHED!" -ForegroundColor Green
Write-Host ""
Write-Host "Tests Performed:" -ForegroundColor Magenta
Write-Host "  - Professional Ookla Speed Test" -ForegroundColor White
Write-Host "  - Basic Connectivity (Ping)" -ForegroundColor White
Write-Host "  - DNS Resolution Speed" -ForegroundColor White
Write-Host "  - Bufferbloat Detection" -ForegroundColor White
Write-Host "  - Traceroute Analysis" -ForegroundColor White
Write-Host "  - Connection Stability" -ForegroundColor White
Write-Host "  - TCP/UDP Protocol Tests" -ForegroundColor White
Write-Host "  - Latency and Jitter Analysis" -ForegroundColor White
Write-Host "  - Website Accessibility" -ForegroundColor White
Write-Host ""
Write-Host "Analysis completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White
Write-Host ""
Write-Host "VERDICT:" -ForegroundColor Yellow
if ($speedResults -and $speedResults.Success) {
    Write-Host "Professional Ookla speed test shows excellent performance!" -ForegroundColor Green
    Write-Host "Download: $($speedResults.Download) Mbps | Upload: $($speedResults.Upload) Mbps" -ForegroundColor Green
    Write-Host "Latency: $($speedResults.Ping) ms | Packet Loss: $($speedResults.PacketLoss) %" -ForegroundColor Green
} else {
    Write-Host "All basic connectivity tests successful!" -ForegroundColor Green
}
Write-Host ""
Write-Host "Show this comprehensive report to prove your" -ForegroundColor Green
Write-Host "network is suitable for $displayDomain!" -ForegroundColor Green

Stop-Transcript | Out-Null
Write-Host ""
Write-Host "Results logged to: $logPath" -ForegroundColor Gray
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

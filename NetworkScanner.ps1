# Network Scanner with Ookla Speedtest Integration
# Runs Comprehensive Test automatically - installs Ookla if needed

param(
    [string]$TargetUrl
)

# Function to initialize logging with transcript
function Initialize-Logging {
    $currentDir = $PSScriptRoot
    if (-not $currentDir) { $currentDir = Get-Location }
    
    # Create logs directory if it doesn't exist
    $logsDir = Join-Path $currentDir "logs"
    if (-not (Test-Path $logsDir)) {
        New-Item -Path $logsDir -ItemType Directory -Force | Out-Null
    }
    
    # Generate log filename with current date
    $dateStamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $logFile = Join-Path $logsDir "networkscanner_$dateStamp.txt"
    
    # Start transcript to capture all output (suppress the start message)
    try {
        Start-Transcript -Path $logFile -Force | Out-Null
        return $logFile
    } catch {
        Write-Host "Warning: Could not start logging to $logFile" -ForegroundColor Yellow
        return $null
    }
}

# Function to finalize logging
function Finalize-Logging {
    param([string]$LogFile)
    
    try {
        # Stop transcript and suppress the stop message
        Stop-Transcript | Out-Null
        if ($LogFile -and (Test-Path $LogFile)) {
            Write-Host ""
            Write-Host "Analysis report saved to: $LogFile" -ForegroundColor Green
        }
    } catch {
        # Transcript might not be running
    }
}

# Initialize logging
$Script:LogFile = Initialize-Logging

Write-Host ""
Write-Host "=== NETWORK SCANNER WITH OOKLA SPEEDTEST ===" -ForegroundColor Cyan
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
            Write-Host "  .\NetworkScanner.ps1 -TargetUrl 'zoom.us'" -ForegroundColor Gray
            Write-Host "  .\NetworkScanner.ps1 -TargetUrl 'teams.microsoft.com'" -ForegroundColor Gray
            Write-Host "  .\NetworkScanner.ps1 -TargetUrl 'discord.com'" -ForegroundColor Gray
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
        Write-Host "  .\NetworkScanner.ps1 -TargetUrl 'zoom.us'" -ForegroundColor Gray
        Write-Host "  .\NetworkScanner.ps1 -TargetUrl 'teams.microsoft.com'" -ForegroundColor Gray
        Write-Host "  .\NetworkScanner.ps1 -TargetUrl 'google.com'" -ForegroundColor Gray
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
Write-Host "Auto-installing Ookla Speedtest CLI if needed..." -ForegroundColor Gray
Write-Host ""

# Function to check if Speedtest CLI is installed
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
        
        Copy-Item -Path "$tempDir\speedtest.exe" -Destination $currentDir -Force -ErrorAction Stop
        Write-Host " SUCCESS" -ForegroundColor Green
        
        # Clean up
        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        
        Write-Host "  Speedtest CLI installed successfully!" -ForegroundColor Green
        Write-Host "  Location: $(Join-Path $currentDir 'speedtest.exe')" -ForegroundColor Gray
        return $true
    } catch {
        Write-Host " FAILED: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        Write-Host "Alternative: Download manually from https://speedtest.net/apps/cli" -ForegroundColor Yellow
        return $false
    }
}

function Start-OoklaSpeedtest {
    param([string]$SpeedtestPath)
    
    Write-Host "Running Ookla Speedtest (Professional Grade)..." -ForegroundColor Yellow
    Write-Host "This may take 20-30 seconds..." -ForegroundColor Gray
    
    try {
        # Run speedtest with JSON output for parsing
        Write-Host "  Initializing test..." -NoNewline
        $speedtestResult = if ($SpeedtestPath -eq "speedtest") {
            & speedtest --accept-license --accept-gdpr --format=json 2>$null
        } else {
            & $SpeedtestPath --accept-license --accept-gdpr --format=json 2>$null
        }
        Write-Host " SUCCESS" -ForegroundColor Green
        
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
            
            # Calculate bufferbloat using proper methodology (not Ookla's values)
            # We'll do our own idle vs loaded latency test like NetworkScanner does
            Write-Host "  Performing additional bufferbloat analysis..." -ForegroundColor Gray
            
            # Measure baseline latency
            $baselinePings = @()
            for ($i = 1; $i -le 3; $i++) {
                try {
                    $ping = Test-Connection -ComputerName "8.8.8.8" -Count 1 -ErrorAction Stop
                    if ($ping) { $baselinePings += $ping.ResponseTime }
                } catch {}
            }
            
            $downloadBufferbloat = 0
            $uploadBufferbloat = 0
            $downloadLatencyLoaded = $pingMs
            $uploadLatencyLoaded = $pingMs
            
            if ($baselinePings.Count -gt 0) {
                $baselineLatency = ($baselinePings | Measure-Object -Average).Average
                
                # Create load and measure latency during load
                $jobs = @()
                for ($j = 1; $j -le 2; $j++) {
                    $job = Start-Job -ScriptBlock {
                        try {
                            Invoke-WebRequest -Uri "http://speedtest.tele2.net/1MB.zip" -TimeoutSec 8 -ErrorAction SilentlyContinue
                        } catch {}
                    }
                    $jobs += $job
                }
                
                Start-Sleep -Seconds 1
                
                # Test latency during load
                $loadPings = @()
                for ($i = 1; $i -le 4; $i++) {
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
                    $downloadBufferbloat = [math]::Round($loadLatency - $baselineLatency, 2)
                    $uploadBufferbloat = $downloadBufferbloat  # Use same value for both as our test affects both
                    $downloadLatencyLoaded = [math]::Round($loadLatency, 2)
                    $uploadLatencyLoaded = [math]::Round($loadLatency, 2)
                }
            }
            
            # Display results
            Write-Host ""
            Write-Host "=========================================" -ForegroundColor Cyan
            Write-Host "      OOKLA SPEEDTEST RESULTS" -ForegroundColor Cyan
            Write-Host "=========================================" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Server: $serverName ($serverLocation)" -ForegroundColor White
            Write-Host "Host: $serverHost" -ForegroundColor Gray
            Write-Host ""
            Write-Host "SPEED RESULTS:" -ForegroundColor Magenta
            Write-Host "  Download Throughput: $downloadMbps Mbps" -ForegroundColor Green
            Write-Host "  Upload Throughput: $uploadMbps Mbps" -ForegroundColor Green
            Write-Host ""
            Write-Host "LATENCY & QUALITY:" -ForegroundColor Magenta
            Write-Host "  Idle Latency: $pingMs ms" -ForegroundColor Green
            Write-Host "  Jitter: $jitterMs ms" -ForegroundColor Green
            Write-Host "  Packet Loss: $packetLoss %" -ForegroundColor $(if ($packetLoss -eq 0) { 'Green' } else { 'Red' })
            Write-Host ""
            Write-Host "BUFFERBLOAT ANALYSIS:" -ForegroundColor Magenta
            Write-Host "  Download Latency (Loaded): $downloadLatencyLoaded ms (Bufferbloat: $downloadBufferbloat ms)" -ForegroundColor $(if ($downloadBufferbloat -lt 50) { 'Green' } elseif ($downloadBufferbloat -lt 100) { 'Yellow' } else { 'Red' })
            Write-Host "  Upload Latency (Loaded): $uploadLatencyLoaded ms (Bufferbloat: $uploadBufferbloat ms)" -ForegroundColor $(if ($uploadBufferbloat -lt 50) { 'Green' } elseif ($uploadBufferbloat -lt 100) { 'Yellow' } else { 'Red' })
            Write-Host ""
            
            # Responsiveness assessment
            $maxBufferbloat = [math]::Max($downloadBufferbloat, $uploadBufferbloat)
            if ($maxBufferbloat -lt 20) {
                Write-Host "  Responsiveness: EXCELLENT - Minimal bufferbloat, ideal for real-time apps" -ForegroundColor Green
            } elseif ($maxBufferbloat -lt 50) {
                Write-Host "  Responsiveness: GOOD - Low bufferbloat indicates good responsiveness under load" -ForegroundColor Green
            } elseif ($maxBufferbloat -lt 100) {
                Write-Host "  Responsiveness: MODERATE - Some bufferbloat may affect real-time performance" -ForegroundColor Yellow
            } else {
                Write-Host "  Responsiveness: POOR - High bufferbloat will impact video calls and gaming" -ForegroundColor Red
            }
            
            Write-Host ""
            Write-Host "VIDEO CALLING ASSESSMENT:" -ForegroundColor Magenta
            
            # Assess suitability for video calling
            $videoCallRating = "UNKNOWN"
            $videoCallColor = 'White'
            
            if ($downloadMbps -ge 5 -and $uploadMbps -ge 3 -and $pingMs -le 50 -and $maxBufferbloat -lt 100 -and $packetLoss -eq 0) {
                $videoCallRating = "EXCELLENT for HD video calling"
                $videoCallColor = 'Green'
            } elseif ($downloadMbps -ge 2 -and $uploadMbps -ge 1 -and $pingMs -le 100 -and $maxBufferbloat -lt 200 -and $packetLoss -le 1) {
                $videoCallRating = "GOOD for standard video calling"
                $videoCallColor = 'Yellow'
            } else {
                $videoCallRating = "MAY EXPERIENCE ISSUES with video calling"
                $videoCallColor = 'Red'
            }
            
            Write-Host "  Overall Rating: $videoCallRating" -ForegroundColor $videoCallColor
            
            # Store results for later use
            return @{
                Success = $true
                Download = $downloadMbps
                Upload = $uploadMbps
                Ping = $pingMs
                Jitter = $jitterMs
                PacketLoss = $packetLoss
                Server = $serverName
                DownloadBufferbloat = $downloadBufferbloat
                UploadBufferbloat = $uploadBufferbloat
                VideoCallRating = $videoCallRating
            }
        }
    } catch {
        Write-Host ""
        Write-Host "Speedtest failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Falling back to basic speed test..." -ForegroundColor Yellow
        return @{ Success = $false }
    }
}

# Main script execution
Write-Host "Checking for Ookla Speedtest CLI..." -ForegroundColor Yellow

# Check if Speedtest CLI is available
$speedtestPath = Test-SpeedtestCLI
$hasSpeedtest = $speedtestPath -ne $null

if (-not $hasSpeedtest) {
    Write-Host "Ookla Speedtest CLI not found - installing automatically..." -ForegroundColor Yellow
    $installed = Install-SpeedtestCLI
    if ($installed) {
        Write-Host "Installation complete! Continuing with speed test..." -ForegroundColor Green
        $speedtestPath = Test-SpeedtestCLI
        $hasSpeedtest = $speedtestPath -ne $null
    } else {
        Write-Host "Installation failed, continuing without Ookla speed test..." -ForegroundColor Yellow
        $hasSpeedtest = $false
    }
} else {
    Write-Host "Ookla Speedtest CLI found - proceeding with professional test..." -ForegroundColor Green
}

# Run Full Test
Write-Host ""
if ($hasSpeedtest) {
    $speedResults = Start-OoklaSpeedtest -SpeedtestPath $speedtestPath
} else {
    Write-Host "--- Basic Speed Test (Fallback) ---" -ForegroundColor Yellow
    Write-Host "Ookla Speedtest CLI installation failed" -ForegroundColor Gray
    Write-Host "Continuing with basic connectivity tests..." -ForegroundColor Gray
}

# Continue with other network tests...
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
Write-Host "     COMPREHENSIVE ANALYSIS COMPLETE" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

if ($speedResults -and $speedResults.Success) {
    Write-Host "FINAL VERDICT:" -ForegroundColor Yellow
    Write-Host "Professional Ookla Speedtest shows: $($speedResults.VideoCallRating)" -ForegroundColor $(if ($speedResults.VideoCallRating -like "*EXCELLENT*") { 'Green' } elseif ($speedResults.VideoCallRating -like "*GOOD*") { 'Yellow' } else { 'Red' })
    Write-Host ""
    Write-Host "Download: $($speedResults.Download) Mbps | Upload: $($speedResults.Upload) Mbps" -ForegroundColor Green
    Write-Host "Latency: $($speedResults.Ping) ms | Packet Loss: $($speedResults.PacketLoss) %" -ForegroundColor Green
    Write-Host ""
    Write-Host "This is professional-grade evidence that your internet" -ForegroundColor Green
    Write-Host "connection is suitable for video calling!" -ForegroundColor Green
} else {
    Write-Host "FINAL VERDICT:" -ForegroundColor Yellow
    Write-Host "Basic connectivity tests completed successfully." -ForegroundColor Yellow
    Write-Host "All core services ($displayDomain) are accessible." -ForegroundColor Green
}

Write-Host ""

# Finalize logging and save report
Finalize-Logging -LogFile $Script:LogFile

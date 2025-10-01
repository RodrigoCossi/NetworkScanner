# Quick Start Guide - Network Scanner

## For online teachers and professionals alike, who need to ensure a good internet connection to video call platforms.

### The Problem being solved
Helping online professionals suffering with bad internet connection, NetworkScanner and NetworkScannerPro help to troubleshoot internet problems with a simple double click. The two scanners available in this repository run industry standard tests to check the connection to the ISP (Internet Service Provider) and to the online/streaming platform. Assessing the quality, speed and stability of their connection. The scanners generate reports after every execution, helping IT teams diagnose deeper network issues and helping solve disputes. 

## 🚀 Quick Start

**Choose your tool:**
- **`RunNetworkScanner.bat`** - Speed test + basic connectivity
- **`RunNetworkScannerPro.bat`** - Everything above + 4 additional diagnostic tests

Just **double-click** and wait for results!


![alt text](<Screenshot 2025-10-01 194643.png>)
![alt text](<Screenshot 2025-10-01 220706.png>)


## 📋 Automatic Logging

**Every test automatically saves results to `logs/` folder:**
- Complete transcript of all tests
- Timestamped for easy reference  
- Professional format ready to share
- Evidence for IT support


## 🎯 Which Tool Should You Use?

### For Daily Use: NetworkScanner 
- Faster, simpler. Only the essential tests. Ideal for most cases. 

### For Problem Solving: NetworkScannerPro
- Slower but performs additional tests for detailed troubleshooting.


## 🧪 What Gets Tested

### All Versions Test:
- **Professional Speed**: Industry-standard Ookla measurements
- **Connection Quality**: Latency, jitter, packet loss
- **Bufferbloat Detection**: Network congestion under load
- **Platform Access**: Direct connectivity testing

### Pro Version Also Tests:
- **Connection Stability**: 30-second consistency check
- **Protocol Testing**: HTTP/HTTPS port accessibility  
- **DNS Performance**: Domain resolution speed
- **Network Route**: Path analysis to servers (traceroute)
- **Latency & Jitter**: Detailed ping statistics analysis


## 📚 Detailed Test Explanations

### 1. Professional Ookla Speed Test
**What it does:** Downloads and uploads data to/from professional Ookla servers (same as speedtest.net) to measure your actual internet throughput.

**How it works:** 
- Downloads multiple data streams simultaneously to max out your connection
- Uploads data to measure outbound capacity
- Measures latency during idle periods
- Uses industry-standard methodology trusted by ISPs

**Why it matters:** 
- **Download speed** determines video quality you can receive (HD/4K)
- **Upload speed** determines video quality you can send to students
- **Minimum needed:** 5 Mbps down/1 Mbps up for basic calls, 25/3 for 4K

### 2. Basic Connectivity (Ping)
**What it does:** Sends small ICMP packets to the target website and measures if they come back.

**How it works:**
- Sends 1-3 ping packets to the destination
- Measures round-trip time
- Checks if any packets are lost

**Why it matters:**
- Verifies you can actually reach the platform
- Tests basic network routing
- If this fails, nothing else will work

### 3. DNS Resolution Speed
**What it does:** Tests how quickly your computer can convert website names (like "zoom.us") into IP addresses.

**How it works:**
- Times how long `Resolve-DnsName` takes
- Measures response in milliseconds
- Tests the specific platform you'll be using

**Why it matters:**
- Slow DNS = delayed connection to video calls
- DNS failures = unable to join meetings
- Should be under 200ms for good performance

### 4. Bufferbloat Detection
**What it does:** Tests if your internet connection gets "clogged up" when downloading/uploading, causing delays in real-time communication.

**How it works:**
- Measures baseline latency when network is idle
- Creates artificial load (downloads files)
- Measures latency again during load
- Calculates the difference (bufferbloat)

**Why it matters:**
- High bufferbloat = your video calls lag when others use internet
- Causes choppy audio/video during busy network periods
- Under 50ms = excellent, over 100ms = problematic

### 5. Traceroute Analysis
**What it does:** Maps the network path from your computer to the target website, showing each "hop" (router) along the way.

**How it works:**
- Sends packets with increasing TTL values
- Each router along the path responds when TTL expires
- Builds a map of the route

**Why it matters:**
- Too many hops = long, inefficient route
- Timeouts = network congestion or blocking
- Helps identify where connection problems occur

### 6. Connection Stability
**What it does:** Tests if your connection stays consistent over time by pinging continuously for 30 seconds.

**How it works:**
- Sends 1 ping per second for 30 seconds
- Counts successes vs failures
- Calculates success percentage

**Why it matters:**
- Unstable connections = calls drop randomly
- Network "flapping" causes interruptions
- 98%+ success rate needed for reliable calls

### 7. TCP/UDP Protocol Tests
**What it does:** Tests specific network protocols and ports that video calling applications use.

**How it works:**
- **TCP tests:** Tries to connect to HTTP (port 80) and HTTPS (port 443)
- **UDP tests:** Verifies DNS resolution works (UDP protocol)
- Checks if firewalls block essential protocols

**Why it matters:**
- Video calls need both TCP (for control) and UDP (for audio/video)
- Blocked ports = can't establish calls
- Corporate firewalls often block these

### 8. Latency and Jitter Analysis
**What it does:** Measures network delay consistency by sending multiple pings and analyzing the timing variations.

**How it works:**
- Sends 3 ping packets to target
- Measures round-trip time for each
- Calculates average, minimum, maximum, and jitter (variation)

**Why it matters:**
- **Latency:** How long it takes for your voice to reach students
- **Jitter:** Variation causes choppy audio/video
- Under 100ms latency + low jitter = smooth calls

### 9. Website Accessibility
**What it does:** Tests if you can actually load the target website's homepage over HTTPS.

**How it works:**
- Makes an HTTP request to `https://[website]/`
- Measures response time
- Checks for successful response (status code 200)

**Why it matters:**
- Final verification that the platform is reachable
- Tests the actual protocol video platforms use
- If this fails, the platform might be down or blocked

## 🔍 Interpreting Test Results

### When Tests Fail or Show Warnings:

**Traceroute Timeouts:** Many modern websites (Discord, Teams, etc.) block ICMP for security. This is normal and doesn't indicate network problems.

**Website Accessibility Fails:** Some enterprise platforms have strict access controls or may be temporarily down. Check if you can access the site normally in a browser.

**High Bufferbloat:** Consider upgrading router firmware, enabling QoS (Quality of Service), or contacting your ISP about traffic shaping.

**DNS Slow Response:** Try changing DNS servers to 8.8.8.8 (Google) or 1.1.1.1 (Cloudflare) in your network settings.

**Connection Instability:** May indicate WiFi interference, overloaded router, or ISP issues. Try ethernet connection for testing.





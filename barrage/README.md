# Barrage

A fast, concurrent directory and file enumeration tool written in Elixir. Barrage leverages Elixir's lightweight processes and fault-tolerance to perform efficient web content discovery through brute-force techniques.

## Features

- **High Concurrency**: Leverages Elixir's actor model for thousands of concurrent requests
- **Fault Tolerance**: Failed requests don't crash the scan
- **Flexible Wordlists**: Support for custom wordlist files
- **File Extension Fuzzing**: Automatically test multiple file extensions
- **Status Code Filtering**: Focus on interesting HTTP responses
- **Color-coded Output**: Easy-to-read results with status code highlighting
- **Progress Tracking**: Real-time scan progress and statistics

## Installation & Building

1. Clone the repository:
```bash
git clone <repository-url>
cd barrage
```

2. Install dependencies:
```bash
mix deps.get
```

3. Build the executable:
```bash
mix escript.build
```

4. Run the tool:
```bash
./barrage <target-url>
```

## Usage

### Basic Usage

```bash
# Basic directory enumeration
./barrage http://example.com

# Scan with custom wordlist
./barrage -w /path/to/wordlist.txt http://example.com

# High-speed scan with more threads
./barrage -t 50 http://example.com
```

### Advanced Examples

```bash
# Scan for PHP and HTML files
./barrage -x php,html,txt http://example.com

# Verbose output showing all requests
./barrage -v http://example.com

# Quiet mode (no banner or progress)
./barrage -q http://example.com

# Custom status codes to display
./barrage -s 200,301,302,403 http://example.com

# Custom timeout and User-Agent
./barrage --timeout 15 -a "MyScanner/1.0" http://example.com

# Comprehensive scan
./barrage -w wordlists/big.txt -t 30 -x php,html,txt,js,css -v http://example.com
```

### Command Line Options

```
USAGE:
    barrage [OPTIONS] URL

ARGS:
    URL        Target URL (e.g., http://example.com)

FLAGS:
    -v, --verbose        Enable verbose output
    -q, --quiet          Suppress banner and errors
    --help               Show help message
    --version            Show version

OPTIONS:
    -w, --wordlist       Path to wordlist file (default: wordlists/common.txt)
    -t, --threads        Number of concurrent threads (default: 10)
    -x, --extensions     File extensions to search for (comma separated)
    -s, --status-codes   HTTP status codes to display (default: 200,204,301,302,307,401,403)
    --timeout            HTTP timeout in seconds (default: 10)
    -a, --user-agent     Custom User-Agent string (default: Barrage/0.1.0)
```

## Sample Output

```
=====================================================
Barrage v0.1.0
by Your Name
=====================================================

Target:     https://example.com/
Wordlist:   wordlists/common.txt
Threads:    10
Extensions: php, html
Requests:   72
Status codes: 200, 301, 302, 403

Starting scan...

200         1.2KB    https://example.com/admin/
301          312B    https://example.com/images/
403          4.5KB    https://example.com/config/
200         15KB     https://example.com/login.php

===============================================================
SCAN COMPLETE
===============================================================
Total requests: 72
Status 200: 2 responses
Status 301: 1 responses
Status 403: 1 responses
Status 404: 68 responses
===============================================================
```

## Creating Custom Wordlists

Create text files with one word per line:

```
admin
api
backup
config
dashboard
login
panel
upload
```

## Performance Tips

- **Start with fewer threads** (10-20) and increase based on target response
- **Use specific wordlists** for better results (admin panels, API endpoints, etc.)
- **Monitor target server** to avoid overwhelming it
- **Combine extensions** strategically based on target technology

## Why Elixir?

Barrage leverages Elixir's unique advantages for security tooling:

- **Massive Concurrency**: Handle thousands of HTTP requests simultaneously
- **Fault Tolerance**: Individual request failures don't affect the overall scan
- **Memory Efficiency**: Lightweight processes consume minimal resources
- **Built-in Supervision**: Automatic error recovery and process management

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request


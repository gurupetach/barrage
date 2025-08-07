# Barrage

An intelligent, high-performance directory and file enumeration tool written in Elixir. Barrage combines Elixir's legendary concurrency with smart technology detection and comprehensive security analysis to deliver professional-grade web content discovery.

## ✨ Key Features

### 🧠 **Intelligent Scanning**
- **Automatic Technology Detection**: Identifies frameworks (Phoenix, Laravel, WordPress, Django, React, Vue, Node.js)
- **Smart Wordlist Selection**: Dynamically loads technology-specific wordlists based on detection
- **Security Vulnerability Detection**: Finds exposed configs, backups, errors, and sensitive files
- **File Type Recognition**: Automatically categorizes discovered content

### ⚡ **High Performance**
- **Massive Concurrency**: Leverages Elixir's actor model for thousands of concurrent requests
- **Fault Tolerance**: Failed requests don't crash the scan thanks to OTP supervision
- **Memory Efficient**: Lightweight processes consume minimal resources
- **Configurable Threading**: Tune concurrency based on target capacity

### 🎯 **Smart Output**
- **Technology Tags**: `[Phoenix]` `[WordPress]` `[Laravel]` for discovered frameworks
- **Security Warnings**: `⚠ SQL Error` `⚠ Git Exposed` `⚠ ENV File` for vulnerabilities  
- **File Type Labels**: `[PHP]` `[JS]` `[JSON]` `[CFG]` for content classification
- **Color-coded Results**: Status codes, technologies, and warnings with distinct colors

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
# Intelligent scan with automatic technology detection (default)
./barrage https://example.com

# Manual wordlist with high concurrency
./barrage -w /path/to/wordlist.txt -t 50 https://example.com

# Target specific file types
./barrage -x php,html,js,json https://example.com
```

### 🧠 **Intelligent Scanning Examples**

```bash
# Auto-detect and scan WordPress site
./barrage https://wordpress-site.com
# Output: Detected technologies: WordPress
# Uses wordpress.txt wordlist automatically + common.txt

# Auto-detect and scan Laravel application  
./barrage https://laravel-app.com
# Output: Detected technologies: PHP/Laravel  
# Uses php-laravel.txt wordlist + common.txt

# Auto-detect Phoenix/Elixir application
./barrage https://phoenix-app.com  
# Output: Detected technologies: Elixir/Phoenix
# Uses elixir-phoenix.txt wordlist + common.txt

# Disable intelligent mode for faster basic scan
./barrage --intelligent false https://example.com
```

### 🚀 **Advanced Examples**

```bash
# Comprehensive security scan with verbose output
./barrage -v -t 30 -x php,html,txt,js,css,json,xml https://target.com

# Quiet mode for scripting (no banner, errors only)
./barrage -q -s 200,403 https://example.com

# Custom timeout and User-Agent for evasion
./barrage --timeout 15 -a "Mozilla/5.0 (Windows NT 10.0)" https://example.com

# Recursive directory scanning (experimental)
./barrage -r --max-depth 2 -t 20 https://example.com
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
    --intelligent        Enable intelligent scanning with technology detection (default: true)
    -r, --recursive      Enable recursive directory scanning (default: false)
    --max-depth          Maximum recursion depth for recursive scanning (default: 3)
```

## 📊 **Sample Output**

### Basic Scan
```
=====================================================
Barrage v0.1.0
by Peter Achieng
=====================================================

Detected technologies: WordPress, PHP/Laravel
Target:     https://example.com/
Wordlist:   wordlists/common.txt + wordpress.txt + php-laravel.txt  
Threads:    10
Extensions: 
Requests:   156
Status codes: 200, 301, 302, 403

Starting scan...

200      1.2KB    https://example.com/wp-admin/       [PHP] [WordPress] ⚠ Missing Headers
301       312B    https://example.com/wp-content/     [WordPress] 
403      4.5KB    https://example.com/.env            [CFG] ⚠ ENV File, Password
200     15.3KB    https://example.com/config.php      [PHP] [Laravel] ⚠ Config File
200      2.1KB    https://example.com/api/graphql     [JSON] [Laravel] 
500       845B    https://example.com/debug.php       [PHP] ⚠ PHP Error, Exception

===============================================================
SCAN COMPLETE
===============================================================
Total requests: 156
Status 200: 4 responses
Status 301: 1 responses  
Status 403: 1 responses
Status 500: 1 responses
Status 404: 149 responses
===============================================================
```

### Security-Focused Output
```bash
./barrage -v https://vulnerable-site.com

# Example findings:
200      1.5KB    /backup.sql                [DB] ⚠ Backup File, SQL Error
403       2KB     /.git/config              [CFG] ⚠ Git Exposed
200      850B     /phpinfo.php              [PHP] ⚠ PHP Error, Debug Info  
200      1.2KB    /.env                     [CFG] ⚠ ENV File, Secret, API Key
```

## 📁 **Technology-Specific Wordlists**

Barrage includes specialized wordlists for different technologies:

### **Built-in Wordlists**
- `elixir-phoenix.txt` - Phoenix LiveView, channels, OTP endpoints
- `wordpress.txt` - WP admin, plugins, themes, REST API  
- `php-laravel.txt` - Artisan, Eloquent, Blade, config files
- `django-python.txt` - Admin panel, migrations, static files
- `react-next.txt` - Next.js routing, API routes, SSG paths
- `vue-nuxt.txt` - Nuxt components, SSR, middleware
- `nodejs-express.txt` - NPM files, Express routes, middleware

### **Custom Wordlists**
Create text files with one word per line:
```
admin
api/v1  
api/v2
.env
backup
config
dashboard
```

## 🚀 **Performance & Security Tips**

### **Performance Optimization**
- **Start conservatively** (10-20 threads) and scale based on target response
- **Use intelligent scanning** to focus on relevant paths for detected technologies
- **Monitor target health** to avoid overwhelming servers
- **Combine strategic extensions** based on technology detection

### **Security Best Practices**  
- **Respect robots.txt** and rate limits during authorized testing
- **Use custom User-Agents** to avoid basic detection
- **Enable verbose mode** to capture maximum security findings
- **Analyze security warnings** for configuration issues and exposures

## 🏗️ **Why Elixir for Security Tools?**

Barrage leverages Elixir's unique advantages for professional security tooling:

### **Concurrency & Performance**
- **Actor Model**: Handle 100k+ concurrent HTTP requests efficiently  
- **Lightweight Processes**: Each request runs in isolated 2KB process
- **No Thread Limits**: Scale beyond traditional threading constraints

### **Reliability & Fault Tolerance**
- **OTP Supervision**: Individual request failures don't crash scans
- **Built-in Recovery**: Automatic restart of failed processes
- **Memory Safety**: No buffer overflows or memory leaks

### **Production Ready**
- **Battle Tested**: Powers high-traffic systems like Discord, Pinterest  
- **Hot Code Swapping**: Update scanning logic without stopping
- **Distributed Computing**: Scale across multiple machines seamlessly

## 🧪 **Testing & Quality**

Barrage includes comprehensive test coverage for reliability:

```bash
# Run all tests
mix test

# Run with coverage report  
mix test --cover

# Test specific modules
mix test test/barrage/technology_detector_test.exs
```

### **Test Coverage**
- **71 comprehensive tests** covering all major functionality
- **Technology detection tests** for framework identification
- **Security analysis tests** for vulnerability detection  
- **Output formatting tests** for intelligent display
- **HTTP client tests** for reliable networking
- **Wordlist processing tests** for file handling

## 📦 **Binary Distribution**

### **For End Users (No Elixir Required)**
Download the pre-built binary and run directly:

```bash
# Download from releases
curl -L -o barrage https://github.com/your-repo/releases/latest/download/barrage
chmod +x barrage

# Run immediately  
./barrage https://example.com
```

### **For Developers**
Build from source for development and customization:

```bash
git clone <repository-url>
cd barrage
mix deps.get
mix compile
mix escript.build
./barrage --help
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request


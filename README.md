# 🛡️ Terraform Security Analyzer

A comprehensive Docker-based security and best practices analyzer for Terraform infrastructure code. Use it across any GitHub repository without local building.

## 🚀 Quick Start

### 🎯 For Any Terraform Repository

1. **Copy one workflow file** to your Terraform repository:
   ```bash
   curl -o .github/workflows/terraform-security-analysis.yml \
     https://raw.githubusercontent.com/YOUR_USERNAME/terraform-security-analyzer/main/.github/workflows/use-published-analyzer.yml
   ```

2. **Update the image name** in the workflow:
   ```yaml
   env:
     DOCKER_IMAGE: ghcr.io/YOUR_USERNAME/terraform-security-analyzer:latest
   ```

3. **Commit and push** - Analysis runs automatically!

### 🐳 Published Docker Image

```bash
# Pull and run directly
docker pull ghcr.io/YOUR_USERNAME/terraform-security-analyzer:latest

# Analyze current directory
docker run --rm \
  -v "$(pwd):/workspace:ro" \
  -v "$(pwd)/output:/output" \
  ghcr.io/YOUR_USERNAME/terraform-security-analyzer:latest
```

## 🔧 Analysis Tools Included

| Tool | Purpose | Output |
|------|---------|--------|
| **Terraform** | Native validation and formatting | CLI + Report |
| **Checkov** | Security and compliance scanning | CLI + SARIF |
| **TFSec** | Security-focused static analysis | JSON + SARIF |
| **TFLint** | Terraform best practices | JSON |
| **Terrascan** | Multi-cloud security scanning | JSON |

## 📊 What You Get

### ✅ Automated Analysis
- **Security vulnerabilities** detection
- **Compliance** checking (CIS, NIST, SOC2)
- **Best practices** validation
- **Multi-cloud** support (AWS, Azure, GCP)

### 📋 Rich Reporting
- **Pull request comments** with analysis results
- **GitHub Security tab** integration via SARIF
- **Markdown reports** with executive summaries
- **JSON results** for programmatic processing

### 🔒 Security Integration
- **SARIF files** uploaded to GitHub Security
- **Vulnerability tracking** across commits
- **Compliance monitoring** over time

## 🎯 Configuration Options

### Analysis Types

| Type | Description | Tools Used |
|------|-------------|------------|
| `full` | Complete analysis (default) | All tools |
| `security-only` | Security focus | Checkov, TFSec, Terrascan |
| `best-practices-only` | Code quality focus | TFLint, Terraform validation |

### Environment Variables

```bash
ANALYSIS_TYPE=full              # full, security-only, best-practices-only
SKIP_ERRORS=true               # Continue on tool failures
WORKSPACE_DIR=/workspace       # Input directory
OUTPUT_DIR=/output            # Output directory
```

## 📁 Repository Structure

```
terraform-security-analyzer/
├── README.md                           # This file
├── README-reusable-analyzer.md        # Detailed usage guide
├── Dockerfile                         # Multi-tool analyzer image
├── .dockerignore                      # Docker build optimization
├── scripts/
│   └── analyze.sh                     # Main analysis script
└── .github/workflows/
    ├── build-and-publish-docker.yml   # Builds & publishes image
    └── use-published-analyzer.yml     # Template for other repos
```

## 🧪 Testing Locally

Test the analyzer on your own Terraform files:

```bash
# Build the image
docker build -t terraform-security-analyzer .

# Test on current directory (make sure it has .tf files)
docker run --rm \
  -v "$(pwd):/workspace:ro" \
  -v "$(pwd)/test-output:/output" \
  terraform-security-analyzer

# View results
cat test-output/analysis-report.md
```

## 🌟 Key Features

✅ **Zero local building** - Uses pre-built Docker image
✅ **Universal compatibility** - Works with any Terraform repository
✅ **Multi-platform support** - AMD64 + ARM64 runners
✅ **Enterprise ready** - Security attestations and compliance
✅ **Configurable analysis** - Choose security-only or full analysis
✅ **Rich reporting** - Markdown, SARIF, JSON outputs
✅ **CI/CD integrated** - GitHub Actions, PR comments, Security tab

## 📈 Usage Examples

### GitHub Actions Integration
```yaml
name: Terraform Security Analysis
on: [push, pull_request]

jobs:
  security-analysis:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Security Analysis
        run: |
          docker run --rm \
            -v "$PWD:/workspace:ro" \
            -v "$PWD/output:/output" \
            ghcr.io/YOUR_USERNAME/terraform-security-analyzer:latest
```

### Local Development
```bash
# Quick security check
docker run --rm \
  -v "$(pwd):/workspace:ro" \
  -v "$(pwd)/security-report:/output" \
  -e ANALYSIS_TYPE=security-only \
  ghcr.io/YOUR_USERNAME/terraform-security-analyzer:latest

# Full analysis with all tools
docker run --rm \
  -v "$(pwd):/workspace:ro" \
  -v "$(pwd)/full-report:/output" \
  -e ANALYSIS_TYPE=full \
  ghcr.io/YOUR_USERNAME/terraform-security-analyzer:latest
```

### CI/CD Pipeline Integration
```yaml
# Azure DevOps
- task: Docker@2
  inputs:
    command: 'run'
    arguments: '--rm -v $(System.DefaultWorkingDirectory):/workspace:ro -v $(System.DefaultWorkingDirectory)/output:/output ghcr.io/YOUR_USERNAME/terraform-security-analyzer:latest'

# GitLab CI
terraform-security:
  script:
    - docker run --rm -v "$PWD:/workspace:ro" -v "$PWD/output:/output" ghcr.io/YOUR_USERNAME/terraform-security-analyzer:latest
  artifacts:
    reports:
      sast: output/*.sarif
```

## 🔍 Sample Analysis Output

```markdown
# 🏗️ Terraform Infrastructure Analysis Report

## 📊 Final Assessment

### Issue Summary
| Priority | Count |
|----------|-------|
| 🚨 Critical | 2 |
| ⚠️ High | 5 |
| ⚡ Medium | 12 |
| ℹ️ Low | 8 |

## 🎯 Recommendations

### 🚨 Critical Actions Required
- Fix S3 bucket public access (2 instances)
- Enable encryption at rest for RDS databases

### ⚠️ High Priority
- Add network security groups to subnets
- Enable CloudTrail logging
```

## 🚀 Getting Started

1. **Fork this repository**
2. **Docker image auto-builds** at `ghcr.io/YOUR_USERNAME/terraform-security-analyzer:latest`
3. **Copy workflow to your Terraform repos**
4. **Enjoy automatic security analysis!**

## 📚 Documentation

- **[Detailed Usage Guide](README-reusable-analyzer.md)** - Complete setup instructions
- **[GitHub Releases](../../releases)** - Version history and changelogs

## 🤝 Contributing

1. Fork the repository
2. Add new security tools or improve existing ones
3. Update test fixtures with examples
4. Test thoroughly and submit a pull request

## 📄 License

MIT License - Use freely in commercial and open-source projects.

---

*Making Terraform security analysis simple, automated, and reusable across your entire organization.*
# Using Terraform Best Practices Analyzer in Your Repository

## 🚀 Quick Setup (2 minutes)

### Step 1: Add Secrets to Your Repository

Go to your repository **Settings → Secrets and variables → Actions** and add:

```
ANTHROPIC_API_KEY = your_claude_api_key
INFRACOST_API_KEY = your_infracost_api_key  (optional)
```

### Step 2: Copy the Workflow File

Copy this workflow file to `.github/workflows/terraform-analysis.yml` in your Terraform repository:

```bash
# From your Terraform repository root:
mkdir -p .github/workflows
curl -o .github/workflows/terraform-analysis.yml \
  https://raw.githubusercontent.com/vskuratovichdev/terraform-security-analyzer/main/.github/workflows/use-analyzer-template.yml
```

### Step 3: Commit and Push

```bash
git add .github/workflows/terraform-analysis.yml
git commit -m "Add Terraform best practices analysis"
git push
```

That's it! 🎉 Analysis will run automatically on:
- **Push** to main/master/develop branches
- **Pull Requests** to main/master/develop branches
- Only when Terraform files (`.tf`, `.tfvars`, `.hcl`) are changed

## 📊 What You Get

### Automatic Analysis
- **AI-powered best practices review** via Claude Code
- **Cost estimation and optimization** via Infracost
- **Code quality checks** via TFLint
- **Terraform validation** and formatting

### Rich Reporting
- **Pull Request comments** with detailed analysis
- **Downloadable reports** as workflow artifacts
- **Critical issue detection** (fails the build if found)

### Example Analysis Output
```markdown
## 🏗️ Terraform Best Practices Analysis

### 📊 Summary
- ✅ Code Quality: 85/100
- 💰 Estimated Monthly Cost: $124.50 (↓15% vs baseline)
- 🚨 Critical Issues: 0
- ⚠️ Recommendations: 3

### 🔍 Key Findings
1. **Cost Optimization**: Switch RDS instance from db.t3.large to db.t3.medium (saves $45/month)
2. **Best Practice**: Add resource tags for better governance
3. **Security**: Enable deletion protection on RDS instance
```

## 🔧 Configuration Options

### Environment Variables

You can customize the analysis by adding these to the workflow:

```yaml
- name: Run Analysis
  run: |
    docker run --rm \
      -v "$PWD:/workspace:ro" \
      -v "$PWD/analysis-output:/output" \
      -e ANTHROPIC_API_KEY="${{ secrets.ANTHROPIC_API_KEY }}" \
      -e INFRACOST_API_KEY="${{ secrets.INFRACOST_API_KEY }}" \
      -e ANALYSIS_TYPE="cost-only" \           # Options: full, cost-only, practices-only
      -e WORKSPACE_DIR="/workspace" \
      -e OUTPUT_DIR="/output" \
      ghcr.io/vskuratovichdev/terraform-best-practices-analyzer:latest
```

### Analysis Types

| Type | Description | Tools Used |
|------|-------------|------------|
| `full` | Complete analysis (default) | Claude Code + Infracost + TFLint + Terraform |
| `cost-only` | Cost analysis focus | Infracost + basic validation |
| `practices-only` | Best practices focus | Claude Code + TFLint + Terraform |

## 🏃‍♂️ Local Testing

Test the analyzer locally before committing:

```bash
# Set your API keys
export ANTHROPIC_API_KEY="your_key"
export INFRACOST_API_KEY="your_key"

# Run analysis on current directory
docker run --rm \
  -v "$PWD:/workspace:ro" \
  -v "$PWD/local-analysis:/output" \
  -e ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" \
  -e INFRACOST_API_KEY="$INFRACOST_API_KEY" \
  ghcr.io/vskuratovichdev/terraform-best-practices-analyzer:latest

# View results
cat local-analysis/analysis-report.md
```

## 🎯 Advanced Usage

### Multiple Terraform Directories

If your repository has multiple Terraform directories:

```yaml
strategy:
  matrix:
    terraform-dir: [infrastructure/aws, infrastructure/azure, modules/networking]

steps:
  - name: Run Analysis
    working-directory: ${{ matrix.terraform-dir }}
    run: |
      docker run --rm \
        -v "$PWD:/workspace:ro" \
        -v "$PWD/analysis-output:/output" \
        -e ANTHROPIC_API_KEY="${{ secrets.ANTHROPIC_API_KEY }}" \
        ghcr.io/vskuratovichdev/terraform-best-practices-analyzer:latest
```

### Custom Output Processing

```yaml
- name: Process Analysis Results
  run: |
    # Extract cost data
    jq '.monthly_cost' analysis-output/cost-analysis.json > cost.txt

    # Send to monitoring system
    curl -X POST "https://monitoring.example.com/metrics" \
      -d "terraform.cost=$(cat cost.txt)"
```

### Integration with Other Tools

```yaml
# Send Slack notification
- name: Slack Notification
  if: failure()
  uses: 8398a7/action-slack@v3
  with:
    status: failure
    text: "Terraform analysis found critical issues in ${{ github.repository }}"
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

## 🔒 Security Best Practices

1. **Store API keys as repository secrets** (never in code)
2. **Use branch protection rules** to require analysis before merging
3. **Review analysis reports** before approving pull requests
4. **Monitor costs regularly** using the cost analysis reports

## 🐛 Troubleshooting

### Common Issues

**"Analysis failed or no report generated"**
- Check that API keys are set correctly in repository secrets
- Verify the repository has `.tf` files in the analyzed paths
- Check workflow logs for detailed error messages

**"Docker pull failed"**
- The image is public, no authentication needed
- Try running the workflow again (temporary network issue)

**"Critical issues found"**
- Review the analysis report in PR comments or artifacts
- Fix the identified critical issues before merging
- Override by setting `FAIL_ON_CRITICAL=false` if needed

### Getting Help

1. Check the [workflow logs](../../actions) for detailed error messages
2. Review the [main repository](https://github.com/vskuratovichdev/terraform-security-analyzer) documentation
3. Open an issue in the analyzer repository for bugs or feature requests

---

## 📝 Example Repositories

See these example repositories using the analyzer:
- [Example AWS Infrastructure](https://github.com/example/aws-terraform)
- [Example Multi-Cloud Setup](https://github.com/example/multicloud-terraform)
- [Example Module Repository](https://github.com/example/terraform-modules)
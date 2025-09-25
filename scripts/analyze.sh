#!/bin/bash

set -e

WORKSPACE_DIR="/workspace"
OUTPUT_DIR="/output"
ANALYSIS_TYPE="${ANALYSIS_TYPE:-full}"
SKIP_ERRORS="${SKIP_ERRORS:-true}"

echo "🏗️ Terraform Best Practices & Cost Analyzer"
echo "================================================"
echo "Analysis Type: $ANALYSIS_TYPE"
echo "Skip Errors: $SKIP_ERRORS"
echo "Workspace: $WORKSPACE_DIR"
echo "Output: $OUTPUT_DIR"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Initialize counters
TOTAL_ISSUES=0
CRITICAL_ISSUES=0
HIGH_ISSUES=0
MEDIUM_ISSUES=0
LOW_ISSUES=0

# Function to handle errors
handle_error() {
    local exit_code=$1
    local tool_name=$2

    if [ $exit_code -ne 0 ] && [ "$SKIP_ERRORS" != "true" ]; then
        echo "❌ $tool_name failed with exit code $exit_code"
        exit $exit_code
    elif [ $exit_code -ne 0 ]; then
        echo "⚠️ $tool_name failed but continuing (skip_errors=true)"
    fi
}

# Change to workspace
cd "$WORKSPACE_DIR"

echo "📁 Analyzing workspace contents..."
find . -name "*.tf" -o -name "*.tfvars" | head -10
echo ""

# Start report
cat > "$OUTPUT_DIR/analysis-report.md" << 'EOF'
# 🏗️ Terraform Best Practices & Cost Analysis Report

## 📊 Executive Summary

This report presents the results of AI-powered best practices and cost analysis performed on your Terraform infrastructure code.

### 🔧 Analysis Tools Used
- **Terraform**: Native validation and formatting
- **Claude AI**: AI-powered best practices analysis using comprehensive Terraform guidelines
- **Infracost**: Cloud cost estimation and optimization recommendations
- **TFLint**: Terraform code quality and best practices validation

---

EOF

# 1. Terraform Validation
echo "🔍 Running Terraform validation..."
echo "## 🏗️ Terraform Validation" >> "$OUTPUT_DIR/analysis-report.md"
echo "" >> "$OUTPUT_DIR/analysis-report.md"

# Format check
echo "### Format Check" >> "$OUTPUT_DIR/analysis-report.md"
echo '```' >> "$OUTPUT_DIR/analysis-report.md"
if terraform fmt -check=true -diff=true -recursive . >> "$OUTPUT_DIR/analysis-report.md" 2>&1; then
    echo "✅ All files are properly formatted" >> "$OUTPUT_DIR/analysis-report.md"
else
    echo "⚠️ Formatting issues found - run 'terraform fmt -recursive' to fix" >> "$OUTPUT_DIR/analysis-report.md"
    MEDIUM_ISSUES=$((MEDIUM_ISSUES + 1))
fi
echo '```' >> "$OUTPUT_DIR/analysis-report.md"
echo "" >> "$OUTPUT_DIR/analysis-report.md"

# Validation
echo "### Syntax Validation" >> "$OUTPUT_DIR/analysis-report.md"
echo '```' >> "$OUTPUT_DIR/analysis-report.md"
terraform init -backend=false >> "$OUTPUT_DIR/analysis-report.md" 2>&1 || echo "Init failed - continuing without backend" >> "$OUTPUT_DIR/analysis-report.md"
if terraform validate >> "$OUTPUT_DIR/analysis-report.md" 2>&1; then
    echo "✅ Terraform configuration is valid" >> "$OUTPUT_DIR/analysis-report.md"
else
    echo "❌ Terraform validation failed" >> "$OUTPUT_DIR/analysis-report.md"
    HIGH_ISSUES=$((HIGH_ISSUES + 1))
fi
echo '```' >> "$OUTPUT_DIR/analysis-report.md"
echo "" >> "$OUTPUT_DIR/analysis-report.md"

# 2. Claude AI Best Practices Analysis
if [ "$ANALYSIS_TYPE" = "practices-only" ] || [ "$ANALYSIS_TYPE" = "full" ]; then
    echo "🤖 Running Claude AI best practices analysis..."
    echo "## 🤖 Claude AI Best Practices Analysis" >> "$OUTPUT_DIR/analysis-report.md"
    echo "" >> "$OUTPUT_DIR/analysis-report.md"

    if [ -n "$ANTHROPIC_API_KEY" ]; then
        # Create a prompt for Claude analysis
        cat > "$OUTPUT_DIR/claude-prompt.txt" << 'PROMPT_EOF'
Please analyze this Terraform code for best practices, security, and cost optimization opportunities.

Use the comprehensive analysis framework from the instruction file in ./claude/terraform-analysis-instruction.md

Focus on:
1. Code structure and organization
2. Security best practices
3. Cost optimization opportunities
4. Operational excellence
5. Compliance and governance

Provide specific, actionable recommendations with priorities (Critical, High, Medium, Low).
PROMPT_EOF

        # Run Claude analysis - simple approach using echo/pipe
        echo "$(cat $OUTPUT_DIR/claude-prompt.txt)" | claude > "$OUTPUT_DIR/claude-analysis.txt" 2>&1 || handle_error $? "Claude Analysis"

        if [ -f "$OUTPUT_DIR/claude-analysis.txt" ] && [ -s "$OUTPUT_DIR/claude-analysis.txt" ]; then
            echo "### AI-Powered Recommendations" >> "$OUTPUT_DIR/analysis-report.md"
            echo '```markdown' >> "$OUTPUT_DIR/analysis-report.md"
            cat "$OUTPUT_DIR/claude-analysis.txt" >> "$OUTPUT_DIR/analysis-report.md"
            echo '```' >> "$OUTPUT_DIR/analysis-report.md"

            # Count issues from Claude analysis (simple heuristic)
            CLAUDE_CRITICAL=$(grep -ci "critical\|severe\|urgent" "$OUTPUT_DIR/claude-analysis.txt" 2>/dev/null || echo "0")
            CLAUDE_HIGH=$(grep -ci "important\|should fix\|recommended" "$OUTPUT_DIR/claude-analysis.txt" 2>/dev/null || echo "0")

            CRITICAL_ISSUES=$((CRITICAL_ISSUES + CLAUDE_CRITICAL))
            HIGH_ISSUES=$((HIGH_ISSUES + CLAUDE_HIGH))
        else
            echo "⚠️ Claude analysis produced no output - check API key and connectivity" >> "$OUTPUT_DIR/analysis-report.md"
        fi
    else
        echo "⚠️ ANTHROPIC_API_KEY not provided - skipping Claude AI analysis" >> "$OUTPUT_DIR/analysis-report.md"
        echo "Set ANTHROPIC_API_KEY environment variable to enable AI-powered analysis" >> "$OUTPUT_DIR/analysis-report.md"
    fi
    echo "" >> "$OUTPUT_DIR/analysis-report.md"
fi

# 3. Infracost Analysis
if [ "$ANALYSIS_TYPE" = "cost-only" ] || [ "$ANALYSIS_TYPE" = "full" ]; then
    echo "💰 Running Infracost analysis..."
    echo "## 💰 Infracost Cost Analysis" >> "$OUTPUT_DIR/analysis-report.md"
    echo "" >> "$OUTPUT_DIR/analysis-report.md"

    if [ -n "$INFRACOST_API_KEY" ]; then
        # Initialize infracost and run analysis
        infracost configure set api_key "$INFRACOST_API_KEY" > /dev/null 2>&1 || true
        infracost breakdown --path . --format json > "$OUTPUT_DIR/infracost-results.json" 2>/dev/null || handle_error $? "Infracost"

        if [ -f "$OUTPUT_DIR/infracost-results.json" ]; then
            # Extract cost information
            MONTHLY_COST=$(jq -r '.totalMonthlyCost // "0"' "$OUTPUT_DIR/infracost-results.json" 2>/dev/null || echo "0")

            echo "### Cost Summary" >> "$OUTPUT_DIR/analysis-report.md"
            echo "- **Estimated Monthly Cost**: \$${MONTHLY_COST}" >> "$OUTPUT_DIR/analysis-report.md"
            echo "" >> "$OUTPUT_DIR/analysis-report.md"

            echo "### Detailed Breakdown" >> "$OUTPUT_DIR/analysis-report.md"
            echo '```json' >> "$OUTPUT_DIR/analysis-report.md"
            jq '.projects[0].breakdown.resources[] | {name: .name, monthlyCost: .monthlyCost, subresources: [.subresources[]? | {name: .name, monthlyCost: .monthlyCost}]}' "$OUTPUT_DIR/infracost-results.json" 2>/dev/null >> "$OUTPUT_DIR/analysis-report.md" || echo "Error parsing cost data" >> "$OUTPUT_DIR/analysis-report.md"
            echo '```' >> "$OUTPUT_DIR/analysis-report.md"

            # Flag high cost items as medium priority for review
            HIGH_COST_THRESHOLD=100
            if [ "${MONTHLY_COST%.*}" -gt "$HIGH_COST_THRESHOLD" 2>/dev/null ]; then
                MEDIUM_ISSUES=$((MEDIUM_ISSUES + 1))
                echo "⚠️ High monthly cost detected (\$${MONTHLY_COST}) - review for optimization opportunities" >> "$OUTPUT_DIR/analysis-report.md"
            fi
        fi
    else
        echo "⚠️ INFRACOST_API_KEY not provided - skipping cost analysis" >> "$OUTPUT_DIR/analysis-report.md"
        echo "Set INFRACOST_API_KEY environment variable to enable cost estimation" >> "$OUTPUT_DIR/analysis-report.md"
    fi
    echo "" >> "$OUTPUT_DIR/analysis-report.md"
fi

# 4. Basic Security Scanning for Secrets
echo "🔍 Running basic security scan for secrets..."
echo "## 🔍 Security Scan" >> "$OUTPUT_DIR/analysis-report.md"
echo "" >> "$OUTPUT_DIR/analysis-report.md"

# Simple secret detection patterns
SECRET_PATTERNS=(
    'password\s*=\s*"[^"]*"'
    'secret\s*=\s*"[^"]*"'
    'key\s*=\s*"[^"]*"'
    'token\s*=\s*"[^"]*"'
    'api_key\s*=\s*"[^"]*"'
    'access_key\s*=\s*"[^"]*"'
    'private_key\s*=\s*"[^"]*"'
)

SECRETS_FOUND=0
for pattern in "${SECRET_PATTERNS[@]}"; do
    if grep -r -i -E "$pattern" . --include="*.tf" --include="*.tfvars" > /dev/null 2>&1; then
        SECRETS_FOUND=$((SECRETS_FOUND + 1))
    fi
done

if [ $SECRETS_FOUND -gt 0 ]; then
    echo "### ⚠️ Potential Secrets Detected" >> "$OUTPUT_DIR/analysis-report.md"
    echo "Found $SECRETS_FOUND potential hardcoded secrets in Terraform files:" >> "$OUTPUT_DIR/analysis-report.md"
    echo '```' >> "$OUTPUT_DIR/analysis-report.md"

    for pattern in "${SECRET_PATTERNS[@]}"; do
        grep -r -i -E "$pattern" . --include="*.tf" --include="*.tfvars" | head -5 >> "$OUTPUT_DIR/analysis-report.md" 2>/dev/null || true
    done

    echo '```' >> "$OUTPUT_DIR/analysis-report.md"
    echo "" >> "$OUTPUT_DIR/analysis-report.md"
    echo "**Recommendations:**" >> "$OUTPUT_DIR/analysis-report.md"
    echo "- Use Terraform variables or data sources instead of hardcoded values" >> "$OUTPUT_DIR/analysis-report.md"
    echo "- Store secrets in Azure Key Vault or AWS Secrets Manager" >> "$OUTPUT_DIR/analysis-report.md"
    echo "- Use environment variables for sensitive data" >> "$OUTPUT_DIR/analysis-report.md"

    CRITICAL_ISSUES=$((CRITICAL_ISSUES + SECRETS_FOUND))
else
    echo "### ✅ No Hardcoded Secrets Found" >> "$OUTPUT_DIR/analysis-report.md"
    echo "No obvious hardcoded secrets detected in Terraform files." >> "$OUTPUT_DIR/analysis-report.md"
fi
echo "" >> "$OUTPUT_DIR/analysis-report.md"

# 5. TFLint Analysis
if [ "$ANALYSIS_TYPE" = "best-practices-only" ] || [ "$ANALYSIS_TYPE" = "full" ]; then
    echo "📋 Running TFLint best practices check..."
    echo "## 📋 TFLint Best Practices Analysis" >> "$OUTPUT_DIR/analysis-report.md"
    echo "" >> "$OUTPUT_DIR/analysis-report.md"

    tflint --format json > "$OUTPUT_DIR/tflint-results.json" 2>/dev/null || handle_error $? "TFLint"

    if [ -f "$OUTPUT_DIR/tflint-results.json" ]; then
        TFLINT_ISSUES=$(jq '.issues | length' "$OUTPUT_DIR/tflint-results.json" 2>/dev/null || echo "0")
        echo "### Summary" >> "$OUTPUT_DIR/analysis-report.md"
        echo "- **Issues Found**: $TFLINT_ISSUES" >> "$OUTPUT_DIR/analysis-report.md"
        echo "" >> "$OUTPUT_DIR/analysis-report.md"

        if [ "$TFLINT_ISSUES" -gt 0 ]; then
            echo "### Issues Found" >> "$OUTPUT_DIR/analysis-report.md"
            echo '```json' >> "$OUTPUT_DIR/analysis-report.md"
            jq '.issues[] | {severity: .rule.severity, rule: .rule.name, message: .message, filename: .range.filename}' "$OUTPUT_DIR/tflint-results.json" | head -30 >> "$OUTPUT_DIR/analysis-report.md" 2>/dev/null || echo "Error parsing TFLint results" >> "$OUTPUT_DIR/analysis-report.md"
            echo '```' >> "$OUTPUT_DIR/analysis-report.md"
        fi

        MEDIUM_ISSUES=$((MEDIUM_ISSUES + TFLINT_ISSUES))
    fi
    echo "" >> "$OUTPUT_DIR/analysis-report.md"
fi

# 5. Calculate Total Issues
TOTAL_ISSUES=$((CRITICAL_ISSUES + HIGH_ISSUES + MEDIUM_ISSUES + LOW_ISSUES))

# 6. Generate Final Summary
echo "## 📊 Final Assessment" >> "$OUTPUT_DIR/analysis-report.md"
echo "" >> "$OUTPUT_DIR/analysis-report.md"
echo "### Issue Summary" >> "$OUTPUT_DIR/analysis-report.md"
echo "| Priority | Count |" >> "$OUTPUT_DIR/analysis-report.md"
echo "|----------|-------|" >> "$OUTPUT_DIR/analysis-report.md"
echo "| 🚨 Critical | $CRITICAL_ISSUES |" >> "$OUTPUT_DIR/analysis-report.md"
echo "| ⚠️ High | $HIGH_ISSUES |" >> "$OUTPUT_DIR/analysis-report.md"
echo "| ⚡ Medium | $MEDIUM_ISSUES |" >> "$OUTPUT_DIR/analysis-report.md"
echo "| ℹ️ Low | $LOW_ISSUES |" >> "$OUTPUT_DIR/analysis-report.md"
echo "| **Total** | **$TOTAL_ISSUES** |" >> "$OUTPUT_DIR/analysis-report.md"
echo "" >> "$OUTPUT_DIR/analysis-report.md"

# 7. Recommendations
echo "## 🎯 Recommendations" >> "$OUTPUT_DIR/analysis-report.md"
echo "" >> "$OUTPUT_DIR/analysis-report.md"

if [ $CRITICAL_ISSUES -gt 0 ]; then
    echo "### 🚨 Critical Actions Required" >> "$OUTPUT_DIR/analysis-report.md"
    echo "- **Immediately** address $CRITICAL_ISSUES critical security issues" >> "$OUTPUT_DIR/analysis-report.md"
    echo "- Review and fix critical vulnerabilities before deployment" >> "$OUTPUT_DIR/analysis-report.md"
    echo "" >> "$OUTPUT_DIR/analysis-report.md"
fi

if [ $HIGH_ISSUES -gt 0 ]; then
    echo "### ⚠️ High Priority" >> "$OUTPUT_DIR/analysis-report.md"
    echo "- Address $HIGH_ISSUES high priority issues in the next sprint" >> "$OUTPUT_DIR/analysis-report.md"
    echo "- Focus on security and compliance violations" >> "$OUTPUT_DIR/analysis-report.md"
    echo "" >> "$OUTPUT_DIR/analysis-report.md"
fi

if [ $MEDIUM_ISSUES -gt 0 ]; then
    echo "### ⚡ Medium Priority" >> "$OUTPUT_DIR/analysis-report.md"
    echo "- Plan to resolve $MEDIUM_ISSUES medium priority issues" >> "$OUTPUT_DIR/analysis-report.md"
    echo "- Includes formatting and best practices improvements" >> "$OUTPUT_DIR/analysis-report.md"
    echo "" >> "$OUTPUT_DIR/analysis-report.md"
fi

echo "### 📋 General Recommendations" >> "$OUTPUT_DIR/analysis-report.md"
echo "1. **Enable pre-commit hooks** to catch issues early" >> "$OUTPUT_DIR/analysis-report.md"
echo "2. **Regular security scans** in CI/CD pipeline" >> "$OUTPUT_DIR/analysis-report.md"
echo "3. **Code review process** for all infrastructure changes" >> "$OUTPUT_DIR/analysis-report.md"
echo "4. **Keep tools updated** for latest security checks" >> "$OUTPUT_DIR/analysis-report.md"
echo "" >> "$OUTPUT_DIR/analysis-report.md"

echo "---" >> "$OUTPUT_DIR/analysis-report.md"
echo "*Analysis completed on $(date)*" >> "$OUTPUT_DIR/analysis-report.md"
echo "*Generated by Terraform Security Analyzer v1.0*" >> "$OUTPUT_DIR/analysis-report.md"

# Print summary to console
echo ""
echo "✅ Analysis completed!"
echo "📊 Summary: $TOTAL_ISSUES total issues ($CRITICAL_ISSUES critical, $HIGH_ISSUES high, $MEDIUM_ISSUES medium, $LOW_ISSUES low)"
echo "📄 Full report: $OUTPUT_DIR/analysis-report.md"
echo ""

# Set exit code based on findings (more lenient for best practices analyzer)
if [ $CRITICAL_ISSUES -gt 0 ]; then
    echo "❌ Critical issues found - immediate attention required"
    exit 2
elif [ $HIGH_ISSUES -gt 3 ]; then
    echo "⚠️ Multiple high priority recommendations - consider addressing before deployment"
    exit 1
else
    echo "✅ Analysis completed successfully"
    exit 0
fi
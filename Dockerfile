FROM ubuntu:22.04

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    unzip \
    git \
    python3 \
    python3-pip \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install Terraform
RUN TERRAFORM_VERSION=1.5.7 && \
    wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    mv terraform /usr/local/bin/ && \
    rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Install Checkov (security scanner)
RUN pip3 install checkov

# Install TFLint
RUN curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# Install TFSec
RUN curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash

# Install Terrascan
RUN curl -L "$(curl -s https://api.github.com/repos/tenable/terrascan/releases/latest | grep -o -E "https://.+?_Linux_x86_64.tar.gz")" > terrascan.tar.gz && \
    tar -xf terrascan.tar.gz terrascan && \
    mv terrascan /usr/local/bin && \
    rm terrascan.tar.gz

# Install Infracost (optional - for cost analysis)
RUN curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh

# Install Claude CLI
RUN curl -fsSL https://claude.ai/install.sh | sh || \
    (curl -L -o claude-cli.tar.gz "https://github.com/anthropics/claude-cli/releases/latest/download/claude-cli-linux-amd64.tar.gz" && \
     tar -xzf claude-cli.tar.gz && \
     mv claude /usr/local/bin/ && \
     rm claude-cli.tar.gz)

# Create analysis script directory
WORKDIR /terraform-validator

# Copy analysis scripts and instructions
COPY scripts/ ./scripts/
COPY templates/ ./templates/
COPY claude/ ./claude/

# Make scripts executable
RUN chmod +x scripts/*.sh

# Set environment variables for API keys (to be provided at runtime)
ENV ANTHROPIC_API_KEY=""
ENV INFRACOST_API_KEY=""

# Set entrypoint
ENTRYPOINT ["./scripts/analyze.sh"]
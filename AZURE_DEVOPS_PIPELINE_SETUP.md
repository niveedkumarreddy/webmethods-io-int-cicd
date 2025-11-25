# Azure DevOps Pipeline Setup Guide for webMethods.io Integration

This file documents how to set up Azure DevOps pipelines for the `webmethods-io-int-cicd` framework. It includes a focused section that shows how to install required CLI/tools on Microsoft-hosted agents (`ubuntu-latest`) and on Windows hosted agents (PowerShell), and a sample YAML snippet to add to pipelines.

## Where this file lives
- Repo root: `./AZURE_DEVOPS_PIPELINE_SETUP.md`
- Related docs: `webmethods_framework_phase-1.md` (contains a short summary and link)

---

## Install required CLI tools on hosted agents

Note: Microsoft-hosted agents (e.g. `ubuntu-latest`) are recommended. Hosted images are ephemeral; install any non-standard tooling at the start of the job.

The pipelines in this repository use these tools at runtime:
- `yq` (YAML query tool)
- `jq` (JSON processor)
- `curl` (HTTP client)
- `perl` (URI escaping used in scripts)
- `python3` + `pip` (some helper scripts)

Below are tested install snippets you can place at the top of your pipeline job before calling repository scripts.

### Bash (Linux, `ubuntu-latest`)

Add a step like this in your pipeline YAML (recommended):

```yaml
# Install prerequisites on ubuntu-latest
- task: Bash@3
  displayName: 'Install CLI tools'
  inputs:
    targetType: 'inline'
    script: |
      set -euo pipefail
      echo "Installing jq, curl, perl, yq and python3-pip"
      sudo apt-get update -y
      sudo apt-get install -y jq curl perl python3-pip

      # Install yq (mikefarah yq) - latest stable
      YQ_BIN=/usr/local/bin/yq
      if [ ! -f "$YQ_BIN" ]; then
        sudo wget -qO "$YQ_BIN" https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
        sudo chmod +x "$YQ_BIN"
      fi

      # Ensure pip is up to date and install python helpers
      python3 -m pip install --upgrade pip
      python3 -m pip install pynacl
```

This installs the minimum tools used by scripts such as `readEnvs.sh`, `exportAsset.sh`, and the GitHub helper scripts that use `encryptGithubSecret.py`.

### PowerShell (Windows hosted agents)

If you run on `windows-2022` or `windows-latest`, use this PowerShell snippet early in the job:

```yaml
- task: PowerShell@2
  displayName: 'Install CLI tools (Windows)'
  inputs:
    targetType: 'inline'
    script: |
      choco install -y jq curl perl python
      # Install yq (mikefarah yq) via scoop or download
      $yqPath = "$env:ProgramFiles\yq.exe"
      if (-not (Test-Path $yqPath)) {
        Invoke-WebRequest -UseBasicParsing -Uri "https://github.com/mikefarah/yq/releases/latest/download/yq_windows_amd64.exe" -OutFile $yqPath
      }
      python -m pip install --upgrade pip
      python -m pip install pynacl
```

Note: Windows hosted images already include many common tools; confirm availability and adjust the snippet to avoid reinstalling tools unnecessarily.

### Use a container image (alternative)

If you prefer, run jobs inside a container image that already contains required tools. Example job declaration:

```yaml
pool:
  vmImage: ubuntu-latest

container: mcr.microsoft.com/azure-cli

steps:
- script: |
    yq --version
    jq --version
  displayName: 'Verify tools in container'
```

Choose or build a container image that includes `yq`, `jq`, `curl`, `perl`, and Python so pipeline setup steps are minimal.

---

## Where to add these steps
- Add the install step as the first job/task in pipelines that call repo scripts (for example, `initialize_pipeline.yml`, `sychronizeFeatureBranch_pipeline.yml`, `synchronizeDEV_pipeline.yml`, `sychronizeToQA_pipeline.yml`, `initialize_runtime.yml`).
- If many pipelines share the same install logic, consider creating a pipeline template and `extends` that template from each pipeline.

## Quick example (inline insertion)

Insert the `Bash@3` step shown above immediately after the `checkout` steps in pipelines that use `yq`/`jq`.

---

## Notes and best practices
- Keep install steps idempotent (check for presence before downloading).
- Keep installs minimal — use a prepared container in CI for faster runs.
- Use `cache` tasks or pipeline caching if you must install larger artifacts frequently.

---

If you want, I can now:
- Insert the `Bash@3` snippet into the top of specific pipeline YAMLs (`initialize_pipeline.yml`, `sychronizeFeatureBranch_pipeline.yml`, `synchronizeDEV_pipeline.yml`, `sychronizeToQA_pipeline.yml`, `initialize_runtime.yml`), or
- Add a short 'Prerequisites' subsection into the existing `AZURE_DEVOPS_PIPELINE_SETUP.md` file summarizing these commands (already done here), or
- Create a reusable template YAML with the installers which pipelines can import.

Tell me which option you prefer and I'll patch the repo accordingly.
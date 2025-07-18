# Auto Sync and PR Script
# This script runs sync_files.py and creates a PR if there are changes
# Requires either -Run or -DryRun flag to run

param(
    [Alias("b")]
    [string]$BranchPrefix = "auto-sync",
    
    [Alias("c")]
    [string]$CommitMessage = "Auto-sync dotfiles",
    
    [Alias("dr")]
    [switch]$DryRun,
    
    [Alias("r")]
    [switch]$Run,
    
    [Alias("h")]
    [switch]$Help
)

# Function to show help
function Show-Help {
    Write-Host @"
Auto Sync and PR Script
=======================

This script runs sync_files.py and creates a PR if there are changes.
Requires either -Run or -DryRun flag to run.

Usage:
    .\auto_sync_and_pr.ps1 -Run [-BranchPrefix <prefix>] [-CommitMessage <message>]
    .\auto_sync_and_pr.ps1 -r [-b <prefix>] [-c <message>]
    Swap out "-Run/-r" with "-DryRun/-dr" to perform a dry run without making changes.

Parameters:
    -Run, -r            : Run the script and make actual changes
    -DryRun, -dr        : Show what would happen without making changes
    -BranchPrefix, -b   : Branch prefix for auto-generated branches (default: auto-sync)
    -CommitMessage, -c  : Commit message for changes (default: Auto-sync dotfiles)
    -Help, -h           : Show this help message

Examples:
    .\auto_sync_and_pr.ps1 -r ( run with actual changes and PR creation )
    .\auto_sync_and_pr.ps1 -dr ( dry run, no changes made but shows what would happen )
    .\auto_sync_and_pr.ps1 -r -b "config-update" -c "Updated configs" ( run with custom branch prefix and commit message )

These requirements will be installed if missing:
    - Python (default installs 3.12)
    - git
    - gh (GitHub CLI)
"@
}

# Function to check and install requirements
function Install-Requirements {
    Write-Log "Checking and installing requirements..."
    
    # Check Python
    try {
        $null = python --version
        Write-Log "Python is already installed"
    } catch {
        Write-Log "Python not found. Installing Python..." -Level "WARNING"
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget install Python.Python.3.12
        } elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            choco install python -y
        } elseif (Get-Command scoop -ErrorAction SilentlyContinue) {
            scoop install python
        } else {
            Write-Log "No package manager found. Please install Python manually from https://python.org" -Level "ERROR"
            throw "Python installation failed"
        }
    }
    
    # Check Git
    try {
        $null = git --version
        Write-Log "Git is already installed"
    } catch {
        Write-Log "Git not found. Installing Git..." -Level "WARNING"
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget install Git.Git
        } elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            choco install git -y
        } elseif (Get-Command scoop -ErrorAction SilentlyContinue) {
            scoop install git
        } else {
            Write-Log "No package manager found. Please install Git manually from https://git-scm.com" -Level "ERROR"
            throw "Git installation failed"
        }
    }
    
    # Check GitHub CLI
    try {
        $null = gh --version
        Write-Log "GitHub CLI is already installed"
    } catch {
        Write-Log "GitHub CLI not found. Installing GitHub CLI..." -Level "WARNING"
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget install GitHub.cli
        } elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            choco install gh -y
        } elseif (Get-Command scoop -ErrorAction SilentlyContinue) {
            scoop install gh
        } else {
            Write-Log "No package manager found. Please install GitHub CLI manually from https://cli.github.com" -Level "ERROR"
            throw "GitHub CLI installation failed"
        }
    }
    
    Write-Log "All requirements checked/installed"
}

# Function to log messages with timestamp
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message"
}

# Function to check for existing PR
function Get-ExistingPR {
    param([string]$BranchPrefix)
    
    try {
        # Check if GitHub CLI is authenticated
        if (-not (Test-GitHubAuth)) {
            Write-Log "GitHub CLI not authenticated. Cannot check for existing PRs." -Level "WARNING"
            return $null
        }
        
        # Get list of open PRs with auto-sync prefix
        $prs = gh pr list --state open --json number,headRefName,title --jq ".[] | select(.headRefName | startswith(`"$BranchPrefix`"))"
        
        if ($prs) {
            # Parse the JSON to get the most recent PR
            $prData = $prs | ConvertFrom-Json | Sort-Object number -Descending | Select-Object -First 1
            return @{
                Number = $prData.number
                Branch = $prData.headRefName
                Title = $prData.title
            }
        }
        return $null
    } catch {
        Write-Log "Could not check for existing PRs: $($_.Exception.Message)" -Level "WARNING"
        return $null
    }
}

# Function to check if GitHub CLI is authenticated
function Test-GitHubAuth {
    try {
        $null = gh auth status 2>$null
        return $LASTEXITCODE -eq 0
    } catch {
        return $false
    }
}

# Function to prompt for GitHub authentication
function Request-GitHubAuth {
    Write-Log "GitHub CLI is not authenticated." -Level "WARNING"
    Write-Log "To use this script, you need to authenticate with GitHub." -Level "INFO"
    Write-Log "Options:" -Level "INFO"
    Write-Log "  1. Run: gh auth login" -Level "INFO"
    Write-Log "  2. Set GH_TOKEN environment variable with a GitHub API token" -Level "INFO"
    Write-Log "  3. Use -DryRun mode to test without authentication" -Level "INFO"
    
    $response = Read-Host "Would you like to run 'gh auth login' now? (y/N)"
    if ($response -eq 'y' -or $response -eq 'Y') {
        try {
            gh auth login
            if (Test-GitHubAuth) {
                Write-Log "GitHub authentication successful!" -Level "INFO"
                return $true
            } else {
                Write-Log "GitHub authentication failed or was cancelled." -Level "ERROR"
                return $false
            }
        } catch {
            Write-Log "Failed to run GitHub authentication: $($_.Exception.Message)" -Level "ERROR"
            return $false
        }
    }
    return $false
}

# Function to cleanup failed branch
function Remove-FailedBranch {
    param([string]$BranchName)
    
    try {
        Write-Log "Cleaning up failed branch: $BranchName" -Level "WARNING"
        
        # Switch back to main if we're still on the failed branch
        $currentBranch = git branch --show-current
        if ($currentBranch -eq $BranchName) {
            git checkout main
        }
        
        # Delete local branch
        git branch -D $BranchName
        
        # Delete remote branch if it exists
        $remoteBranch = git ls-remote --heads origin $BranchName
        if ($remoteBranch) {
            Write-Log "Deleting remote branch: $BranchName" -Level "WARNING"
            git push origin --delete $BranchName
        }
        
        Write-Log "Branch cleanup completed" -Level "INFO"
    } catch {
        Write-Log "Failed to cleanup branch: $($_.Exception.Message)" -Level "ERROR"
    }
}

# Function to check if current changes differ from PR branch
function Test-ChangesDifferFromPR {
    param([string]$PrBranch)
    
    try {
        # Fetch the latest changes
        git fetch origin $PrBranch
        
        # Stage current changes temporarily
        git add .
        
        # Compare with the PR branch
        $diff = git diff --cached origin/$PrBranch
        
        # Unstage the changes
        git reset
        
        return -not [string]::IsNullOrWhiteSpace($diff)
    } catch {
        Write-Log "Could not compare changes with PR branch: $($_.Exception.Message)" -Level "WARNING"
        return $true  # Assume there are differences if we can't compare
    }
}

# Check if help is requested, if no parameters, or validate mutually exclusive parameters
if ($Help -or ($args.Count -eq 0 -and -not $Run -and -not $DryRun)) {
    Show-Help
    exit 0
}

# Check for mutually exclusive parameters
if ($Run -and $DryRun) {
    Write-Host "Error: -Run and -DryRun are mutually exclusive. Use one or the other." -ForegroundColor Red
    Write-Host "Use -Help or -h to see usage information." -ForegroundColor Yellow
    exit 1
}

# Check if neither -Run nor -DryRun is specified
if (-not $Run -and -not $DryRun) {
    Write-Host "Error: This script requires either -Run (-r) or -DryRun (-dr) flag to run." -ForegroundColor Red
    Write-Host "Use -Help or -h to see usage information." -ForegroundColor Yellow
    exit 1
}

# Set working directory to script location
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

Write-Log "Starting auto-sync process in $ScriptDir"

try {
    # Step 0: Install requirements
    Install-Requirements

    # Step 0.5: Check GitHub authentication
    if (-not (Test-GitHubAuth)) {
        if (-not $DryRun) {
            if (-not (Request-GitHubAuth)) {
                Write-Log "GitHub authentication is required for this script to function properly." -Level "ERROR"
                exit 1
            }
        } else {
            Write-Log "DRY RUN: Continuing without GitHub authentication (no actual changes will be made)" -Level "WARNING"
        }
    } else {
        Write-Log "GitHub CLI is authenticated and ready" -Level "INFO"
    }

    # Step 1: Run sync_files.py
    Write-Log "Running sync_files.py..."
    
    if ($DryRun) {
        Write-Log "DRY RUN: Would execute: python sync_files.py" -Level "INFO"
    } else {
        python sync_files.py
        if ($LASTEXITCODE -ne 0) {
            throw "sync_files.py failed with exit code $LASTEXITCODE"
        }
        Write-Log "sync_files.py completed successfully"
    }

    # Step 2: Check if there are any changes
    Write-Log "Checking for git changes..."
    
    $gitStatus = git status --porcelain
    if (-not $gitStatus) {
        Write-Log "No changes detected. Exiting." -Level "INFO"
        exit 0
    }

    Write-Log "Changes detected:"
    git status --short

    # Step 3: Check for existing PR
    $existingPR = Get-ExistingPR -BranchPrefix $BranchPrefix
    
    if ($existingPR) {
        Write-Log "Found existing PR #$($existingPR.Number) on branch $($existingPR.Branch)"
        
        # Check if current changes are different from the existing PR
        if (Test-ChangesDifferFromPR -PrBranch $existingPR.Branch) {
            Write-Log "Current changes differ from existing PR. Updating PR..." -Level "INFO"
            
            # Switch to existing branch and update it
            if ($DryRun) {
                Write-Log "DRY RUN: Would checkout branch $($existingPR.Branch) and update it" -Level "INFO"
            } else {
                # Check authentication before updating PR
                if (-not (Test-GitHubAuth)) {
                    Write-Log "GitHub CLI authentication lost. Cannot update PR." -Level "ERROR"
                    throw "GitHub CLI authentication required"
                }
                
                git checkout $existingPR.Branch
                git pull origin $existingPR.Branch
                git add .
                
                $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
                git commit -m "$CommitMessage - Updated $timestamp"
                git push origin $existingPR.Branch
                
                # Update PR description
                $prBody = @"
This is an automated pull request created by the auto-sync script.

## Changes
This PR contains the latest synced dotfiles from the local system.

## Files Changed
``````
$($gitStatus)
``````

Last updated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@
                gh pr edit $existingPR.Number --body $prBody
                if ($LASTEXITCODE -eq 0) {
                    Write-Log "Updated existing PR #$($existingPR.Number)"
                    
                    # Get the PR URL
                    $prUrl = gh pr view $existingPR.Number --json url --jq .url
                    if ($prUrl) {
                        Write-Log "PR URL: $prUrl"
                    }
                } else {
                    Write-Log "Failed to update PR description, but commits were pushed successfully" -Level "WARNING"
                }
            }
        } else {
            Write-Log "No new changes compared to existing PR. Nothing to update." -Level "INFO"
            exit 0
        }
    } else {
        # No existing PR, create a new one
        Write-Log "No existing PR found. Creating new PR..."
        
        # Create a new branch with timestamp
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $branchName = "$BranchPrefix-$timestamp"
        
        Write-Log "Creating new branch: $branchName"
        
        if ($DryRun) {
            Write-Log "DRY RUN: Would create branch $branchName" -Level "INFO"
        } else {
            git checkout -b $branchName
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to create branch $branchName"
            }
        }

        # Stage and commit changes
        Write-Log "Staging and committing changes..."
        
        if ($DryRun) {
            Write-Log "DRY RUN: Would stage all changes and commit with message: $CommitMessage" -Level "INFO"
        } else {
            git add .
            git commit -m "$CommitMessage - $timestamp"
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to commit changes"
            }
        }

        # Push to origin
        Write-Log "Pushing branch to origin..."
        
        if ($DryRun) {
            Write-Log "DRY RUN: Would push branch $branchName to origin" -Level "INFO"
        } else {
            git push -u origin $branchName
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to push branch to origin"
            }
        }

        # Create PR using GitHub CLI
        Write-Log "Creating pull request using GitHub CLI..."
        
        $prTitle = "Auto-sync dotfiles - $timestamp"
        $prBody = @"
This is an automated pull request created by the auto-sync script.

## Changes
This PR contains the latest synced dotfiles from the local system.

## Files Changed
``````
$($gitStatus)
``````

Generated on: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@

        if ($DryRun) {
            Write-Log "DRY RUN: Would create PR with title: $prTitle" -Level "INFO"
        } else {
            # Check authentication again before creating PR
            if (-not (Test-GitHubAuth)) {
                Write-Log "GitHub CLI authentication lost. Cannot create PR." -Level "ERROR"
                Remove-FailedBranch -BranchName $branchName
                throw "GitHub CLI authentication required"
            }
            
            gh pr create --title $prTitle --body $prBody --base main --head $branchName
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Pull request created successfully!"
                
                # Get the PR URL
                $prUrl = gh pr view $branchName --json url --jq .url
                if ($prUrl) {
                    Write-Log "PR URL: $prUrl"
                }
            } else {
                Write-Log "Failed to create pull request via GitHub CLI" -Level "ERROR"
                Remove-FailedBranch -BranchName $branchName
                throw "Failed to create pull request"
            }
        }
    }

    # Return to main branch
    if (-not $DryRun) {
        Write-Log "Returning to main branch..."
        git checkout main
    }

    Write-Log "Auto-sync process completed successfully!" -Level "INFO"

} catch {
    Write-Log "Error: $($_.Exception.Message)" -Level "ERROR"
    
    # Try to return to main branch on error
    try {
        if (-not $DryRun) {
            git checkout main
        }
    } catch {
        Write-Log "Failed to return to main branch: $($_.Exception.Message)" -Level "ERROR"
    }
    
    exit 1
}

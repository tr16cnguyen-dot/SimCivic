$repo = "C:\Users\tr16c\Documents\SimCivic"

# ── Validate repo exists ───────────────────────────────────────────────────
if (-not (Test-Path $repo -PathType Container)) {
    Write-Error "Repository folder not found: $repo"; exit 1
}
if (-not (Test-Path "$repo\.git" -PathType Container)) {
    Write-Error "Not a git repository: $repo"; exit 1
}

Set-Location $repo

# ── Sanitize commit message (strip control characters) ────────────────────
$rawMsg = if ($args[0]) { $args[0] } else { "Update SimCivic dashboard $(Get-Date -Format 'yyyy-MM-dd HH:mm')" }
$msg    = $rawMsg -replace '[\x00-\x1F\x7F]', ''   # strip control chars
if ($msg.Length -gt 200) { $msg = $msg.Substring(0, 200) }   # cap length

git add index.html
$status = git status --porcelain
if (-not $status) {
    Write-Output "Nothing to commit - already up to date."
    exit 0
}

# ── Use array-form to prevent shell injection in commit message ────────────
git @('commit', '-m', $msg)
if ($LASTEXITCODE -ne 0) {
    Write-Error "Commit failed (exit $LASTEXITCODE)"; exit $LASTEXITCODE
}

# ── Validate branch name before push ──────────────────────────────────────
$branch = git rev-parse --abbrev-ref HEAD 2>&1
if ($LASTEXITCODE -ne 0 -or $branch -notmatch '^[a-zA-Z0-9/_\-\.]+$') {
    Write-Error "Invalid or unreadable branch name: $branch"; exit 1
}

git @('push', 'origin', $branch)
if ($LASTEXITCODE -ne 0) {
    Write-Error "Push failed (exit $LASTEXITCODE)"; exit $LASTEXITCODE
}

Write-Output "Pushed to GitHub successfully (branch: $branch)."

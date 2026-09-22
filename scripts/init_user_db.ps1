# scripts\init_user_db.ps1
# Usage: .\scripts\init_user_db.ps1 -UserId <id> -Email <email>
# Requires: sqlite3 CLI available in PATH (https://www.sqlite.org/download.html)

param (
  [Parameter(Mandatory=$true)] [string]$UserId,
  [Parameter(Mandatory=$false)] [string]$Email
)

$projectRoot = Split-Path -Parent $PSScriptRoot
$schemaPath = Join-Path $projectRoot 'db\schema.sqlite.sql'
$storageDir = Join-Path $projectRoot 'storage\db'
$dbPath = Join-Path $storageDir ("$UserId.sqlite")

if (-not (Test-Path $schemaPath)) {
  Write-Error "Schema file not found: $schemaPath"; exit 2
}

if (-not (Get-Command sqlite3 -ErrorAction SilentlyContinue)) {
  Write-Error "sqlite3 CLI not found in PATH. Download from https://www.sqlite.org/download.html"; exit 3
}

New-Item -ItemType Directory -Path $storageDir -Force | Out-Null

Write-Host "Initializing DB for user $UserId at $dbPath"

# Run sqlite3 with .read to execute the schema
# The argument form: sqlite3.exe <dbfile> ".read <schemafile>"
$readArg = ".read $($schemaPath)"
$startInfo = @{ FilePath = 'sqlite3'; ArgumentList = $dbPath, $readArg }

$proc = Start-Process @startInfo -NoNewWindow -Wait -PassThru
if ($proc.ExitCode -ne 0) {
  Write-Error "sqlite3 exited with code $($proc.ExitCode)"; exit $proc.ExitCode
}

# Insert owner row if table exists
# Use sqlite3 parameterized insert via temporary SQL file
$ownerSql = @"
INSERT OR IGNORE INTO owner (id, email, display_name, created_at) VALUES ('$UserId', '$Email', NULL, datetime('now'));
"@

$ownerTemp = [IO.Path]::GetTempFileName()
Set-Content -Path $ownerTemp -Value $ownerSql -Encoding UTF8
$proc2 = Start-Process -FilePath sqlite3 -ArgumentList $dbPath, ".read $ownerTemp" -NoNewWindow -Wait -PassThru
Remove-Item $ownerTemp -Force

if ($proc2.ExitCode -ne 0) {
  Write-Warning "Owner insert may have failed (exit $($proc2.ExitCode))." 
} else {
  Write-Host "Database initialized and owner row inserted (or existed)."
}

# Convenience script to run the PostSA Flutter app with Supabase config.
#
# Usage:
#   .\run_dev.ps1                    # Uses default dev values below
#   .\run_dev.ps1 -Url <url> -Key <key>   # Override
#
# IMPORTANT: Do NOT commit real production keys. Create a local copy
# (e.g. run_dev.local.ps1) with your actual keys and add it to .gitignore.

param(
  [string]$Url  = "https://iirpfvpjhpqmnguvyiku.supabase.co",
  [string]$Key  = "sb_publishable_sMZaSjl2QOZvNUmJw4cCqw_ICyG54Dj"
)

$flutter = "C:\Users\Iqbal\OneDrive\Documents\flutter\bin\flutter.bat"

Write-Host "Starting PostSA Flutter POS with Supabase config..." -ForegroundColor Cyan
Write-Host "  URL: $Url"
Write-Host ""

& $flutter run `
  --dart-define=SUPABASE_URL=$Url `
  --dart-define=SUPABASE_ANON_KEY=$Key

# PowerShell script to create a ZIP file for GitHub upload
$source = "C:\Users\macks\Desktop\Lab Glassess\glasses_app"
$destination = "C:\Users\macks\Desktop\smart-glasses-app.zip"

# Remove old zip if exists
if (Test-Path $destination) {
    Remove-Item $destination
}

# Create zip excluding unnecessary files
$exclude = @("*.zip", "create_zip.ps1", "build", ".dart_tool")

Write-Host "Creating ZIP file for GitHub upload..." -ForegroundColor Cyan
Compress-Archive -Path "$source\*" -DestinationPath $destination -Force

Write-Host ""
Write-Host "ZIP file created successfully!" -ForegroundColor Green
Write-Host "Location: $destination" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Go to https://github.com/new" -ForegroundColor White
Write-Host "2. Create a new repository named 'smart-glasses-app'" -ForegroundColor White
Write-Host "3. Extract the ZIP and upload all files" -ForegroundColor White

# Open the folder containing the zip
explorer "C:\Users\macks\Desktop"


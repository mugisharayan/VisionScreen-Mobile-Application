$file = 'c:\Users\TABITHA\Desktop\VISION SCREEN\VisionScreen-Mobile-Application\lib\screens\home_screen.dart'
$content = [System.IO.File]::ReadAllText($file)

# Replace remaining non-standard fonts
$content = $content -replace 'GoogleFonts\.barlow\(', 'GoogleFonts.nunito('
$content = $content -replace 'GoogleFonts\.sora\(', 'GoogleFonts.poppins('
$content = $content -replace 'GoogleFonts\.dmSerifDisplay\(', 'GoogleFonts.nunito('

# Fix hardcoded dark colors to AppColors equivalents
$content = $content -replace "const Color\(0xFF1A2A3D\)", "AppColors.textDark"
$content = $content -replace "const Color\(0xFF8FA0B4\)", "AppColors.textMuted"
$content = $content -replace "const Color\(0xFF5E7291\)", "AppColors.textMuted"

[System.IO.File]::WriteAllText($file, $content)
Write-Host "Done"

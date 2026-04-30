$file = 'c:\Users\TABITHA\Desktop\VISION SCREEN\VisionScreen-Mobile-Application\lib\screens\home_screen.dart'
$content = [System.IO.File]::ReadAllText($file)

# Pass rate strip: replace dark teal gradient with green
$content = $content -replace "Color\(0xFF0D3D38\)", "AppColors.greenDeep"
$content = $content -replace "Color\(0xFF1A7A3E\)", "AppColors.greenDeep"

# Pass rate strip circular indicator: teal -> green
$content = $content -replace "Color\(0xFF5EEAD4\)\)", "AppColors.green)"

# Update plusJakartaSans/spaceGrotesk/inter fonts in patient cards to poppins/nunito
$content = $content -replace "GoogleFonts\.plusJakartaSans\(", "GoogleFonts.nunito("
$content = $content -replace "GoogleFonts\.spaceGrotesk\(", "GoogleFonts.nunito("
$content = $content -replace "GoogleFonts\.ibmPlexSans\(", "GoogleFonts.poppins("
$content = $content -replace "GoogleFonts\.inter\(", "GoogleFonts.poppins("

[System.IO.File]::WriteAllText($file, $content)
Write-Host "Done"

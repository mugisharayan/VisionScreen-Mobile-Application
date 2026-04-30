$file = 'c:\Users\TABITHA\Desktop\VISION SCREEN\VisionScreen-Mobile-Application\lib\screens\home_screen.dart'
$content = [System.IO.File]::ReadAllText($file)

# Fix: const AppColors.green -> AppColors.green
$content = $content -replace 'const AppColors\.green', 'AppColors.green'

# Fix: AppColors.green.withOpacity -> AppColors.green.withValues(alpha:
# (leave withOpacity as is for now, just fix the const issue)

[System.IO.File]::WriteAllText($file, $content)
Write-Host "Done"

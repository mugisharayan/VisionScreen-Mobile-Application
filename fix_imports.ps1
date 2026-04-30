$file = 'c:\Users\TABITHA\Desktop\VISION SCREEN\VisionScreen-Mobile-Application\lib\screens\home_screen.dart'
$lines = [System.IO.File]::ReadAllLines($file)

# Add AppColors import after line 9
$importLine = "import 'splash_screen.dart' show AppColors;"
$lines = $lines[0..9] + $importLine + $lines[10..($lines.Length-1)]

# Now fix the scaffold - lines shifted by 1
# Line 192 has old color, 193 has new color (duplicate), 194-195 are misplaced
$lines[192] = '              color: AppColors.green,'
$lines[193] = '              child: SingleChildScrollView('
$lines[194] = '                physics: const AlwaysScrollableScrollPhysics(),'
$lines[195] = '                padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),'

[System.IO.File]::WriteAllLines($file, $lines)
Write-Host "Done"

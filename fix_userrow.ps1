$file = 'c:\Users\TABITHA\Desktop\VISION SCREEN\VisionScreen-Mobile-Application\lib\screens\home_screen.dart'
$lines = [System.IO.File]::ReadAllLines($file)

# Avatar gradient: teal -> green
$lines[544] = '            gradient: const LinearGradient('
$lines[545] = '              colors: [AppColors.greenDark, AppColors.green],'
$lines[549] = '            border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),'

# CHW name style: white (already white, keep)
$lines[565] = '                      style: GoogleFonts.poppins('

# CHW name text style
$lines[578] = '                style: GoogleFonts.nunito('
$lines[579] = '                    color: Colors.white,'
$lines[580] = '                    fontSize: 14,'
$lines[581] = '                    fontWeight: FontWeight.w800)),'

# CHW center text style
$lines[584] = '                style: GoogleFonts.poppins('
$lines[585] = '                    color: Colors.white.withValues(alpha: 0.8),'
$lines[586] = '                    fontSize: 11,'
$lines[587] = '                    fontWeight: FontWeight.w500)),'

# Connectivity indicator - use white bg with opacity
$lines[597] = '            color: _isOffline'
$lines[598] = '                ? Colors.red.withValues(alpha: 0.25)'
$lines[599] = '                : Colors.white.withValues(alpha: 0.25),'
$lines[602] = '              color: _isOffline'
$lines[603] = '                  ? Colors.red.withValues(alpha: 0.7)'
$lines[604] = '                  : Colors.white.withValues(alpha: 0.6),'

# Connectivity dot colors
$lines[618] = '                      color: _isOffline'
$lines[619] = '                          ? Colors.red'
$lines[620] = '                          : Colors.white,'

# Connectivity text color
$lines[629] = '                style: GoogleFonts.poppins('
$lines[630] = '                    fontSize: 9,'
$lines[631] = '                    fontWeight: FontWeight.w700,'
$lines[632] = '                    color: _isOffline'
$lines[633] = '                        ? Colors.red'
$lines[634] = '                        : Colors.white),'

[System.IO.File]::WriteAllLines($file, $lines)
Write-Host "Done"

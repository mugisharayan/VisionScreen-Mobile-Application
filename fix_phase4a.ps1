$file = 'c:\Users\TABITHA\Desktop\VISION SCREEN\VisionScreen-Mobile-Application\lib\screens\home_screen.dart'
$lines = [System.IO.File]::ReadAllLines($file)

# ── Section header: "Today's Screenings" title font
$lines[1234] = '                    style: GoogleFonts.nunito('
$lines[1235] = '                        fontSize: 16,'
$lines[1236] = '                        fontWeight: FontWeight.w900,'
$lines[1237] = '                        color: AppColors.textDark,'
$lines[1238] = '                        letterSpacing: 0.1)),'

# ── Section header subtitle font
$lines[1240] = '                    style: GoogleFonts.poppins('
$lines[1241] = '                        fontSize: 11,'
$lines[1242] = '                        color: AppColors.textMuted,'
$lines[1243] = '                        fontWeight: FontWeight.w400)),'

# ── "See all" button color: teal -> green
$lines[1252] = '                  size: 13, color: AppColors.green),'
$lines[1254] = '                  style: GoogleFonts.poppins('
$lines[1255] = '                      fontSize: 11,'
$lines[1256] = '                      color: AppColors.greenDark,'
$lines[1257] = '                      fontWeight: FontWeight.w600)),'
$lines[1259] = '                backgroundColor: AppColors.greenHero,'
$lines[1261] = '                    borderRadius: BorderRadius.circular(99)),'

# ── Empty state text
$lines[1276] = '                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMuted, height: 1.6),'

# ── Patient card border color
$lines[1368] = '            border: Border.all(color: AppColors.borderColor, width: 1.5),'

# ── Patient name font
$lines[1421] = '                              Flexible(child: Text(name, overflow: TextOverflow.ellipsis, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark))),'

# ── Demographic text
$lines[1435] = '                               Flexible(child: Text(demographic, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted))),'

# ── Bottom strip id/time text
$lines[1486] = '                      child: Text(id, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w500)),'
$lines[1491] = '                    Text(time, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w500)),'

# ── VA pill colors: teal -> green
$lines[1506] = '    final fg = isBad ? const Color(0xFFEF4444) : AppColors.greenDark;'

[System.IO.File]::WriteAllLines($file, $lines)
Write-Host "Done"

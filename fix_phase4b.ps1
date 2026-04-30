$file = 'c:\Users\TABITHA\Desktop\VISION SCREEN\VisionScreen-Mobile-Application\lib\screens\home_screen.dart'
$lines = [System.IO.File]::ReadAllLines($file)

# ── Referral section title
$lines[1533] = '                    style: GoogleFonts.nunito('
$lines[1534] = '                        fontSize: 16, fontWeight: FontWeight.w900,'
$lines[1535] = '                        color: AppColors.textDark, letterSpacing: 0.1)),'

# ── Referral subtitle
$lines[1537] = '                    style: GoogleFonts.poppins('
$lines[1538] = '                        fontSize: 11,'
$lines[1540] = '                        fontWeight: FontWeight.w500)),'

# ── "View all" button
$lines[1545] = '              icon: const Icon(Icons.arrow_forward_rounded, size: 13, color: AppColors.green),'
$lines[1546] = '              label: Text(''View all'', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.greenDark, fontWeight: FontWeight.w600)),'
$lines[1548] = '                backgroundColor: AppColors.greenHero,'

# ── Empty state
$lines[1561] = '                  style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMuted)),'

# ── Section label method
# Find _buildSectionLabel and update it
for ($i = 0; $i -lt $lines.Length; $i++) {
    if ($lines[$i] -match '_buildSectionLabel') {
        # found usage, skip
    }
    if ($lines[$i] -match 'Widget _buildSectionLabel') {
        $lines[$i+3] = '      style: GoogleFonts.nunito('
        $lines[$i+4] = '        fontSize: 12,'
        $lines[$i+5] = '        fontWeight: FontWeight.w900,'
        $lines[$i+6] = '        color: AppColors.textDark,'
        $lines[$i+7] = '        letterSpacing: 1.5,'
        break
    }
}

# ── Pass rate strip: update teal to green
for ($i = 0; $i -lt $lines.Length; $i++) {
    if ($lines[$i] -match '0xFF0D3D38') {
        $lines[$i] = $lines[$i] -replace '0xFF0D3D38', '0xFF1A7A3E'
    }
    if ($lines[$i] -match '0xFF0D9488') {
        $lines[$i] = $lines[$i] -replace 'Color\(0xFF0D9488\)', 'AppColors.green'
    }
}

[System.IO.File]::WriteAllLines($file, $lines)
Write-Host "Done"

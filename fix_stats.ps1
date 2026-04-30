$file = 'c:\Users\TABITHA\Desktop\VISION SCREEN\VisionScreen-Mobile-Application\lib\screens\home_screen.dart'
$lines = [System.IO.File]::ReadAllLines($file)

$newStats = @(
'',
'  Widget _buildStatsRow() {',
'    return Row(',
'      children: [',
"        _buildStatCard('\$_totalScreened', 'Screened', Icons.remove_red_eye_outlined, Colors.white),",
'        const SizedBox(width: 8),',
"        _buildStatCard('\$_totalReferred', 'Referred', Icons.warning_amber_rounded, const Color(0xFFFFE08A)),",
'        const SizedBox(width: 8),',
"        _buildStatCard('\$_unsyncedCount', 'Unsynced', Icons.sync_rounded, const Color(0xFFFFB3B3)),",
'      ],',
'    );',
'  }',
'',
'  Widget _buildStatCard(String number, String label, IconData icon, Color accent) {',
'    return Expanded(',
'      child: Container(',
'        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),',
'        decoration: BoxDecoration(',
'          color: Colors.white.withValues(alpha: 0.18),',
'          borderRadius: BorderRadius.circular(14),',
'          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),',
'        ),',
'        child: Column(',
'          mainAxisSize: MainAxisSize.min,',
'          children: [',
'            Icon(icon, size: 18, color: accent),',
'            const SizedBox(height: 4),',
'            Text(number,',
'                style: GoogleFonts.nunito(',
'                    fontSize: 20,',
'                    fontWeight: FontWeight.w900,',
'                    color: Colors.white)),',
'            Text(label,',
'                style: GoogleFonts.poppins(',
'                    fontSize: 9,',
'                    color: Colors.white.withValues(alpha: 0.85),',
'                    fontWeight: FontWeight.w500,',
'                    letterSpacing: 0.5)),',
'          ],',
'        ),',
'      ),',
'    );',
'  }'
)

$lines = $lines[0..849] + $newStats + $lines[909..($lines.Length-1)]
[System.IO.File]::WriteAllLines($file, $lines)
Write-Host "Done"

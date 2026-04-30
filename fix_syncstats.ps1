$file = 'c:\Users\TABITHA\Desktop\VISION SCREEN\VisionScreen-Mobile-Application\lib\screens\home_screen.dart'
$lines = [System.IO.File]::ReadAllLines($file)

# SyncBar - update text color from teal to white
$lines[823] = '                    color: Colors.white.withValues(alpha: 0.9),'
$lines[833] = '                      color: Colors.white,'
$lines[839] = '                        color: Colors.white,'

# StatsRow - update change colors to white-based
$lines[852] = '        _buildStatCard(''$_totalScreened'', ''Screened'', ''Total'', Colors.white),'
$lines[854] = '        _buildStatCard(''$_totalReferred'', ''Referrals'', ''Need follow-up'', const Color(0xFFFFE08A)),'
$lines[856] = '        _buildStatCard(''$_unsyncedCount'', ''Unsynced'', ''Pending upload'', const Color(0xFFFFB3B3)),'

# StatCard - number color white, label color white with opacity
$lines[888] = '                    color: Colors.white)),'
$lines[892] = '                    color: Colors.white.withValues(alpha: 0.7),'
$lines[899] = '                    color: changeColor,'

[System.IO.File]::WriteAllLines($file, $lines)
Write-Host "Done"

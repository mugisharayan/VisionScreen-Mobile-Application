$file = 'c:\Users\TABITHA\Desktop\VISION SCREEN\VisionScreen-Mobile-Application\lib\screens\home_screen.dart'
$lines = [System.IO.File]::ReadAllLines($file)

# ── Fix header: remove duplicate old RichText lines 464-465 and fix location row ──
# Lines 464-465 are the old RichText start, 466-478 is the new one
# Lines 479-515 are the old location/time row that got orphaned inside children:[]
# We need to:
# 1. Remove lines 464-465 (old RichText( + text: TextSpan()
# 2. Keep 466-478 (new RichText)
# 3. Replace 479-515 with proper Row widgets (not inside TextSpan children)

$lines[464] = ''  # remove old RichText(
$lines[465] = ''  # remove old text: TextSpan(

# Fix orphaned children: [ at 479 - replace with proper SizedBox + Row
$lines[479] = '                    const SizedBox(height: 6),'
$lines[480] = '                    Row('
$lines[481] = '                      children: ['
$lines[482] = '                        GestureDetector('
$lines[483] = '                          onTap: _fetchLocation,'
$lines[484] = '                          child: Row('
$lines[485] = '                            children: ['
$lines[486] = '                              Icon('
$lines[487] = "                                _locationLabel.contains('retry') || _locationLabel.contains('timeout')"
$lines[488] = '                                    ? Icons.refresh_rounded : Icons.location_on_rounded,'
$lines[489] = '                                size: 11, color: Colors.white.withValues(alpha: 0.85),'
$lines[490] = '                              ),'
$lines[491] = '                              const SizedBox(width: 4),'
$lines[492] = '                              ConstrainedBox('
$lines[493] = '                                constraints: const BoxConstraints(maxWidth: 160),'
$lines[494] = '                                child: Text(_locationLabel, overflow: TextOverflow.ellipsis,'
$lines[495] = '                                  style: GoogleFonts.poppins(fontSize: 11,'
$lines[496] = '                                    color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w500)),'
$lines[497] = '                              ),'
$lines[498] = '                            ],'
$lines[499] = '                          ),'
$lines[500] = '                        ),'
$lines[501] = '                        const Spacer(),'
$lines[502] = '                        Container('
$lines[503] = '                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),'
$lines[504] = '                          decoration: BoxDecoration('
$lines[505] = '                            color: Colors.white.withValues(alpha: 0.2),'
$lines[506] = '                            borderRadius: BorderRadius.circular(99),'
$lines[507] = '                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),'
$lines[508] = '                          ),'
$lines[509] = '                          child: Row(children: ['
$lines[510] = '                            Icon(Icons.access_time_rounded, size: 10, color: Colors.white),'
$lines[511] = '                            const SizedBox(width: 4),'
$lines[512] = '                            Text(_formatTime(_now), style: GoogleFonts.poppins('
$lines[513] = '                                fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),'
$lines[514] = '                          ]),'
$lines[515] = '                        ),'
$lines[516] = '                      ],'  # close Row children
# line 517 was already: const SizedBox(height: 4) - but now it's Row(children: [
# need to close the Row and add SizedBox
$lines[517] = '                    ),'   # close Row(

# ── Fix stats: restore mangled variable names ──
$lines[835] = "          number: '\$_totalScreened',"
$lines[843] = "          number: '\$_totalReferred',"
$lines[851] = "          number: '\$_unsyncedCount',"

[System.IO.File]::WriteAllLines($file, $lines)
Write-Host "Done"

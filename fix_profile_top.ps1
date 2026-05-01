$file = 'c:\Users\TABITHA\Desktop\VISION SCREEN\VisionScreen-Mobile-Application\lib\screens\home_screen.dart'
$lines = [System.IO.File]::ReadAllLines($file)

# Replace brand row closing (lines 492-496) to add profile avatar on right
# Line 492: ]),   <- closes left Row
# Line 493: ],    <- closes brand Row children
# Line 494: ),    <- closes brand Row
# Line 495: const SizedBox(height: 14),
# Line 496: _buildUserRow(),
# Line 497: const SizedBox(height: 14),

$lines[492] = '                        ]),'   # close left logo Row
$lines[493] = '                        // Profile avatar top-right'
$lines[494] = '                        GestureDetector('
$lines[495] = '                          onTap: () {},'
$lines[496] = '                          child: Container('
$lines[497] = '                            width: 38, height: 38,'
$lines[498] = '                            decoration: BoxDecoration('
$lines[499] = '                              borderRadius: BorderRadius.circular(12),'
$lines[500] = '                              gradient: const LinearGradient('
$lines[501] = '                                colors: [AppColors.greenDark, AppColors.green],'
$lines[502] = '                                begin: Alignment.topLeft, end: Alignment.bottomRight,'
$lines[503] = '                              ),'
$lines[504] = '                              border: Border.all(color: Colors.white, width: 2),'
$lines[505] = '                            ),'
$lines[506] = '                            child: ClipRRect('
$lines[507] = '                              borderRadius: BorderRadius.circular(10),'
$lines[508] = '                              child: Center('
$lines[509] = '                                child: Text('
$lines[510] = '                                  _chwName.trim().isEmpty ? ''VS'' : _chwName.trim().split('' '').map((w) => w.isEmpty ? '''' : w[0]).take(2).join().toUpperCase(),'
$lines[511] = '                                  style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),'
$lines[512] = '                                ),'
$lines[513] = '                              ),'
$lines[514] = '                            ),'
$lines[515] = '                          ),'
$lines[516] = '                        ),'
$lines[517] = '                      ],'   # close brand Row children
$lines[518] = '                    ),'     # close brand Row

# Remove old _buildUserRow call and its spacing (now handled inline)
# Find and clear lines 519+ that had SizedBox + _buildUserRow
$lines[519] = '                    const SizedBox(height: 12),'
$lines[520] = ''
$lines[521] = ''

[System.IO.File]::WriteAllLines($file, $lines)
Write-Host "Done"

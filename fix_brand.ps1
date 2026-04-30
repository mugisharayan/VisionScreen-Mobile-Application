$file = 'c:\Users\TABITHA\Desktop\VISION SCREEN\VisionScreen-Mobile-Application\lib\screens\home_screen.dart'
$lines = [System.IO.File]::ReadAllLines($file)

# ── 1. Insert brand row + greeting before _buildUserRow ──
$brandRow = @(
'                    // Brand row',
'                    Row(',
'                      mainAxisAlignment: MainAxisAlignment.spaceBetween,',
'                      children: [',
'                        Row(children: [',
'                          Container(',
'                            width: 28, height: 28,',
'                            decoration: BoxDecoration(',
'                              color: Colors.white.withValues(alpha: 0.2),',
'                              borderRadius: BorderRadius.circular(8),',
'                              border: Border.all(color: Colors.white.withValues(alpha: 0.4)),',
'                            ),',
'                            child: const Center(',
'                              child: CustomPaint(',
'                                size: Size(16, 16),',
'                                painter: _AuthEyePainter(color: Colors.white),',
'                              ),',
'                            ),',
'                          ),',
'                          const SizedBox(width: 8),',
'                          RichText(',
'                            text: TextSpan(',
'                              style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w900),',
'                              children: const [',
'                                TextSpan(text: ''Vision'', style: TextStyle(color: Colors.white)),',
'                                TextSpan(text: ''Screen'', style: TextStyle(color: Colors.black)),',
'                              ],',
'                            ),',
'                          ),',
'                        ]),',
'                      ],',
'                    ),',
'                    const SizedBox(height: 14),'
)

# Insert brand row before line 462 (_buildUserRow)
$lines = $lines[0..461] + $brandRow + $lines[462..($lines.Length-1)]

[System.IO.File]::WriteAllLines($file, $lines)
Write-Host "Brand row inserted"

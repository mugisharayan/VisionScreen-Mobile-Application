$file = 'c:\Users\TABITHA\Desktop\VISION SCREEN\VisionScreen-Mobile-Application\lib\screens\home_screen.dart'
$lines = [System.IO.File]::ReadAllLines($file)

# ── Find and rewrite _buildHeader greeting section ──
# Find the RichText greeting (around line 455-470)
for ($i = 440; $i -le 490; $i++) {
    if ($lines[$i] -match "Ready to screen") {
        # Rewrite the greeting RichText block
        $lines[$i-2] = '                    RichText('
        $lines[$i-1] = '                      text: TextSpan('
        $lines[$i]   = '                        style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w900),'
        $lines[$i+1] = '                        children: ['
        $lines[$i+2] = "                          const TextSpan(text: 'Ready to screen, ', style: TextStyle(color: Colors.white)),"
        $lines[$i+3] = '                          TextSpan('
        $lines[$i+4] = "                            text: _chwName.isNotEmpty ? _chwName.split(' ').first : 'CHW',"
        $lines[$i+5] = '                            style: const TextStyle(color: Color(0xFFA8F0C6), fontStyle: FontStyle.italic),'
        $lines[$i+6] = '                          ),'
        $lines[$i+7] = "                          const TextSpan(text: '!', style: TextStyle(color: Colors.white)),"
        $lines[$i+8] = '                        ],'
        $lines[$i+9] = '                      ),'
        $lines[$i+10] = '                    ),'
        break
    }
}

[System.IO.File]::WriteAllLines($file, $lines)
Write-Host "Header done"

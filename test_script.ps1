$content = @'
// REDESIGNED HOME SCREEN
'@
[System.IO.File]::WriteAllText('lib\screens\home_screen.dart', $content, [System.Text.Encoding]::UTF8)

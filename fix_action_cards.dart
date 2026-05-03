import 'dart:io';

void main() {
  final file = File('lib/screens/home_screen.dart');
  final lines = file.readAsLinesSync();

  // Find the line with the watermark illustration comment
  int watermarkLine = -1;
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].contains('Large illustration') && lines[i].contains('watermark')) {
      watermarkLine = i;
      break;
    }
  }

  if (watermarkLine == -1) {
    print('ERROR: Could not find watermark line');
    // Print lines around illustration
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains('illustration')) {
        print('Line $i: ${lines[i]}');
      }
    }
    exit(1);
  }

  print('Found watermark at line $watermarkLine: ${lines[watermarkLine]}');

  // Find the end of the old content: "// Bottom: title + subtitle + arrow"
  // then find the closing ),  ),  ],  ),  ),
  // We need to find the line that closes the Padding widget
  // Strategy: find "// Bottom: title + subtitle + arrow" then count to closing

  int bottomCommentLine = -1;
  for (int i = watermarkLine; i < lines.length; i++) {
    if (lines[i].contains('Bottom: title + subtitle + arrow')) {
      bottomCommentLine = i;
      break;
    }
  }

  if (bottomCommentLine == -1) {
    print('ERROR: Could not find bottom comment');
    exit(1);
  }

  print('Found bottom comment at line $bottomCommentLine');

  // Find the closing of the Padding (after the Column closes)
  // Pattern: after the bottom Column, we have:
  //   ],       <- closes Column children
  //   ),       <- closes Column
  //   ],       <- closes Padding Column children  
  //   ),       <- closes Padding child Column
  //   ),       <- closes Padding
  // Then ],  <- closes Stack children
  
  // Find the line with just "                ),\n              ]," pattern
  // which is the closing of the Padding widget
  int paddingEndLine = -1;
  for (int i = bottomCommentLine + 30; i < lines.length; i++) {
    // Look for the pattern: line is "                )," followed by "              ],"
    if (lines[i].trim() == '),' && 
        i + 1 < lines.length && lines[i+1].trim() == '],') {
      // Check if this is the Stack children closing
      if (i + 2 < lines.length && lines[i+2].trim() == '),') {
        paddingEndLine = i;
        print('Found padding end at line $paddingEndLine: ${lines[paddingEndLine]}');
        break;
      }
    }
  }

  if (paddingEndLine == -1) {
    // Try another approach - find the line after the last ], that closes the Padding Column
    for (int i = bottomCommentLine + 20; i < lines.length; i++) {
      if (lines[i].contains('              ],') && 
          i + 1 < lines.length && lines[i+1].contains('            ),') &&
          i + 2 < lines.length && lines[i+2].contains('          ],')) {
        paddingEndLine = i + 1; // the ), that closes Padding
        print('Found padding end (alt) at line $paddingEndLine: ${lines[paddingEndLine]}');
        break;
      }
    }
  }

  if (paddingEndLine == -1) {
    // Print lines from bottomCommentLine to see structure
    print('Printing lines from $bottomCommentLine:');
    for (int i = bottomCommentLine; i < bottomCommentLine + 50 && i < lines.length; i++) {
      print('$i: ${lines[i]}');
    }
    exit(1);
  }

  // Build new content
  final before = lines.sublist(0, watermarkLine);
  final after = lines.sublist(paddingEndLine + 1);

  final newLines = [
    ...before,
    '                // -- Decorative arc top-right --',
    '                Positioned(',
    '                  top: -24, right: -24,',
    '                  child: Container(',
    '                    width: 90, height: 90,',
    '                    decoration: BoxDecoration(',
    '                      shape: BoxShape.circle,',
    '                      border: Border.all(',
    '                          color: Colors.white.withValues(alpha: 0.10),',
    '                          width: 1.5),',
    '                    ),',
    '                  ),',
    '                ),',
    '                Positioned(',
    '                  top: -8, right: -8,',
    '                  child: Container(',
    '                    width: 54, height: 54,',
    '                    decoration: BoxDecoration(',
    '                      shape: BoxShape.circle,',
    '                      border: Border.all(',
    '                          color: Colors.white.withValues(alpha: 0.15),',
    '                          width: 1),',
    '                    ),',
    '                  ),',
    '                ),',
    '                // -- Content --',
    '                Padding(',
    '                  padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),',
    '                  child: Column(',
    '                    crossAxisAlignment: CrossAxisAlignment.start,',
    '                    mainAxisAlignment: MainAxisAlignment.spaceBetween,',
    '                    children: [',
    '                      // Top row: icon + tag',
    '                      Row(',
    '                        mainAxisAlignment: MainAxisAlignment.spaceBetween,',
    '                        crossAxisAlignment: CrossAxisAlignment.start,',
    '                        children: [',
    '                          // Icon with glow container',
    '                          Container(',
    '                            width: 40, height: 40,',
    '                            decoration: BoxDecoration(',
    '                              color: Colors.white.withValues(alpha: 0.22),',
    '                              borderRadius: BorderRadius.circular(12),',
    '                              border: Border.all(',
    '                                  color: Colors.white.withValues(alpha: 0.35),',
    '                                  width: 1.5),',
    '                              boxShadow: [',
    '                                BoxShadow(',
    '                                  color: Colors.black.withValues(alpha: 0.18),',
    '                                  blurRadius: 10,',
    '                                  offset: const Offset(0, 4),',
    '                                ),',
    '                              ],',
    '                            ),',
    '                            child: Icon(a.icon, color: Colors.white, size: 20),',
    '                          ),',
    '                          // Tag pill',
    '                          Container(',
    '                            padding: const EdgeInsets.symmetric(',
    '                                horizontal: 7, vertical: 4),',
    '                            decoration: BoxDecoration(',
    '                              color: Colors.white.withValues(alpha: 0.22),',
    '                              borderRadius: BorderRadius.circular(99),',
    '                              border: Border.all(',
    '                                  color: Colors.white.withValues(alpha: 0.4)),',
    '                            ),',
    '                            child: Text(a.tag,',
    '                                style: GoogleFonts.inter(',
    '                                    fontSize: 7.5,',
    '                                    fontWeight: FontWeight.w800,',
    '                                    color: Colors.white,',
    '                                    letterSpacing: 0.7)),',
    '                          ),',
    '                        ],',
    '                      ),',
    '',
    '                      // Middle: illustration (visible, full opacity)',
    '                      SizedBox(',
    '                        height: 44,',
    '                        child: a.illustration,',
    '                      ),',
    '',
    '                      // Bottom: title + subtitle + arrow',
    '                      Row(',
    '                        crossAxisAlignment: CrossAxisAlignment.end,',
    '                        children: [',
    '                          Expanded(',
    '                            child: Column(',
    '                              crossAxisAlignment: CrossAxisAlignment.start,',
    '                              children: [',
    '                                Text(a.title,',
    '                                    style: GoogleFonts.plusJakartaSans(',
    '                                        fontSize: 13,',
    '                                        fontWeight: FontWeight.w800,',
    '                                        color: Colors.white,',
    '                                        height: 1.1)),',
    '                                const SizedBox(height: 2),',
    '                                Text(a.subtitle,',
    '                                    style: GoogleFonts.inter(',
    '                                        fontSize: 10,',
    '                                        color: Colors.white.withValues(alpha: 0.75),',
    '                                        fontWeight: FontWeight.w400)),',
    '                              ],',
    '                            ),',
    '                          ),',
    '                          Container(',
    '                            width: 26, height: 26,',
    '                            decoration: BoxDecoration(',
    '                              color: Colors.white.withValues(alpha: 0.22),',
    '                              shape: BoxShape.circle,',
    '                              border: Border.all(',
    '                                  color: Colors.white.withValues(alpha: 0.35)),',
    '                            ),',
    '                            child: const Icon(',
    '                                Icons.arrow_forward_rounded,',
    '                                size: 13, color: Colors.white),',
    '                          ),',
    '                        ],',
    '                      ),',
    '                    ],',
    '                  ),',
    '                ),',
    ...after,
  ];

  file.writeAsStringSync(newLines.join('\n'));
  print('SUCCESS: Written ${newLines.length} lines');
}

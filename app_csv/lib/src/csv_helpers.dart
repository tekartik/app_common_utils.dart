import 'dart:typed_data';

/// UTF-8 byte order mark (BOM) for Excel compatibility.
final csvExcelCompatibilityBom = Uint8List.fromList([0xEF, 0xBB, 0xBF]);

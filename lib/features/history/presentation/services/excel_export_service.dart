import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/waybill_item_entity.dart';

class ExcelExportService {
  /// Generates an Excel file for the given waybill items and date range.
  static Future<File> generateWaybillExcel({
    required List<WaybillItemEntity> items,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final excel = Excel.createExcel();
    final sheetName = 'Waybills';

    // Rename default sheet
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null && defaultSheet != sheetName) {
      excel.rename(defaultSheet, sheetName);
    }
    final sheet = excel[sheetName];

    // Define Header Cell Styling
    final headerStyle = CellStyle(
      bold: true,
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#059669'), // SunGguard Emerald
    );

    // Header Row
    final headers = [
      'Waybill ID',
      'Status',
      'Pickup Address',
      'Drop Address',
      'Amount (₹)',
      'Date & Time',
      'Shipment Type',
    ];

    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

    // Apply header styles to Row 0
    for (int col = 0; col < headers.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.cellStyle = headerStyle;
    }

    // Data Cell Styling
    final dataStyle = CellStyle(
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 10,
      fontColorHex: ExcelColor.fromHexString('#0F172A'),
    );

    final numStyle = CellStyle(
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 10,
      fontColorHex: ExcelColor.fromHexString('#059669'),
    );

    // Fill Data Rows
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final rowIndex = i + 1;

      final rowValues = [
        TextCellValue(item.referenceId),
        TextCellValue(item.status.label),
        TextCellValue(item.pickupAddress),
        TextCellValue(item.dropAddress),
        DoubleCellValue(item.amount),
        TextCellValue(item.formattedTime),
        TextCellValue(item.kind.toUpperCase()),
      ];

      sheet.appendRow(rowValues);

      // Apply cell styling
      for (int col = 0; col < rowValues.length; col++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex));
        cell.cellStyle = (col == 4) ? numStyle : dataStyle;
      }
    }

    // Set Column Widths for readability
    sheet.setColumnWidth(0, 20.0);
    sheet.setColumnWidth(1, 18.0);
    sheet.setColumnWidth(2, 35.0);
    sheet.setColumnWidth(3, 35.0);
    sheet.setColumnWidth(4, 15.0);
    sheet.setColumnWidth(5, 22.0);
    sheet.setColumnWidth(6, 16.0);

    // Save bytes to file
    final fileBytes = excel.save();
    if (fileBytes == null || fileBytes.isEmpty) {
      throw Exception('Failed to generate Excel file bytes.');
    }

    final fromStr = DateFormat('yyyy-MM-dd').format(fromDate);
    final toStr = DateFormat('yyyy-MM-dd').format(toDate);
    final fileName = 'Waybill_History_${fromStr}_to_$toStr.xlsx';

    Directory dir;
    if (Platform.isAndroid) {
      final extDir = await getExternalStorageDirectory();
      dir = extDir ?? await getApplicationDocumentsDirectory();
    } else {
      dir = await getApplicationDocumentsDirectory();
    }

    final filePath = '${dir.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(fileBytes, flush: true);

    return file;
  }
}

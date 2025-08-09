import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/theme_provider.dart';

class CertificateScreen extends StatefulWidget {
  const CertificateScreen({super.key});

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  final _studentNameController = TextEditingController();
  final _schoolNameController = TextEditingController();
  final _classController = TextEditingController();
  final _dateController = TextEditingController();
  String? _selectedClass; // Selected class for dropdown

  @override
  void initState() {
    super.initState();
    _dateController.text = _getCurrentDate();
  }

  @override
  void dispose() {
    _studentNameController.dispose();
    _schoolNameController.dispose();
    _classController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('सर्टिफिकेट जेनरेट करें'),
        backgroundColor: AppTheme.purple,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => appState.goBack(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.purple.withOpacity(0.1), Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.purple.withOpacity(0.3)),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.card_membership,
                    size: 60,
                    color: AppTheme.purple,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'हरिहर पाठशाला',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.purple,
                    ),
                  ),
                  Text(
                    'डिजिटल प्रमाणपत्र जेनरेटर',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Form Fields
            const Text(
              'प्रमाणपत्र की जानकारी भरें:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _studentNameController,
              decoration: const InputDecoration(
                labelText: 'छात्र का नाम *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _schoolNameController,
              decoration: const InputDecoration(
                labelText: 'स्कूल का नाम *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.school),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedClass,
                    decoration: const InputDecoration(
                      labelText: 'कक्षा',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.class_),
                    ),
                    items: List.generate(12, (index) {
                      final classNumber = index + 1;
                      return DropdownMenuItem<String>(
                        value: classNumber.toString(),
                        child: Text('कक्षा $classNumber'),
                      );
                    }),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedClass = newValue;
                        // Update the controller for API compatibility
                        _classController.text = newValue ?? '';
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _dateController,
                    decoration: const InputDecoration(
                      labelText: 'दिनांक',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    onTap: () => _selectDate(context),
                    readOnly: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _previewCertificate,
                    icon: const Icon(Icons.preview),
                    label: const Text('प्रीव्यू देखें'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _generateCertificate,
                    icon: const Icon(Icons.download),
                    label: const Text('डाउनलोड करें'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  void _previewCertificate() async {
    if (_studentNameController.text.isEmpty ||
        _schoolNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('कृपया छात्र और स्कूल का नाम भरें'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final pdf = await _generatePDF();
    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

  void _generateCertificate() async {
    if (_studentNameController.text.isEmpty ||
        _schoolNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('कृपया छात्र और स्कूल का नाम भरें'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final pdf = await _generatePDF();
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Certificate_${_studentNameController.text}.pdf',
    );
  }

  Future<pw.Document> _generatePDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.green, width: 3),
            ),
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'हरिहर पाठशाला',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'प्रमाणपत्र',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.purple,
                  ),
                ),
                pw.SizedBox(height: 40),
                pw.Text(
                  'यह प्रमाणित किया जाता है कि',
                  style: const pw.TextStyle(fontSize: 16),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  _studentNameController.text,
                  style: pw.TextStyle(
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue,
                  ),
                ),
                pw.SizedBox(height: 20),
                if (_classController.text.isNotEmpty)
                  pw.Text(
                    'कक्षा: ${_classController.text}',
                    style: const pw.TextStyle(fontSize: 16),
                  ),
                pw.Text(
                  _schoolNameController.text,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 30),
                pw.Text(
                  'ने पर्यावरण संरक्षण में योगदान दिया है',
                  style: const pw.TextStyle(fontSize: 16),
                ),
                pw.SizedBox(height: 40),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      children: [
                        pw.Text('दिनांक: ${_dateController.text}'),
                        pw.SizedBox(height: 30),
                        pw.Container(
                          height: 1,
                          width: 150,
                          color: PdfColors.black,
                        ),
                        pw.Text('प्राधानाचार्य हस्ताक्षर'),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text('स्थान: ________________'),
                        pw.SizedBox(height: 30),
                        pw.Container(
                          height: 1,
                          width: 150,
                          color: PdfColors.black,
                        ),
                        pw.Text('शिक्षक हस्ताक्षर'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf;
  }
}

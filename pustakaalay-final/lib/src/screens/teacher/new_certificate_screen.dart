import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';

class NewCertificateScreen extends StatelessWidget {
  const NewCertificateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('नया सर्टिफिकेट'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => appState.goBackToHome(),
        ),
      ),
      body: const Center(
        child: Text(
          'नया सर्टिफिकेट स्क्रीन\n(जल्द ही उपलब्ध)',
          style: TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class AddWaterScreen extends StatelessWidget {
  const AddWaterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Water'),
      ),
      body: const Center(
        child: Text(
          'Add Water Screen Placeholder',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

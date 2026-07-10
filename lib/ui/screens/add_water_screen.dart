import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/providers/hydrio_provider.dart';

class AddWaterScreen extends StatefulWidget {
  const AddWaterScreen({super.key});

  @override
  State<AddWaterScreen> createState() => _AddWaterScreenState();
}

class _AddWaterScreenState extends State<AddWaterScreen> {
  late int _selectedAmountMl;
  bool _isCustomSelected = false;
  bool _debounceLock = false;
  final TextEditingController _customController = TextEditingController();
  String? _validationError;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<HydrioProvider>(context, listen: false);
    _selectedAmountMl = provider.settings.cupSizeMl;
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  // Logs a preset immediately and pops
  Future<void> _logPreset(HydrioProvider provider, int amountMl) async {
    if (_debounceLock) return;
    setState(() {
      _debounceLock = true;
      _selectedAmountMl = amountMl;
    });
    
    await provider.logDrink(amountMl);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logged ${provider.formatVolume(amountMl)} of water! 💧'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  void _onCustomInputChanged(String text, HydrioProvider provider) {
    if (text.isEmpty) {
      setState(() {
        _validationError = 'Please enter an amount';
        _selectedAmountMl = 0;
      });
      return;
    }

    final isOz = provider.settings.unit == 'oz';
    final parsed = double.tryParse(text);
    if (parsed == null || parsed <= 0) {
      setState(() {
        _validationError = 'Please enter a positive number';
        _selectedAmountMl = 0;
      });
      return;
    }

    int amountMl;
    if (isOz) {
      amountMl = provider.toMl(parsed);
    } else {
      amountMl = parsed.round();
    }

    // Limit checks: 1 to 2000 ml
    if (amountMl < 1 || amountMl > 2000) {
      final unitLabel = provider.unitSuffix;
      final maxDisplay = isOz ? provider.toOz(2000).toStringAsFixed(1) : '2000';
      final minDisplay = isOz ? provider.toOz(1).toStringAsFixed(2) : '1';
      setState(() {
        _validationError = 'Amount must be between $minDisplay and $maxDisplay $unitLabel';
        _selectedAmountMl = 0;
      });
    } else {
      setState(() {
        _validationError = null;
        _selectedAmountMl = amountMl;
      });
    }
  }

  Future<void> _submitCustom(HydrioProvider provider) async {
    if (_validationError != null || _selectedAmountMl <= 0) return;
    
    if (_debounceLock) return;
    setState(() {
      _debounceLock = true;
    });

    await provider.logDrink(_selectedAmountMl);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logged ${provider.formatVolume(_selectedAmountMl)} of water! 💧'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<HydrioProvider>();
    final isOz = provider.settings.unit == 'oz';
    final isDark = theme.brightness == Brightness.dark;

    // Presets in mL
    final List<Map<String, dynamic>> presets = [
      {'label': '100 mL', 'ml': 100, 'icon': Icons.local_cafe},
      {'label': '200 mL', 'ml': 200, 'icon': Icons.local_cafe},
      {'label': '250 mL', 'ml': 250, 'icon': Icons.local_cafe},
      {'label': '500 mL', 'ml': 500, 'icon': Icons.local_drink},
      {'label': 'Bottle', 'ml': 750, 'icon': Icons.local_drink},
    ];

    // Determine custom text labels
    final unitLabel = provider.unitSuffix;
    final hintText = isOz ? 'Enter fl oz' : 'Enter mL';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Water',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Description
                Center(
                  child: Text(
                    'How much did you drink?',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Live Amount Display Container
                Center(
                  child: Container(
                    width: double.infinity,
                    height: 100,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xff173448) : const Color(0xffD6ECFB),
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Text(
                      _selectedAmountMl > 0
                          ? provider.formatVolume(_selectedAmountMl)
                          : '0 $unitLabel',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Presets Title
                Text(
                  'Choose a size',
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                // Presets Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.8,
                  ),
                  itemCount: presets.length + 1, // +1 for Custom chip
                  itemBuilder: (context, index) {
                    if (index < presets.length) {
                      final preset = presets[index];
                      final amountMl = preset['ml'] as int;
                      final icon = preset['icon'] as IconData;
                      
                      // Convert preset label string if isOz
                      String displayLabel;
                      if (isOz) {
                        displayLabel = '${provider.toOz(amountMl).toStringAsFixed(1)} oz';
                      } else {
                        displayLabel = preset['label'] as String;
                      }

                      final isSelected = !_isCustomSelected && _selectedAmountMl == amountMl;

                      return _PresetChip(
                        label: displayLabel,
                        icon: icon,
                        isSelected: isSelected,
                        onTap: () => _logPreset(provider, amountMl),
                      );
                    } else {
                      // Custom chip
                      return _PresetChip(
                        label: 'Custom',
                        icon: Icons.edit,
                        isSelected: _isCustomSelected,
                        onTap: () {
                          setState(() {
                            _isCustomSelected = true;
                            _selectedAmountMl = 0;
                            _validationError = 'Please enter an amount';
                          });
                          _customController.clear();
                        },
                      );
                    }
                  },
                ),
                const SizedBox(height: 24),
                // Conditional Custom Input Field
                if (_isCustomSelected) ...[
                  Text(
                    'Custom amount ($unitLabel)',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _customController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    onChanged: (text) => _onCustomInputChanged(text, provider),
                    decoration: InputDecoration(
                      hintText: hintText,
                      errorText: _validationError,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Primary Confirm Button (only active/visible when custom input is valid)
                  ElevatedButton(
                    onPressed: (_validationError == null && _selectedAmountMl > 0)
                        ? () => _submitCustom(provider)
                        : null,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.brightness == Brightness.dark 
                          ? Colors.black 
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                    ),
                    child: const Text(
                      'Add',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isSelected
        ? (isDark ? const Color(0xff173448) : const Color(0xffD6ECFB))
        : (isDark ? const Color(0xff1B2430) : const Color(0xffF2F5F8));

    final textColor = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

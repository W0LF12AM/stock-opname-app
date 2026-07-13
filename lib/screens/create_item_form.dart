import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sync_provider.dart';
import '../models/adjustment.dart';

class CreateItemForm extends StatefulWidget {
  final int vesselId;
  const CreateItemForm({super.key, required this.vesselId});

  @override
  State<CreateItemForm> createState() => _CreateItemFormState();
}

class _CreateItemFormState extends State<CreateItemForm> {
  final _formKey = GlobalKey<FormState>();
  final _partNameController = TextEditingController();
  final _partNumberController = TextEditingController();
  final _satuanController = TextEditingController(text: 'PCS');
  final _qtyController = TextEditingController(text: '0');
  final _priceController = TextEditingController(text: '0');
  final _keteranganController = TextEditingController();

  // For adding new components offline
  final _newMainController = TextEditingController();
  final _newSubController = TextEditingController();
  bool _isCreatingNewMain = false;
  bool _isCreatingNewSub = false;

  int? _selectedMainId;
  int? _selectedSubId;

  @override
  void dispose() {
    _partNameController.dispose();
    _partNumberController.dispose();
    _satuanController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    _keteranganController.dispose();
    _newMainController.dispose();
    _newSubController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final sync = context.read<SyncProvider>();
    final double qty = double.parse(_qtyController.text);
    final double price = double.tryParse(_priceController.text) ?? 0.0;

    final String? newMain = _isCreatingNewMain ? _newMainController.text.trim() : null;
    final String? newSub = (_isCreatingNewMain || _isCreatingNewSub)
        ? (_newSubController.text.trim().isNotEmpty ? _newSubController.text.trim() : null)
        : null;

    final newAdj = Adjustment(
      vesselId: widget.vesselId,
      isExisting: false,
      qtyChange: qty, // delta is the initial count since it starts at 0
      physicalQty: qty,
      hargaSatuan: price,
      keterangan: _keteranganController.text,
      partName: _partNameController.text.trim(),
      partNumber: _partNumberController.text.trim().isNotEmpty ? _partNumberController.text.trim() : null,
      satuan: _satuanController.text.trim(),
      mainComponentId: _isCreatingNewMain ? 0 : (_selectedMainId ?? 0),
      subComponentId: (_isCreatingNewMain || _isCreatingNewSub) ? null : _selectedSubId,
      newMainComponent: newMain,
      newSubComponent: newSub,
    );

    sync.saveAdjustment(newAdj).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item baru disimpan secara lokal'),
          backgroundColor: Color(0xFF2E7D32), // Green CTA
        ),
      );
      Navigator.pop(context);
    }).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan: ${e.toString()}'),
          backgroundColor: const Color(0xFFC62828),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Tambah Item Baru'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informasi Barang',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Part Name field
                      TextFormField(
                        controller: _partNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Barang (Part Name) *',
                          prefixIcon: Icon(Icons.shopping_bag_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama barang wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Part Number field
                      TextFormField(
                        controller: _partNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Part Number (Opsional)',
                          prefixIcon: Icon(Icons.tag_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Satuan / Unit field
                      TextFormField(
                        controller: _satuanController,
                        decoration: const InputDecoration(
                          labelText: 'Satuan (Unit) *',
                          prefixIcon: Icon(Icons.line_weight_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Satuan wajib diisi (Contoh: PCS, SET)';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Category/Component card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Komponen & Kategori',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Main Component dropdown
                      DropdownButtonFormField<int>(
                        value: _selectedMainId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Komponen Utama *',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: [
                          ...sync.mainComponents.map((main) {
                            return DropdownMenuItem<int>(
                              value: main.id,
                              child: Text(
                                main.componentName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                          const DropdownMenuItem<int>(
                            value: -1,
                            child: Text(
                              '[+] Tambah Komponen Utama Baru',
                              style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        validator: (value) {
                          if (value == null) {
                            return 'Komponen Utama wajib dipilih';
                          }
                          return null;
                        },
                        onChanged: (val) {
                          setState(() {
                            _selectedMainId = val;
                            _isCreatingNewMain = (val == -1);
                            _selectedSubId = null;
                            _isCreatingNewSub = false;
                            _newMainController.clear();
                            _newSubController.clear();
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      if (_isCreatingNewMain) ...[
                        // Input for new Main Component name
                        TextFormField(
                          controller: _newMainController,
                          decoration: const InputDecoration(
                            labelText: 'Nama Komponen Utama Baru *',
                            prefixIcon: Icon(Icons.add_box_outlined),
                          ),
                          validator: (value) {
                            if (_isCreatingNewMain && (value == null || value.trim().isEmpty)) {
                              return 'Nama komponen utama baru wajib diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Input for new Sub Component name (Optional)
                        TextFormField(
                          controller: _newSubController,
                          decoration: const InputDecoration(
                            labelText: 'Nama Sub Komponen Baru (Opsional)',
                            prefixIcon: Icon(Icons.add_box_outlined),
                          ),
                        ),
                      ] else ...[
                        // Sub Component dropdown (only when main component is selected and not new)
                        DropdownButtonFormField<int>(
                          value: _selectedSubId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Sub Komponen (Opsional)',
                            prefixIcon: Icon(Icons.account_tree_outlined),
                          ),
                          items: _selectedMainId == null
                              ? []
                              : [
                                  ...sync.subComponents
                                      .where((sub) => sub.mainComponentId == _selectedMainId)
                                      .map((sub) {
                                    return DropdownMenuItem<int>(
                                      value: sub.id,
                                      child: Text(
                                        sub.subComponentName,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }),
                                  const DropdownMenuItem<int>(
                                    value: -1,
                                    child: Text(
                                      '[+] Tambah Sub Komponen Baru',
                                      style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                          onChanged: _selectedMainId == null
                              ? null
                              : (val) {
                                  setState(() {
                                    _selectedSubId = val;
                                    _isCreatingNewSub = (val == -1);
                                    _newSubController.clear();
                                  });
                                },
                        ),
                        const SizedBox(height: 12),

                        if (_isCreatingNewSub) ...[
                          // Input for new Sub Component name
                          TextFormField(
                            controller: _newSubController,
                            decoration: const InputDecoration(
                              labelText: 'Nama Sub Komponen Baru *',
                              prefixIcon: Icon(Icons.add_box_outlined),
                            ),
                            validator: (value) {
                              if (_isCreatingNewSub && (value == null || value.trim().isEmpty)) {
                                return 'Nama sub komponen baru wajib diisi';
                              }
                              return null;
                            },
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Count & Price Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hasil Perhitungan Fisik',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Qty counted
                      TextFormField(
                        controller: _qtyController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Jumlah Fisik Ditemukan *',
                          prefixIcon: Icon(Icons.exposure_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Jumlah fisik wajib diisi';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Harus berupa angka valid';
                          }
                          if (double.parse(value) < 0) {
                            return 'Jumlah tidak boleh kurang dari 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Price field
                      TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Estimasi Harga Satuan (Opsional)',
                          prefixIcon: Icon(Icons.payments_outlined),
                          prefixText: 'Rp ',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return null;
                          if (double.tryParse(value) == null) {
                            return 'Harus berupa angka valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Remarks field
                      TextFormField(
                        controller: _keteranganController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Keterangan Tambahan',
                          prefixIcon: Icon(Icons.notes_rounded),
                          hintText: 'Misal: Ditemukan di laci darurat...',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button (Green CTA)
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32), // Green CTA for saving
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save_rounded, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Simpan Item & Stok'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              // Cancel Button (Red CTA or default back)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Color(0xFFC62828), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

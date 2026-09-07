import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stock_opname_app/models/adjustment.dart';
import 'package:stock_opname_app/models/inventory_item.dart';
import 'package:stock_opname_app/providers/sync_provider.dart';
import 'package:stock_opname_app/services/api_service.dart';

class EditItem extends StatefulWidget {
  final InventoryItem item;
  final bool isNewItem;
  final Adjustment? existingAdj;

  const EditItem({
    super.key,
    required this.item,
    required this.isNewItem,
    this.existingAdj,
  });

  @override
  State<EditItem> createState() => _EditItemState();
}

class _EditItemState extends State<EditItem> {
  final _formKey = GlobalKey<FormState>();

  final _partNameController = TextEditingController();
  final _partNumberController = TextEditingController();
  final _satuanController = TextEditingController();
  final _priceController = TextEditingController();

  int? _selectedMainId;
  int? _selectedSubId;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _partNameController.text = widget.item.partName;
    _partNumberController.text = widget.item.partNumber ?? '';
    _satuanController.text = widget.item.satuan;
    _priceController.text = widget.item.price.toStringAsFixed(0);

    _selectedMainId = widget.item.mainComponentId;
    _selectedSubId = widget.item.subComponentId;
  }

  @override
  void dispose() {
    _partNameController.dispose();
    _partNumberController.dispose();
    _satuanController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submitEdit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final sync = context.read<SyncProvider>();

    try {
      if (widget.isNewItem) {
        if (widget.existingAdj?.id != null) {
          await sync.deleteAdjustment(
            widget.existingAdj!.id!,
            widget.item.vesselId,
          );
        }
        final updateAdj = Adjustment(
          vesselId: widget.item.vesselId,
          isExisting: false,
          qtyChange: widget.existingAdj?.qtyChange ?? 0,
          physicalQty: widget.existingAdj?.physicalQty ?? 0,
          hargaSatuan: double.tryParse(_priceController.text) ?? 0,
          keterangan: widget.existingAdj?.keterangan ?? '',
          partName: _partNameController.text,
          partNumber: _partNumberController.text.trim().isNotEmpty
              ? _partNumberController.text.trim()
              : null,
          satuan: _satuanController.text.trim(),
          mainComponentId: _selectedMainId ?? widget.item.mainComponentId,
          subComponentId: _selectedSubId,
        );
        await sync.saveAdjustment(updateAdj);
      } else {
        final api = APIService();
        await api.editItem(
          inventoryId: widget.item.id,
          vesselId: widget.item.vesselId,
          partName: _partNameController.text.trim(),
          partNumber: _partNumberController.text.trim().isNotEmpty
              ? _partNumberController.text.trim()
              : null,
          satuan: _satuanController.text.trim(),
          price: double.tryParse(_priceController.text) ?? widget.item.price,
          mainComponentId: _selectedMainId ?? widget.item.mainComponentId,
          subComponentId: _selectedSubId,
        );
        await sync.loadVesselWorkspace(widget.item.vesselId);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Item berhasil disimpan')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: ${e.toString()}'),
            backgroundColor: const Color(0xFFC62828),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNewItem ? 'Edit Item Lokal' : 'Edit Item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _partNameController,
                decoration: const InputDecoration(labelText: 'Nama Item'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama item wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _partNumberController,
                decoration: const InputDecoration(labelText: 'Nomor Part'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama item wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _satuanController,
                decoration: const InputDecoration(labelText: 'Satuan'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama item wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Harga'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama item wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSaving ? null : _submitEdit,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

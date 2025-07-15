import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class EditProductScreen extends StatefulWidget {
  final String productKey;
  final Map<String, dynamic> productData;

  const EditProductScreen({
    super.key,
    required this.productKey,
    required this.productData,
  });

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descController;
  late TextEditingController _brandController;
  late TextEditingController _modelController;
  late TextEditingController _yearController;

  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref(
    "products",
  );

  late int _originalPrice;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.productData['name']);
    _priceController = TextEditingController(text: widget.productData['price']);
    _descController = TextEditingController(text: widget.productData['desc']);
    _brandController = TextEditingController(
      text: widget.productData['brand'] ?? '',
    );
    _modelController = TextEditingController(
      text: widget.productData['model'] ?? '',
    );
    _yearController = TextEditingController(
      text: widget.productData['year'] ?? '',
    );

    _originalPrice =
        int.tryParse(
          widget.productData['price'].toString().replaceAll(
            RegExp(r'[^0-9]'),
            '',
          ),
        ) ??
        0;
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final int newPrice =
          int.tryParse(
            _priceController.text.trim().replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          _originalPrice;

      final updatedProduct = {
        "name": _nameController.text.trim(),
        "price": _priceController.text.trim(),
        "desc": _descController.text.trim(),
        "brand": _brandController.text.trim(),
        "model": _modelController.text.trim(),
        "year": _yearController.text.trim(),
        "image": widget.productData['image'],
        "uid": widget.productData['uid'],
        "tag": (newPrice < _originalPrice)
            ? "price_drop"
            : (widget.productData['tag'] ?? ""),
      };

      await _databaseRef.child(widget.productKey).update(updatedProduct);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Product")),
      backgroundColor: const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Product Name"),
                validator: (v) => v!.isEmpty ? "Enter product name" : null,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: "Price"),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Enter price" : null,
              ),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: "Description"),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? "Enter description" : null,
              ),
              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(labelText: "Brand"),
                validator: (v) => v!.isEmpty ? "Enter brand" : null,
              ),
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(labelText: "Model"),
                validator: (v) => v!.isEmpty ? "Enter model" : null,
              ),
              TextFormField(
                controller: _yearController,
                decoration: const InputDecoration(labelText: "Year"),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Enter year" : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFF500),
                  foregroundColor: Colors.black,
                ),
                child: const Text("Save Changes"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

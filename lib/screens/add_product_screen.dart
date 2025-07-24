import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _databaseRef = FirebaseDatabase.instance.ref().child("products");

  File? _selectedImage;
  bool _uploading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<String> _uploadImage(File file, String productId) async {
    final storageRef = FirebaseStorage.instance.ref().child(
      'product_images/$productId.jpg',
    );
    await storageRef.putFile(file);
    return await storageRef.getDownloadURL();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a product image.")),
      );
      return;
    }

    setState(() => _uploading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final newProductRef = _databaseRef.push();
      final productId = newProductRef.key!;

      final imageUrl = await _uploadImage(_selectedImage!, productId);

      final newProduct = {
        "id": productId,
        "name": _nameController.text.trim(),
        "price": _priceController.text.trim(),
        "desc": _descController.text.trim(),
        "brand": _brandController.text.trim(),
        "model": _modelController.text.trim(),
        "year": _yearController.text.trim(),
        "image": imageUrl,
        "uid": user?.uid ?? "unknown",
      };

      await newProductRef.set(newProduct);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product added successfully!")),
      );
      _formKey.currentState!.reset();
      _nameController.clear();
      _priceController.clear();
      _descController.clear();
      _brandController.clear();
      _modelController.clear();
      _yearController.clear();
      setState(() {
        _selectedImage = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    } finally {
      setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("List Your Product"),
        backgroundColor: const Color(0xFFFFF500),
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: _selectedImage != null
                    ? Image.file(
                        _selectedImage!,
                        height: 200,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Center(child: Text("Tap to select image")),
                      ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Product Name"),
                validator: (value) =>
                    value!.isEmpty ? "Please enter product name" : null,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: "Price"),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? "Please enter price" : null,
              ),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: "Description"),
                maxLines: 3,
                validator: (value) =>
                    value!.isEmpty ? "Please enter description" : null,
              ),
              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(labelText: "Brand"),
                validator: (value) =>
                    value!.isEmpty ? "Please enter brand" : null,
              ),
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(labelText: "Model"),
                validator: (value) =>
                    value!.isEmpty ? "Please enter model" : null,
              ),
              TextFormField(
                controller: _yearController,
                decoration: const InputDecoration(labelText: "Year"),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? "Please enter year" : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _uploading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFF500),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _uploading
                    ? const CircularProgressIndicator()
                    : const Text("Submit Product"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

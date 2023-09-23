import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shop_app/models/grocery_item.dart';

import '../data/categories.dart';
import '../models/category.dart';

class NewItem extends StatefulWidget {
  const NewItem({Key? key}) : super(key: key);

  @override
  State<NewItem> createState() => _NewItemState();
}

class _NewItemState extends State<NewItem> {
  final _formKey = GlobalKey<FormState>();
  var _enteredName = '';
  int _enteredQuantity = 0;
  Category _selectedCategory = categories[Categories.fruit]!;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add new title',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                maxLength: 50,
                onSaved: (newValue) {
                  _enteredName = newValue!;
                },
                decoration: const InputDecoration(
                  labelText: 'Name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty || value.trim().length <= 1 || value.trim().length > 50) {
                    return 'must be between 1 and 50 characters';
                  }
                  return null;
                },
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: '1',
                      keyboardType: TextInputType.number,
                      onSaved: (newValue) {
                        _enteredQuantity = int.parse(newValue!);
                      },
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty || int.tryParse(value) == null || int.tryParse(value)! <= 0) {
                          return 'must be a valid , positive number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField(
                      value: _selectedCategory,
                      items: [
                        for (final category in categories.entries)
                          DropdownMenuItem(
                              value: category.value,
                              child: Row(
                                children: [
                                  Container(
                                    height: 15,
                                    width: 15,
                                    color: category.value.color,
                                  ),
                                  const SizedBox(
                                    width: 7,
                                  ),
                                  Text(category.value.title),
                                ],
                              ))
                      ],
                      onChanged: (Category? value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                  )
                ],
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null :() {
                      _formKey.currentState!.reset();
                    },
                    child: const Text('Reset'),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null :() {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        setState(() {
                          _isLoading = true;
                        });
                        //final Uri url = Uri.parse('https://shop-app-4c739-default-rtdb.firebaseio.com/shopping-list.json');
                        final Uri url = Uri.https('shop-app-4c739-default-rtdb.firebaseio.com', 'shopping-list.json');
                        http.post(
                          url,
                          headers: {
                            'Content-Type': 'application/json',
                          },
                          body: json.encode({
                            'name': _enteredName,
                            'quantity': _enteredQuantity,
                            'category': _selectedCategory.title,
                          }),
                        ).then((response) {
                          final Map<String, dynamic> responseData = json.decode(response.body);
                          if (response.statusCode == 200) {
                            Navigator.of(context).pop(
                              GroceryItem(
                                  id: responseData['name'],
                                  name: _enteredName,
                                  quantity: _enteredQuantity,
                                  category: _selectedCategory,
                              ),
                            );
                          }
                        });
                      }
                    },
                    child: _isLoading
                        ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(),)
                        : const Text('Add Item'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

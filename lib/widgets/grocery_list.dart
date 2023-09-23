import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:shop_app/data/categories.dart';
import 'package:shop_app/models/grocery_item.dart';
import 'package:http/http.dart' as http;

import '../models/category.dart';
import '../widgets/new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({Key? key}) : super(key: key);

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  bool _isLoading = true;
  String? _error;

  void _loadData() async {
    final Uri url = Uri.https('shop-app-4c739-default-rtdb.firebaseio.com', 'shopping-list.json');

    final response = await http.get(url).catchError((_) {
      return http.Response('', 400);
    });
    if (response.statusCode >= 400) {
      setState(() {
        _error = 'Failed to fetch data ,please try again later';
      });
      log(_error!);
      return;
    }
    if (response.body == 'null') {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    log(response.body);
    final Map<String, dynamic> loadedData = json.decode(response.body);
    final List<GroceryItem> loadedItems = [];

    for (var item in loadedData.entries) {
      final Category category =
          categories.entries.firstWhere((element) => element.value.title == item.value['category']).value;
      loadedItems.add(
        GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category,
        ),
      );

      setState(() {
        _groceryItems = loadedItems;
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text(
          'Your Grocery',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(
              Icons.add,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: _error != null
          ? Center(
              child: Text(
              _error!,
              style: const TextStyle(fontSize: 20),
            ))
          : _isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : _groceryItems.isNotEmpty
                  ? ListView.builder(
                      itemCount: _groceryItems.length,
                      itemBuilder: (context, index) => Dismissible(
                        key: ValueKey(_groceryItems[index].id),
                        onDismissed: (_) {
                          _removeItem(_groceryItems[index]);
                        },
                        child: ListTile(
                          title: Text(
                            _groceryItems[index].name,
                          ),
                          leading: Container(
                            height: 22,
                            width: 22,
                            color: _groceryItems[index].category.color,
                          ),
                          trailing: Text(_groceryItems[index].quantity.toString()),
                        ),
                      ),
                    )
                  : const Center(
                      child: Text(
                        'No Items add yet',
                        style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                      ),
                    ),
    );
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });

    final Uri url = Uri.https('shop-app-4c739-default-rtdb.firebaseio.com', 'shopping-list/${item.id}.json');
    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('We could not delete item'),
        ),
      );
      setState(() {
        _groceryItems.insert(index, item);
      });
    }
  }

  _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(MaterialPageRoute(builder: (context) => const NewItem()));
    if (newItem == null) {
      return;
    }
    setState(() {
      _groceryItems.add(newItem);
    });
  }
}

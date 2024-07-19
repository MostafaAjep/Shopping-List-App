// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shopping_app/data/categories.dart';
import 'package:shopping_app/models/grocery_item.dart';
import 'package:shopping_app/pages/new_item_page.dart';
import 'package:http/http.dart' as http;

class GroceryListPage extends StatefulWidget {
  const GroceryListPage({super.key});

  @override
  State<GroceryListPage> createState() => _GroceryListPageState();
}

class _GroceryListPageState extends State<GroceryListPage> {
  List<GroceryItem> _groceryItems = [];
  int? _deletedItemIndex;
  GroceryItem? _deletedItem;
  late Future<List<GroceryItem>> loadeditems;
  String tabs = '\t' * 7;
  String? error;

  @override
  void initState() {
    super.initState();
    loadeditems = loadItems();
  }

  Future<List<GroceryItem>> loadItems() async {
    final url = Uri.https(
        'flutter-new-be519-default-rtdb.firebaseio.com', 'shopping-app.json');
    final response = await http.get(url);

    // throw Exception('An error occurred');

    //  handling Error of fetching data
    if (response.statusCode >= 400) {
      throw Exception('Failed to fetch data. please try again later');
    }
    if (response.body == 'null') {
      return [];
    }
    final Map<String, dynamic> listData = json.decode(response.body);
    final List<GroceryItem> loadedItems = [];
    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere(
              (catItem) => catItem.value.title == item.value['category'])
          .value;
      loadedItems.add(
        GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category,
        ),
      );
    }
    return loadedItems;
  }

  void addItem() async {
    final newItem = await Navigator.push<GroceryItem>(
      context,
      MaterialPageRoute(
        builder: ((context) => const NewItemPage()),
      ),
    );

    if (newItem == null) {
      return;
    }
    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void removeItem(GroceryItem item, int index) async {
    setState(() {
      _groceryItems.remove(item);
      _deletedItem = item;
      _deletedItemIndex = index;
    });
    final url = Uri.https('flutter-new-be519-default-rtdb.firebaseio.com',
        'shopping-app/${item.id}.json');
    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.add(item);
        _deletedItemIndex = index;
        _deletedItem = null;
      });
    }
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Item deleted'),
      duration: const Duration(seconds: 2),
      action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            undoDelete();
          }),
    ));
  }

  void undoDelete() async {
    if (_deletedItem != null && _deletedItemIndex != null) {
      setState(() {
        _groceryItems.insert(_deletedItemIndex!, _deletedItem!);
      });
      final url = Uri.https('flutter-new-be519-default-rtdb.firebaseio.com',
          'shopping-app/${_deletedItem!.id}.json');
      await http.put(
        url,
        body: json.encode({
          'name': _deletedItem!.name,
          'quantity': _deletedItem!.quantity,
          'category': _deletedItem!.category.title,
        }),
      );
      _deletedItem = null;
      _deletedItemIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: IconButton(
              onPressed: addItem,
              icon: const Icon(Icons.add),
              color: Colors.white,
              iconSize: 28,
            ),
          ),
        ],
      ),
      body: FutureBuilder(
        future: loadeditems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: Text(
                    snapshot.error.toString(),
                    style: const TextStyle(
                        fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          }
          if (snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: Text(
                    '${tabs}Nothing here! \nTry adding some items.',
                    style: const TextStyle(
                        fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          }
          _groceryItems = snapshot.data!;
          return ListView.builder(
            itemBuilder: (ctx, index) => Dismissible(
              onDismissed: (direction) {
                removeItem(_groceryItems[index], index);
              },
              key: ValueKey(_groceryItems[index].id),
              child: ListTile(
                title: Text(_groceryItems[index].name),
                leading: Container(
                  width: 20,
                  height: 20,
                  color: _groceryItems[index].category.color,
                ),
                trailing: Text(
                  _groceryItems[index].quantity.toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            itemCount: _groceryItems.length,
          );
        },
      ),
    );
  }
}

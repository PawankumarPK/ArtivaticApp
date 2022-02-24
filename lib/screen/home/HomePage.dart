import 'dart:convert';
import 'package:flutter/material.dart';
import '../../apiService/url/Config.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  List<Map<String, dynamic>> _items = [];
  static List internetData = [];

  //creating a hive box
  final _postBox = Hive.box('posts_box');

  // TextFields' controllers
  final TextEditingController titleController = TextEditingController();
  final TextEditingController bodyController = TextEditingController();


  @override
  void initState() {
    super.initState();
    fetchApiData();
    _refreshItems(); // Load data when app starts
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artivatic App'),
      ),

      ///----------------- ListView builder with Floating button ---------------------
      body: _items.isEmpty
          ? const Center(
        child: CircularProgressIndicator()
      )
          : ListView.builder(
        // the list of items
          itemCount: _items.length,
          itemBuilder: (_, index) {
            final currentItem = _items[index];
            return Card(
              color: Colors.grey,
              margin: const EdgeInsets.all(10),
              elevation: 3,
              child: GestureDetector(
                onLongPress: (){
                  _deleteItem(currentItem['key']);
                },
                onTap: ()=>{ ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Long Press To delete')))
                }
                ,
                child: ListTile(
                    title: Text(currentItem['title']),
                    subtitle: Text(currentItem['body'].toString()),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete,color: Colors.black54,),
                          onPressed: () => _deleteItem(currentItem['key']),
                        ),
                      ],
                    )),
              ),
            );
          }),
      // Add new item button
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  ///----------------- fetch all item using internet ---------------------
  Future<bool> fetchApiData() async {
    var url = Config.BASE_URL;
    try {
      var response = await http.get(Uri.parse(url));
      var parsedJson = json.decode(response.body);
      internetData = parsedJson;
      for (int i = 0; i <= internetData.length; i++) {
        var title = parsedJson[i]['title'];
        var body = parsedJson[i]['body'];

        //After fetch & decode json add data to db
        _createItem({"title": title, "body": body});
      }
      return true;
    } catch (socketException) {
      print("No Internet");

    }
    return true;
  }

  ///----------------- Get all items from the database ---------------------
  void _refreshItems() {
    final data = _postBox.keys.map((key) {
      final value = _postBox.get(key);
      return {"key": key, "title": value["title"], "body": value['body']};
    }).toList();

    setState(() {
      _items = data.reversed.toList();
      // we use "reversed" to sort items in order from the latest to the oldest
    });
  }

  ///--------------------- Create new item -------------------------------
  Future<void> _createItem(Map<String, dynamic> newItem) async {
    await _postBox.add(newItem);
    _refreshItems(); // update the UI
  }

  ///------------------------ Delete a single item ---------------------
  Future<void> _deleteItem(int itemKey) async {
    await _postBox.delete(itemKey);
    _refreshItems(); // update the UI

    // Display a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An item has been deleted')));
  }

  ///-------- It will also be triggered when you want to update an item ---------
  void _showForm(BuildContext ctx, int? itemKey) async {
    // itemKey == null -> create new item
    // itemKey != null -> update an existing item

    if (itemKey != null) {
      final existingItem =
          _items.firstWhere((element) => element['key'] == itemKey);
      titleController.text = existingItem['title'];
      bodyController.text = existingItem['body'];
    }
    ///----- BottomSheet open when the floating button is pressed ------------
    showModalBottomSheet(
        context: ctx,
        elevation: 5,
        enableDrag: true,
        isScrollControlled: true,
        builder: (BuildContext context) => Container(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                  top: 15,
                  left: 15,
                  right: 15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(hintText: 'title'),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextField(
                    controller: bodyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'body'),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // Save new item
                      if (itemKey == null) {
                        _createItem({
                          "title": titleController.text,
                          "body": bodyController.text
                        });
                      }

                      // Clear the text fields
                      titleController.text = '';
                      bodyController.text = '';

                      Navigator.of(context).pop(); // Close the bottom sheet
                    },
                    child: Text(itemKey == null ? 'Create New' : 'Update'),
                  ),
                  const SizedBox(
                    height: 15,
                  )
                ],
              ),
            ));
  }
}

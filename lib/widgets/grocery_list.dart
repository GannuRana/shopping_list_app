import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shopping_app/data/categories.dart';
import 'package:shopping_app/models/grocery_item.dart';
import 'package:shopping_app/widgets/new_item.dart';
import 'package:http/http.dart' as http;
class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}


class _GroceryListState extends State<GroceryList> {

   List<GroceryItem> _groceryItem=[];
   var _isLoading=true;
  @override
  void initState() {
    super.initState();
    _loadItem();
  }
  void _loadItem()async{
    final url=Uri.https('flutter-prep-f6e97-default-rtdb.firebaseio.com','shopping-list.json');
    final response=await http.get(url);

    if(response.body=='null'){
      setState(() {
        _isLoading=false;
      });
      return;
    }
   final Map<String,dynamic> listData=json.decode(response.body);
   final List<GroceryItem> loadedItem=[];
   for(final item in listData.entries){
     final category=categories.entries.firstWhere((catItem) =>
     catItem.value.title==item.value['category']).value;
     loadedItem.add(GroceryItem(
         id: item.key,
         name: item.value['name'],
         quantity: item.value['quantity'],
         category: category,
     ),
     );
   }
   setState(() {
     _groceryItem=loadedItem;
     _isLoading=false;
   });
  }

  void _AddItem()async{
   final newItem=await Navigator.of(context)
        .push(MaterialPageRoute(
        builder: (context)=>NewItem(),
      ),
    );
   if(newItem==null){
     return ;
   }
   setState(() {
     _groceryItem.add(newItem);
   });
  }

void _removeItem(GroceryItem item)async{
    final index=_groceryItem.indexOf(item);
  setState(() {
    _groceryItem.remove(item);
  });
  final url=Uri.https('flutter-prep-f6e97-default-rtdb.firebaseio.com',
      'shopping-list/${item.id}.json'
  );
  final response= await http.delete(url);
  if(response.statusCode>=400){
    setState(() {
      _groceryItem.insert(index,item);
    });
  }
}


  @override
  Widget build(BuildContext context) {
    Widget content=const Center(child: Text('No items added yet'),);
    if(_isLoading){
      content=const Center(child: CircularProgressIndicator(),);
    }
    if(_groceryItem.isNotEmpty){
      content=ListView.builder(
        itemCount: _groceryItem.length,
        itemBuilder:  (context,index)=>Dismissible(
          onDismissed: (direction){
             _removeItem(_groceryItem[index]);
          },
          key: ValueKey(_groceryItem[index].id),
          child: ListTile(
            title: Text(_groceryItem[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryItem[index].category.color,
            ),
            trailing: Text(_groceryItem[index].quantity.toString()),
          ),
        ),
      );
    }
    return    Scaffold(
      appBar: AppBar(
        title: const Text(
          'Grocery Item',
        ),
        actions: [
          IconButton(
              onPressed: _AddItem,
              icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: content,
    );
  }
}

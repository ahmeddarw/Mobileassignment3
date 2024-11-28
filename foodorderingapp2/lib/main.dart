import 'package:flutter/material.dart';
import 'db_helper.dart';

void main() => runApp(FoodOrderingApp());

class FoodOrderingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Ordering App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
    );
  }
}
// home screen
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}
// intialize data
class _HomeScreenState extends State<HomeScreen> {
  final DBHelper _dbHelper = DBHelper();
  List<Map<String, dynamic>> _foodItems = [];
  List<Map<String, dynamic>> _selectedFoodItems = [];
  List<Map<String, dynamic>> _queriedPlans = [];
  TextEditingController _nameController = TextEditingController();
  TextEditingController _costController = TextEditingController();

  double _targetCost = 0.0;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadFoodItems();
  }
Future<void> _initializeData() async {
    final items = await _dbHelper.getFoodItems();  
    if (items.isEmpty) {
     //if the table is empty, insert deault items
      List<Map<String, dynamic>> defaultItems = [
        {'name': 'Pizza', 'cost': 12.0, 'selected': false},
        {'name': 'Burger', 'cost': 8.0, 'selected': false},
        {'name': 'Pasta', 'cost': 10.0, 'selected': false},
        {'name': 'Salad', 'cost': 6.0, 'selected': false},
        {'name': 'Sandwich', 'cost': 7.0, 'selected': false},
        {'name': 'Sushi', 'cost': 15.0, 'selected': false},
        {'name': 'Soup', 'cost': 5.0, 'selected': false},
        {'name': 'Steak', 'cost': 20.0, 'selected': false},
        {'name': 'Taco', 'cost': 9.0, 'selected': false},
        {'name': 'Burrito', 'cost': 10.0, 'selected': false},
        {'name': 'Hot Dog', 'cost': 6.0, 'selected': false},
        {'name': 'Fries', 'cost': 4.0, 'selected': false},
        {'name': 'Ice Cream', 'cost': 5.0, 'selected': false},
        {'name': 'Donut', 'cost': 3.0, 'selected': false},
        {'name': 'Cake', 'cost': 8.0, 'selected': false},
        {'name': 'Coffee', 'cost': 3.0, 'selected': false},
        {'name': 'Tea', 'cost': 2.0, 'selected': false},
        {'name': 'Juice', 'cost': 4.0, 'selected': false},
        {'name': 'Smoothie', 'cost': 6.0, 'selected': false},
        {'name': 'Milkshake', 'cost': 7.0, 'selected': false},
      ];
      for (var item in defaultItems) {
        await _dbHelper.insertFoodItem(item);
      }
    }
  }
  //load food items
  Future<void> _loadFoodItems() async {
    final items = await _dbHelper.getFoodItems();
    setState(() {
      _foodItems = items.map((item) => Map<String, dynamic>.from(item)).toList();
    });
  }
//add food items
Future<void> _addFoodItem(String name, double cost) async {
  await _dbHelper.insertFoodItem({'name': name, 'cost': cost, 'selected': false});
  await _loadFoodItems(); // Refresh food list after adding new items
}

//edit food items 
  Future<void> _editFoodItem(int id, String name, double cost) async {
    await _dbHelper.updateFoodItem(id, {'name': name, 'cost': cost});
    _loadFoodItems();
  }
//delete food items 
  Future<void> _deleteFoodItem(int id) async {
    await _dbHelper.deleteFoodItem(id);
    _loadFoodItems();
  }
//save order plans
  Future<void> _saveOrderPlan() async {
    if (_selectedDate == null || _selectedFoodItems.isEmpty || _targetCost <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please complete all fields.')),
      );
      return;
    }
  //get items names
    final itemNames = _selectedFoodItems.map((item) => item['name']).join(', ');
  //save order plan
    await _dbHelper.insertOrderPlan({
      'date': _selectedDate!.toIso8601String(),
      'items': itemNames,
      'target_cost': _targetCost,
    });
//show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order Plan Saved!')),
    );

    setState(() {
      _selectedFoodItems.clear();
      _selectedDate = null;
      _targetCost = 0.0;
    });
  }

  Future<void> _queryOrderPlans() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        //show select a date to query
        SnackBar(content: Text('Please select a date to query.')),
      );
      return;
    }
//get order plans
    final plans = await _dbHelper.getOrderPlans(_selectedDate!.toIso8601String());
    if (plans.isNotEmpty) {
      setState(() {
        _queriedPlans = plans;
      });
    } else {
      //show no order plan found
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No order plan found for the selected date.')),
      );
    }
  }
  //CRUD operations on UI
  void _showAddDialog() {
    _nameController.clear();
    _costController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _costController,
              decoration: InputDecoration(labelText: 'Cost'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = _nameController.text.trim();
              final cost = double.tryParse(_costController.text) ?? 0.0;
              if (name.isNotEmpty && cost > 0) {
                _addFoodItem(name, cost);
                Navigator.of(context).pop();
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }
  //edit items 
  void _showEditDialog(Map<String, dynamic> item) {
    _nameController.text = item['name'];
    _costController.text = item['cost'].toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _costController,
              decoration: InputDecoration(labelText: 'Cost'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = _nameController.text.trim();
              final cost = double.tryParse(_costController.text) ?? 0.0;
              if (name.isNotEmpty && cost > 0) {
                _editFoodItem(item['id'], name, cost);
                Navigator.of(context).pop();
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
  //frontend of the application
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Food Ordering App')),
      body: Column(
        children: [
          
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              decoration: InputDecoration(
                labelText: 'Target Cost per Day',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _targetCost = double.tryParse(value) ?? 0.0;
                });
              },
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () async {
                final selectedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (selectedDate != null) {
                  setState(() {
                    _selectedDate = selectedDate;
                  });
                }
              },
              child: Text(_selectedDate == null
                  ? 'Select Date'
                  : 'Selected: ${_selectedDate!.toLocal()}'.split(' ')[0]),
            ),
          ),
          
          ElevatedButton(
            onPressed: _showAddDialog,
            child: Text('Add New Item'),
          ),
          
          Expanded(
            child: ListView.builder(
              itemCount: _foodItems.length,
              itemBuilder: (context, index) {
                final item = _foodItems[index];
                return CheckboxListTile(
                  title: Row(
                    children: [
                      Expanded(child: Text('${item['name']} (\$${item['cost']})')),
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditDialog(item),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteFoodItem(item['id']),
                      ),
                    ],
                  ),
                  value: item['selected'] ?? false,
                  onChanged: (selected) {
                    setState(() {
                      final currentTotal = _selectedFoodItems.fold(
                          0.0, (sum, item) => sum + (item['cost'] as double));
                      final itemCost = item['cost'] as double;

                      if (selected == true) {
                        if (currentTotal + itemCost > _targetCost) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Cannot add item. Total cost exceeds the target!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return; // Prevent adding
                        }
                        _selectedFoodItems.add(item);
                        item['selected'] = true;
                      } else {
                        _selectedFoodItems.remove(item);
                        item['selected'] = false;
                      }
                    });
                  },
                );
              },
            ),
          ),
          // saving the order plan button
          ElevatedButton(
            onPressed: _saveOrderPlan,
            child: Text('Save Order Plan'),
          ),
          // query the order plan button
          ElevatedButton(
            onPressed: _queryOrderPlans,
            child: Text('Query Order Plan'),
          ),
          // Display food Plans created by the user
          Expanded(
            child: ListView.builder(
              itemCount: _queriedPlans.length,
              itemBuilder: (context, index) {
                final plan = _queriedPlans[index];
                return ListTile(
                  title: Text('Items: ${plan['items']}'),
                  subtitle: Text(
                    'Date: ${plan['date']} - Target Cost: \$${plan['target_cost']}',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}




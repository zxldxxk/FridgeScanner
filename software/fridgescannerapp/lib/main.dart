import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fridgescannerapp/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);  runApp(const MyApp());
}

class Item {
  final String id; // 👈 ADD THIS
  final String name;
  final String brand;
  final String barcode;
  final String quantity;
  final DateTime expiryDate;
  final DateTime? dateBought;

  Item({
    required this.id, // 👈 ADD
    required this.name,
    required this.brand,
    required this.barcode,
    required this.quantity,
    required this.expiryDate,
    this.dateBought,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'brand': brand,
      'barcode': barcode,
      'quantity': quantity,
      'expiryDate': expiryDate.toIso8601String(),
      'dateBought': dateBought?.toIso8601String(),
    };
  }

  factory Item.fromMap(String id, Map<String, dynamic> data) {
    return Item(
      id: id, // 👈 STORE KEY
      name: data['name'] ?? '',
      brand: data['brand'] ?? '',
      barcode: data['barcode'] ?? '',
      quantity: data['quantity'] ?? '',
      expiryDate: DateTime.parse(data['expiryDate']),
      dateBought: data['dateBought'] != null
          ? DateTime.parse(data['dateBought'])
          : null,
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fridge Scanner',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Item> items = [];
  List<Item> filteredItems = [];
  String searchQuery = "";
@override
void initState() {
  super.initState();

  dbRef.onValue.listen((event) {
    final start = DateTime.now();
    final data = event.snapshot.value;

    if (data == null) {
      setState(() => items = []);
      return;
    }

    final Map<dynamic, dynamic> map = data as Map;

    final List<Item> loadedItems = [];

map.forEach((key, value) {
  final itemMap = Map<String, dynamic>.from(value);
  loadedItems.add(Item.fromMap(key, itemMap));
});

    setState(() {
      items = loadedItems;
      filteredItems = loadedItems;
    });
    final end = DateTime.now();
    print("Data loaded in ${end.difference(start).inMilliseconds} ms");
    
  });
}

void searchItems(String query) {
  final results = items.where((item) {
    final nameLower = item.name.toLowerCase();
    final brandLower = item.brand.toLowerCase();
    final searchLower = query.toLowerCase();

    return nameLower.contains(searchLower) ||
        brandLower.contains(searchLower);
  }).toList();

  setState(() {
    searchQuery = query;
    filteredItems = results;
  });
}

  final DatabaseReference dbRef = FirebaseDatabase.instance.ref("fridgescanner");
  int daysSinceBought(DateTime dateBought) {
    return DateTime.now().difference(dateBought).inDays;
  }

  int daysUntilExpiry(DateTime expiryDate) {
    return expiryDate.difference(DateTime.now()).inDays;
  }
void addItem(String name, String brand, String barcode, String quantity, DateTime expiryDate) {
  final newRef = dbRef.push();

  final newItem = Item(
    id: newRef.key!, // 👈 IMPORTANT
    name: name,
    brand: brand,
    barcode: barcode,
    quantity: quantity,
    expiryDate: expiryDate,
    dateBought: DateTime.now(),
  );

  newRef.set(newItem.toMap());
}

void showAddItemDialog() {
  TextEditingController nameController = TextEditingController();
  TextEditingController brandController = TextEditingController();
  TextEditingController barcodeController = TextEditingController();
  TextEditingController quantityController = TextEditingController();

  DateTime? selectedDate;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Add Item"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Item name"),
              ),
              TextField(
                controller: brandController,
                decoration: const InputDecoration(labelText: "Brand"),
              ),

              TextField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: "Quantity"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 3)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    selectedDate = picked;
                  }
                },
                child: const Text("Select Expiry Date"),
              )
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  selectedDate != null) {

                addItem(
                  nameController.text,
                  brandController.text.isNotEmpty
                      ? brandController.text
                      : "Unknown",
                  barcodeController.text,
                  quantityController.text.isNotEmpty
                      ? quantityController.text
                      : "1",
                  selectedDate!,
                );

                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          )
        ],
      );
    },
  );
}

  Widget buildItemTile(Item item) {
int daysOld = item.dateBought != null
    ? daysSinceBought(item.dateBought!)
    : 0;
    int daysLeft = daysUntilExpiry(item.expiryDate);

    String status;
    Color color;

    if (daysLeft <= 1) {
      status = "Eat soon!";
      color = Colors.red;
    } else if (daysOld > 5) {
      status = "Old";
      color = Colors.orange;
    } else {
      status = "Fresh";
      color = Colors.green;
    }

    return Card(
      child: ListTile(
        title: Text(item.name),
        subtitle: Text(
          "Bought $daysOld days ago • Expires in $daysLeft days",
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            status,
            style: const TextStyle(color: Colors.white),
          ),
        ),

        onTap:() => showEditDialog(item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fridge Scanner"),
      ),
      body: Column(
  children: [
    Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        decoration: const InputDecoration(
          labelText: "Search items...",
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
        onChanged: searchItems,
      ),
    ),
    Expanded(
      child: filteredItems.isEmpty
          ? const Center(child: Text("No items found"))
          : ListView.builder(
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                return buildItemTile(filteredItems[index]);
              },
            ),
    ),
  ],
),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddItemDialog,
        child: const Icon(Icons.add),
      ),
      
    );
  }
  
void deleteItem(String id) {
    dbRef.child(id).remove();
  }

  void updateItem(Item item) {
    dbRef.child(item.id).update(item.toMap());
  }
void showEditDialog(Item item) {
  TextEditingController nameController =
      TextEditingController(text: item.name);
  TextEditingController quantityController =
      TextEditingController(text: item.quantity);

  DateTime selectedDate = item.expiryDate; 

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Edit Item"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Item name"),
            ),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(labelText: "Quantity"),
            ),
            const SizedBox(height: 10),

            // 👇 NEW BUTTON FOR EDITING DATE
            ElevatedButton(
              onPressed: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );

                if (picked != null) {
                  selectedDate = picked;
                }
              },
              child: const Text("Edit Expiry Date"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              deleteItem(item.id);
              Navigator.pop(context);
            },
            child: const Text("Delete",
                style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              final updatedItem = Item(
                id: item.id,
                name: nameController.text,
                brand: item.brand,
                barcode: item.barcode,
                quantity: quantityController.text,
                expiryDate: selectedDate,
                dateBought: item.dateBought,
              );

              updateItem(updatedItem);
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      );
    },
  );
}
}
import 'package:flutter/material.dart';
import '../database/model.dart';
import '../database/database_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// ignore: must_be_immutable
class ProductListScreen extends StatefulWidget {
  final DatabaseHelper dbHelper;

  const ProductListScreen({Key? key, required this.dbHelper}) : super(key: key);

  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Product> products = [];

  Future<bool?> _showConfirmDialog(BuildContext context, String message) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('จองคิวแม่บ้าน'), // Changed title
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: widget.dbHelper.getStream(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          products.clear();
          for (var element in snapshot.data!.docs) {
            var data = element.data() as Map<String, dynamic>;
            products.add(Product(
              name: element.get('name'),
              description: element.get('description'),
              favorite: element.get('favorite'),
              referenceId: element.id,
              contactnumber: data.containsKey('contactnumber')
                  ? data['contactnumber']
                  : '',
              address: data.containsKey('address') ? data['address'] : '',
              bookingTime:
                  data.containsKey('bookingTime') ? data['bookingTime'] : '',
            ));
          }

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              return Dismissible(
                key: UniqueKey(),
                background: Container(color: Colors.blue),
                secondaryBackground: Container(
                  color: Colors.red,
                  child: const Icon(Icons.delete),
                  alignment: Alignment.centerRight,
                ),
                onDismissed: (direction) {
                  if (direction == DismissDirection.endToStart) {
                    widget.dbHelper.deleteProduct(products[index]);
                  }
                },
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.endToStart) {
                    return await _showConfirmDialog(context,
                        'แน่ใจว่าจะลบการจองนี้?'); // Changed confirmation message
                  }
                  return false;
                },
                child: Card(
                  child: ListTile(
                    title: Text(products[index].name),
                    subtitle: Text(
                        'รายละเอียด: ${products[index].description.toString()}'),
                    contentPadding: const EdgeInsets.all(50),
                    trailing: products[index].favorite == 1
                        ? const Icon(Icons.build, color: Colors.green)
                        : null,
                    onTap: () async {
                      var result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DetailScreen(productdetail: products[index]),
                        ),
                      );
                      setState(() {
                        if (result != null) {
                          products[index].favorite = result;
                          widget.dbHelper.updateProduct(products[index]);
                        }
                      });
                    },
                    onLongPress: () async {
                      await ModalEditProductForm(
                        dbHelper: widget.dbHelper,
                        editedProduct: products[index],
                      ).showModalInputForm(context);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await ModalProductForm(dbHelper: widget.dbHelper)
              .showModalInputForm(context);
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.orange, // Customize the color
      ),
    );
  }
}

class DetailScreen extends StatelessWidget {
  const DetailScreen({Key? key, required this.productdetail}) : super(key: key);

  final Product productdetail;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(productdetail.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(
                  left: 10, top: 20.0), // Adjust top padding as needed
              child: Text(
                'เรื่องจอง: ${productdetail.name}', // Updated label
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(
                  left: 10, top: 20.0), // Adjust top padding as needed
              child: Text(
                'รายละเอียด: ${productdetail.description}', // Updated label
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(
                  left: 10, top: 20.0), // Adjust top padding as needed
              child: Text(
                'ที่อยู่: ${productdetail.address}', // Updated label
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(
                  left: 10, top: 20.0), // Adjust top padding as needed
              child: Text(
                'เบอร์โทร: ${productdetail.contactnumber}', // Updated label
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(
                left: 10,
                top: 20.0,
              ),
              child: Text(
                'เวลาการจอง: ${productdetail.bookingTime}', // New label for booking time
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.only(top: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    child: const Text('Close'),
                    style: ElevatedButton.styleFrom(
                      fixedSize: const Size(120, 40),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20), // Add spacing at the bottom
          ],
        ),
      ),
    );
  }
}

class ModalProductForm {
  ModalProductForm({Key? key, required this.dbHelper});
  final DatabaseHelper dbHelper;

  String _name = '', _description = '';
  String _address = '';
  String _contactnumber = '';
  final int _favorite = 0;
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      _selectedDate = picked;
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      _selectedTime = picked;
    }
  }

  Future<dynamic> showModalInputForm(BuildContext context) {
    return showModalBottomSheet(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          height: 700, // Set desired height
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: IconButton(
                  icon: Icon(Icons.close, color: Colors.orange),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                title: const Center(
                  child: Text(
                    'จองคิวแม่บ้าน', // Changed title
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
                trailing: TextButton(
                  onPressed: () async {
                    if (_name.isEmpty || _description.isEmpty || _selectedDate == null || _selectedTime == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('กรุณากรอกข้อมูลให้ครบถ้วน'), // Error message
                        ),
                      );
                    } else {
                      await dbHelper.insertProduct(Product(
                        name: _name,
                        description: _description,
                        favorite: _favorite,
                        contactnumber: _contactnumber,
                        address: _address,
                        bookingTime: '${DateFormat('dd/MM/yyyy').format(_selectedDate!)} ${_selectedTime!.format(context)}',
                      ));
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('บันทึก', style: TextStyle(color: Colors.orange)), // Save button
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('กรอกข้อมูล'), // Input data title
                    TextField(
                      onChanged: (value) {
                        _name = value;
                      },
                      decoration: const InputDecoration(
                        hintText: 'ชื่อบริการ (เช่น ทำความสะอาด)',
                      ),
                    ),
                    TextField(
                      onChanged: (value) {
                        _description = value;
                      },
                      decoration: const InputDecoration(
                        hintText: 'รายละเอียด (เช่น ทำความสะอาดบ้าน)',
                      ),
                    ),
                    TextField(
                      onChanged: (value) {
                        _address = value;
                      },
                      decoration: const InputDecoration(
                        hintText: 'ที่อยู่',
                      ),
                    ),
                    TextField(
                      onChanged: (value) {
                        _contactnumber = value;
                      },
                      decoration: const InputDecoration(
                        hintText: 'เบอร์โทรศัพท์',
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text('เลือกวันและเวลา'), // Date and time selection title
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectDate(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Center(
                                child: Text(
                                  _selectedDate == null
                                      ? 'เลือกวันที่'
                                      : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectTime(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Center(
                                child: Text(
                                  _selectedTime == null
                                      ? 'เลือกเวลา'
                                      : _selectedTime!.format(context),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ModalEditProductForm {
  const ModalEditProductForm({Key? key, required this.dbHelper, required this.editedProduct});
  
  final DatabaseHelper dbHelper;
  final Product editedProduct;

  Future<dynamic> showModalInputForm(BuildContext context) {
    return showModalBottomSheet(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          height: 500, // Set desired height
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: IconButton(
                  icon: Icon(Icons.close, color: Colors.orange),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                title: const Center(
                  child: Text(
                    'แก้ไขข้อมูล', // Changed title
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
                trailing: TextButton(
                  onPressed: () async {
                    await dbHelper.updateProduct(editedProduct);
                    Navigator.pop(context);
                  },
                  child: const Text('บันทึก', style: TextStyle(color: Colors.orange)), // Save button
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      onChanged: (value) {
                        editedProduct.name = value;
                      },
                      decoration: InputDecoration(
                        hintText: 'ชื่อบริการ (เช่น ทำความสะอาด)',
                        labelText: 'ชื่อบริการ',
                        labelStyle: TextStyle(color: Colors.orange),
                      ),
                    ),
                    TextField(
                      onChanged: (value) {
                        editedProduct.description = value;
                      },
                      decoration: InputDecoration(
                        hintText: 'รายละเอียด (เช่น ทำความสะอาดบ้าน)',
                        labelText: 'รายละเอียด',
                        labelStyle: TextStyle(color: Colors.orange),
                      ),
                    ),
                    TextField(
                      onChanged: (value) {
                        editedProduct.address = value;
                      },
                      decoration: InputDecoration(
                        hintText: 'ที่อยู่',
                        labelText: 'ที่อยู่',
                        labelStyle: TextStyle(color: Colors.orange),
                      ),
                    ),
                    TextField(
                      onChanged: (value) {
                        editedProduct.contactnumber = value;
                      },
                      decoration: InputDecoration(
                        hintText: 'เบอร์โทรศัพท์',
                        labelText: 'เบอร์โทรศัพท์',
                        labelStyle: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}



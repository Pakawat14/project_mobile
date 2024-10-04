import 'package:flutter/material.dart';
import '../database/model.dart';
import '../database/database_helper.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
        title: const Text('จองคิวแม่บ้าน'),  // Changed title
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
      contactnumber: data.containsKey('contactnumber') ? data['contactnumber'] : '',
      address: data.containsKey('address') ? data['address'] : '',
       // Default to null if not found
      
        // Default to empty string if not found
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
                    return await _showConfirmDialog(context, 'แน่ใจว่าจะลบการจองนี้?');  // Changed confirmation message
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
    var result = productdetail.favorite;
    return Scaffold(
      appBar: AppBar(
        title: Text(productdetail.name),
      ),
      body: SingleChildScrollView(
        // Enclose content in SingleChildScrollView
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display uploaded image at the top if available
            if (productdetail.imagePath != null)
              Container(
                height: 300, // Set a height for the image
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: FileImage(File(productdetail.imagePath!)), // Load the image from file path
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(
                  left: 10, top: 20.0), // Adjust top padding as needed
              child: Text(
                'เรื่องจอง: ${productdetail.name}',  // Updated label
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(
                  left: 10, top: 20.0), // Adjust top padding as needed
              child: Text(
                'รายละเอียด: ${productdetail.description}',  // Updated label
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(
                  left: 10, top: 20.0), // Adjust top padding as needed
              child: Text(
                'ที่อยู่: ${productdetail.address}',  // Updated label
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            
           Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(
                  left: 10, top: 20.0), // Adjust top padding as needed
              child: Text(
                'เบอร์โทร: ${productdetail.contactnumber}',  // Updated label
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

  // Controllers for day, month, year, and time fields
  final TextEditingController _dayController = TextEditingController();
  final TextEditingController _monthController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  DateTime? _getSelectedDate() {
    try {
      int day = int.parse(_dayController.text);
      int month = int.parse(_monthController.text);
      int year = int.parse(_yearController.text);

      List<String> timeParts = _timeController.text.split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);

      return DateTime(year, month, day, hour, minute);
    } catch (e) {
      return null;
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
          height: 900, // Set desired height
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
                    'จองคิวแม่บ้าน',  // Changed title
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
                trailing: TextButton(
                  onPressed: () async {
                    DateTime? selectedDate = _getSelectedDate();
                    if (selectedDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('กรุณากรอกข้อมูลวันที่และเวลาให้ถูกต้อง'),
                        ),
                      );
                      return;
                    }

                    if (_name.isEmpty || _description.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('กรุณากรอกข้อมูลให้ครบถ้วน'),
                        ),
                      );
                      return;
                    }

                    await dbHelper.insertProduct(
                      Product(
                        name: _name,
                        description: _description,
                        favorite: _favorite,
                        contactnumber: _contactnumber,
                        address: _address,
                        
                        

                        
                        
                      ),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('บันทึก'),
                ),
              ),
              _buildInputField(
                context,
                'จองบริการ',  // Updated label
                'กรุณากรอกหัวข้อการจอง',
                (value) => _name = value,
              ),
              _buildInputField(
                context,
                'รายละเอียดการจอง',  // Updated label
                'กรุณากรอกรายละเอียดการจอง',
                (value) => _description = value,
              ),
              _buildInputField(
                context,
                'ที่อยู่',  // Updated label
                'กรุณากรอกรายละเอียดที่อยู่',
                (value) => _address = value,
              ),
              _buildInputField(
                context,
                'เบอร์โทร',  // Updated label
                'กรุณากรอกเบอร์โทร',
                (value) => _contactnumber = value,
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('เลือกวันและเวลา'),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _dayController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'วัน (เช่น 25)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _monthController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'เดือน (เช่น 12)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _yearController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'ปี (เช่น 2021)',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _timeController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'เวลา (เช่น 14:30)',
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

  Padding _buildInputField(BuildContext context, String labelText, String hintText, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          border: OutlineInputBorder(),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class ModalEditProductForm {
  final DatabaseHelper dbHelper;
  final Product editedProduct;

  ModalEditProductForm({required this.dbHelper, required this.editedProduct});

  Future<dynamic> showModalInputForm(BuildContext context) {
    final TextEditingController nameController =
        TextEditingController(text: editedProduct.name);
    final TextEditingController descriptionController =
        TextEditingController(text: editedProduct.description);

    return showModalBottomSheet(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          height: 600, // Set desired height
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
                    'แก้ไขข้อมูลการจอง',  // Updated title
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
                trailing: TextButton(
                  onPressed: () async {
                    final updatedProduct = Product(
                      name: nameController.text,
                      description: descriptionController.text,
                      favorite: editedProduct.favorite,
                      referenceId: editedProduct.referenceId,
                      contactnumber: editedProduct.contactnumber,
                      address: editedProduct.address,
                      


                      
                      
                      
                    );
                    await dbHelper.updateProduct(updatedProduct);
                    Navigator.pop(context);
                  },
                  child: const Text('บันทึก'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'หัวข้อการจอง',  // Updated label
                    hintText: 'กรุณากรอกหัวข้อการจอง',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'รายละเอียดการจอง',  // Updated label
                    hintText: 'กรุณากรอกรายละเอียดการจอง',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}



class ServiceSelectionScreen extends StatelessWidget {
  final List<String> services = ['ทำความสะอาดทั่วไป', 'ทำความสะอาดลึก', 'บริการเสริม'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เลือกบริการแม่บ้าน')),
      body: ListView.builder(
        itemCount: services.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(services[index]),
            onTap: () {
              // Logic to proceed with booking the selected service
            },
          );
        },
      ),
    );
  }
}
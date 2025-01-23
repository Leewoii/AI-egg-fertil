import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:intl/intl.dart';


class EggTrayScreen extends StatefulWidget {
  final String macAddress;
  final int? trayNumber;

  EggTrayScreen({required this.macAddress, this.trayNumber});

  @override
  _EggTrayScreenState createState() => _EggTrayScreenState();
}

class _EggTrayScreenState extends State<EggTrayScreen> {
  late List<Map<String, dynamic>> eggTray;
  late int currentTrayNumber;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

@override
void initState() {
  super.initState();
  currentTrayNumber = widget.trayNumber ?? 1; // Default to tray 1 if not provided
  eggTray = List.generate(56, (index) => {
        'number': index + 1,
        'hasEgg': false,
        'daysLeft': 0,
        'status': 'None',
      });

  _fetchEggTrayData(); // Fetch data from Firestore
  _updateDaysLeft(); // Automatically update daysLeft after data is fetched

  // Start a daily timer to decrement daysLeft
  Timer.periodic(Duration(days: 1), (timer) {
    setState(() {
      for (var egg in eggTray) {
        if (egg['hasEgg'] && egg['daysLeft'] > 0) {
          egg['daysLeft'] -= 1; // Decrease daysLeft by 1
        }
      }
    });
  });
}

// Function to save the macAddress
Future<void> saveMacAddress(String macAddress) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('macAddress', macAddress);
}



 Future<void> _fetchEggTrayData() async {
    try {
      var incubatorDoc = await _firestore
          .collection('Detection')
          .where('macAddress', isEqualTo: widget.macAddress)
          .limit(1)
          .get();

      if (incubatorDoc.docs.isNotEmpty) {
        var docId = incubatorDoc.docs.first.id;
        var docData = incubatorDoc.docs.first.data();

        if (docData.containsKey('tray_$currentTrayNumber') && docData['tray_$currentTrayNumber'] is Map) {
          Map tray = docData['tray_$currentTrayNumber'];

          for (int i = 0; i < 56; i++) {
            int slotNumber = i + 1;

            if (!tray.containsKey('slot_$slotNumber')) {
              tray['slot_$slotNumber'] = {
                'hasEgg': false,
                'daysLeft': 0,
                'status': 'None',
              };
            }

            eggTray[i]['hasEgg'] = tray['slot_$slotNumber']['hasEgg'];
            eggTray[i]['daysLeft'] = tray['slot_$slotNumber']['daysLeft'];
            eggTray[i]['status'] = tray['slot_$slotNumber']['status'];
          }

          await _firestore.collection('Detection').doc(docId).update({
            'tray_$currentTrayNumber': tray,
          });

          // After fetching data, update the days left
          await _updateDaysLeft();

          if (mounted) {
            setState(() {});
          }
        }
      }
    } catch (e) {
      print('Error fetching egg tray data: $e');
    }
  }

// Function to update Firestore with the egg tray data
  Future<void> _updateEggTrayData(List<int> selectedSlots) async {
  try {
    final Map<String, dynamic> updatedTrayData = {};

    for (int i = 0; i < 56; i++) {
      int slotNumber = i + 1;
      // Only update the modified slots
      if (selectedSlots.contains(slotNumber)) {
        updatedTrayData['slot_${slotNumber}'] = {
          'hasEgg': eggTray[i]['hasEgg'],
          'daysLeft': eggTray[i]['daysLeft'],
          'status': eggTray[i]['status'],
          'startDate': eggTray[i]['startDate'],  // Preserve startDate
          'endDate': eggTray[i]['endDate'],      // Preserve endDate
        };
      }
    }

    // Update Firestore for only the modified slots
    await _firestore
        .collection('Detection')
        .where('macAddress', isEqualTo: widget.macAddress)
        .get()
        .then((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        String docId = snapshot.docs.first.id;
        var docRef = _firestore.collection('Detection').doc(docId);

        docRef.get().then((docSnapshot) {
          if (docSnapshot.exists) {
            Map<String, dynamic> tray = docSnapshot.data()?['tray_$currentTrayNumber'] ?? {};

            // Update only the modified slots
            tray.addAll(updatedTrayData);

            docRef.update({
              'tray_$currentTrayNumber': tray,  // Update the current tray only
            }).then((_) {
              print('Egg tray data successfully updated');
            }).catchError((e) {
              print('Error updating tray data: $e');
            });
          } else {
            print('Document does not exist');
          }
        });
      } else {
        print('No matching document found');
      }
    });
  } catch (e) {
    print('Error updating egg tray data: $e');
  }
}



// Modify _addEgg to store the date excluding time
  void _addEgg(int index) async {
  try {
    var incubatorDoc = await _firestore
        .collection('Detection')
        .where('macAddress', isEqualTo: widget.macAddress)
        .limit(1)
        .get();

    if (incubatorDoc.docs.isNotEmpty) {
      var docId = incubatorDoc.docs.first.id;
      var docData = incubatorDoc.docs.first.data();

      // Get the tray data (tray_1 or tray_2)
      Map<String, dynamic> trayData = docData['tray_$currentTrayNumber'] ?? {};

      int slotNumber = index + 1; // Calculate slot number from index
      String slotKey = 'slot_$slotNumber';

      // Update only the specific slot with new egg data
      trayData[slotKey] = {
        'hasEgg': true,
        'daysLeft': 18,
        'status': 'Unknown',
        'startDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'endDate': DateFormat('yyyy-MM-dd')
            .format(DateTime.now().add(Duration(days: 18))),
      };

      // Update the tray data in Firestore
      await _firestore.collection('Detection').doc(docId).update({
        'tray_$currentTrayNumber': trayData,
      });

      if (mounted) {
        setState(() {
          // Update the local eggTray list
          eggTray[index]['hasEgg'] = true;
          eggTray[index]['daysLeft'] = 18;
          eggTray[index]['status'] = 'Unknown';
          eggTray[index]['startDate'] =
              DateFormat('yyyy-MM-dd').format(DateTime.now());
          eggTray[index]['endDate'] =
              DateFormat('yyyy-MM-dd').format(DateTime.now().add(Duration(days: 18)));
        });
      }
    }
  } catch (e) {
    print('Error adding egg: $e');
  }
}

Future<void> _updateDaysLeft() async {
  try {
    // Retrieve the document based on macAddress
    var incubatorDoc = await _firestore
        .collection('Detection')
        .where('macAddress', isEqualTo: widget.macAddress)
        .limit(1)
        .get();

    if (incubatorDoc.docs.isNotEmpty) {
      var docId = incubatorDoc.docs.first.id; // Document ID
      var docData = incubatorDoc.docs.first.data(); // Document data

      // Check if the current tray exists and is a map
      if (docData.containsKey('tray_$currentTrayNumber') &&
          docData['tray_$currentTrayNumber'] is Map) {
        Map<String, dynamic> tray = docData['tray_$currentTrayNumber'];

        for (int i = 0; i < 56; i++) {
          int slotNumber = i + 1;
          String slotKey = 'slot_$slotNumber';

          // Check if the slot exists
          if (tray.containsKey(slotKey)) {
            if (tray[slotKey]['hasEgg'] == true) {
              // Update dates when there is an egg
              String? startDateString = tray[slotKey]['startDate'];
              String? endDateString = tray[slotKey]['endDate'];

              if (startDateString != null && startDateString.isNotEmpty) {
                DateTime startDate = DateTime.parse(startDateString);
                DateTime currentDate = DateTime.now();

                DateTime endDate;
                if (endDateString == null || endDateString == "N/A") {
                  // Calculate endDate if it's "N/A" or missing
                  endDate = startDate.add(Duration(days: 18));
                  tray[slotKey]['endDate'] = endDate.toIso8601String();
                } else {
                  // Parse existing endDate
                  endDate = DateTime.parse(endDateString);
                }

                // Calculate daysLeft
                int daysRemaining = endDate.difference(currentDate).inDays;
                if (daysRemaining < 0) {
                  daysRemaining = 0; // Ensure daysLeft doesn't go negative
                }

                tray[slotKey]['daysLeft'] = daysRemaining;
              }
            } else {
              // Reset fields if no egg
              tray[slotKey]['startDate'] = "N/A";
              tray[slotKey]['endDate'] = "N/A";
              tray[slotKey]['daysLeft'] = "N/A";
            }
          }
        }

        // Update Firestore with the modified tray data
        await _firestore.collection('Detection').doc(docId).update({
          'tray_$currentTrayNumber': tray,
        });

        if (mounted) {
          setState(() {}); // Trigger UI update if widget is still mounted
        }
      }
    }
  } catch (e) {
    print('Error updating daysLeft: $e');
  }
}

void _emptySelectedSlots(List<int> selectedSlots) {
  for (int slot in selectedSlots) {
    setState(() {
      eggTray[slot - 1]['hasEgg'] = false;
      eggTray[slot - 1]['daysLeft'] = 'N/A';  // Set to string 'N/A'
      eggTray[slot - 1]['status'] = 'None';   // Reset status to 'None'
      eggTray[slot - 1]['startDate'] = 'N/A';  // Set to 'N/A'
      eggTray[slot - 1]['endDate'] = 'N/A';    // Set to 'N/A'
    });
  }
  _updateEggTrayData(selectedSlots);  // Update Firestore after emptying slots
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            _logoutAndNavigateBack();
          },
        ),
        title: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(30.0),
            border: Border.all(color: Colors.blue.shade200, width: 1.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: currentTrayNumber,
              icon: Icon(Icons.arrow_drop_down, color: Colors.black),
              onChanged: _onTrayChanged,
              items: [1, 2].map((trayNumber) {
                return DropdownMenuItem<int>(
                  value: trayNumber,
                  child: Text(
                    'Tray $trayNumber',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
     body: Padding(
  padding: const EdgeInsets.all(16.0),
  child: Column(
    children: [
      // The egg tray grid
      Expanded(
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7, // Number of columns in the grid
            childAspectRatio: 0.9, // Adjust the item size for a better fit
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
          ),
          itemCount: eggTray.length,
itemBuilder: (context, index) {
  double progress = eggTray[index]['hasEgg']
      ? 1.0 - (eggTray[index]['daysLeft'] / 18) // Adjust based on max days
      : 0.0;

  return GestureDetector(
    onTap: () {
      if (!eggTray[index]['hasEgg']) {
        _showAddEggButton(index);
      } else {
        _checkEggStatus(index);
      }
    },
    child: Stack(
      alignment: Alignment.center,
      children: [
        // Circular progress animation
        SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(
            value: progress, // Current progress
            backgroundColor: Colors.grey.shade300, // Inactive background color
            valueColor: AlwaysStoppedAnimation<Color>(
              eggTray[index]['daysLeft'] == 0 ? Colors.green : Colors.blue,
            ),
            strokeWidth: 6,
          ),
        ),
        // Circle icon inside the progress animation
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: eggTray[index]['hasEgg']
                ? (eggTray[index]['daysLeft'] == 0
                    ? Colors.green
                    : Colors.grey.shade400)
                : Colors.grey.shade300,
          ),
          child: Center(
            child: Text(
              '${eggTray[index]['number']}',
              style: TextStyle(
                color: eggTray[index]['hasEgg'] ? Colors.white : Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    ),
  );
},
),
),

      // Button Row with reduced gap
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0), // Reduced vertical padding
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center, // Center buttons horizontally
          children: [
            ElevatedButton(
              onPressed: () {
                _showMultiSlotSelectionDialog(empty: true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text('Empty Egg'),
            ),
            SizedBox(width: 16), // Reduced space between buttons
            ElevatedButton(
              onPressed: () {
                _showMultiSlotSelectionDialog(empty: false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text('Add Egg'),
            ),
          ],
        ),
      ),
    ],
  ),
),
    );
  }


  void _onTrayChanged(int? newTray) {
    if (newTray != null && newTray != currentTrayNumber) {
      setState(() {
        currentTrayNumber = newTray;
        _fetchEggTrayData();
      });
    }
  }

  Future<void> _logoutAndNavigateBack() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    Navigator.pop(context);
  }
  
  void _showAddEggButton(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Egg to Slot ${index + 1}'),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                _addEgg(index);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text('Add Egg'),
            ),
          ],
        );
      },
    );
  }

void _showMultiSlotSelectionDialog({required bool empty}) {
  List<int> selectedSlots = [];

  // Filter slots based on the action (adding or emptying eggs).
  List<Map<String, dynamic>> availableSlots = empty
      ? eggTray.where((slot) => slot['hasEgg']).toList() // Slots with eggs for emptying
      : eggTray.where((slot) => !slot['hasEgg']).toList(); // Slots without eggs for adding

  // Ensure dialog is showing after frame is built
  WidgetsBinding.instance.addPostFrameCallback((_) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, void Function(void Function()) setDialogState) {
            return AlertDialog(
              title: Text(
                empty ? 'Select Slots to Empty' : 'Select Slots to Add Eggs',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 400), // Limit the dialog height
                child: SingleChildScrollView(
                  child: GridView.builder(
                    shrinkWrap: true, // Allow the grid to be constrained
                    physics: NeverScrollableScrollPhysics(), // Disable scrolling in the grid itself
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4, // Adjust number of columns
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: availableSlots.length,
                    itemBuilder: (context, index) {
                      int slotIndex = availableSlots[index]['number'];
                      bool isSelected = selectedSlots.contains(slotIndex);

                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            if (isSelected) {
                              selectedSlots.remove(slotIndex); // Deselect
                            } else {
                              selectedSlots.add(slotIndex); // Select
                            }
                          });
                        },
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.green[300] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? Colors.green : Colors.grey,
                              width: 2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.5),
                                      blurRadius: 5,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Text(
                            'Slot $slotIndex',
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    if (selectedSlots.isNotEmpty) {
                      Navigator.of(context).pop();
                      if (empty) {
                        _emptySelectedSlots(selectedSlots);
                      } else {
                        for (int slotIndex in selectedSlots) {
                          _addEgg(slotIndex - 1); // Adjust for 0-based indexing
                        }
                      }
                    }
                  },
                  child: Text('Confirm'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  });
}

 void _checkEggStatus(int index) {
  String status = eggTray[index]['status'];
  int daysLeft = eggTray[index]['daysLeft'];

  if (daysLeft == 0 && status == 'fertile') {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Egg Ready for Hatchery'),
          content: Text(
            'The egg in Slot ${index + 1} is ready to be placed in the hatchery.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Remove the egg from the slot
                setState(() {
                  eggTray[index]['hasEgg'] = false;
                  eggTray[index]['daysLeft'] = 'N/A'; // Set to string 'N/A'
                  eggTray[index]['status'] = 'None'; // Reset the status
                  eggTray[index]['startDate'] = 'N/A';
                  eggTray[index]['endDate'] = 'N/A';
                });

                // Update Firestore to reflect changes
                _updateEggTrayData([index + 1]); // Slot numbers are 1-based
                Navigator.of(context).pop();
              },
              child: Text('Remove'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  } else {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Egg Status for Slot ${index + 1}'),
          content: Text(
            'Status: $status\nDays Left: $daysLeft',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

  BoxDecoration _getSlotDecoration(int index) {
    if (eggTray[index]['daysLeft'] == 14 &&
        eggTray[index]['status'] == 'infertile') {
      return BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.red, // Red background for critical condition
      );
    } else {
      return BoxDecoration(
        shape: BoxShape.circle,
        color: eggTray[index]['hasEgg']
            ? (eggTray[index]['daysLeft'] == 0
                ? Colors.green
                : Colors.grey.shade400)
            : Colors.grey.shade300,
      );
    }
  }
}
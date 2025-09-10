import 'package:flutter/material.dart';

class EggSlotWidget extends StatelessWidget {
  final int slotNumber;
  final bool hasEgg;
  final Stream<int> daysLeftStream; // Stream of days left for countdown
  final String status;
  final VoidCallback onSlotTap;

  const EggSlotWidget({
    Key? key,
    required this.slotNumber,
    required this.hasEgg,
    required this.daysLeftStream,
    required this.status,
    required this.onSlotTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSlotTap,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: hasEgg ? Colors.green : Colors.grey.shade300,
          border: Border.all(
            color: Colors.black.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$slotNumber',
                style: TextStyle(
                  color: hasEgg ? Colors.white : Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (hasEgg) ...[
                Text(
                  '$status',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
                StreamBuilder<int>(
                  stream: daysLeftStream,
                  builder: (context, snapshot) {
                    int daysLeft = snapshot.data ?? 0;
                    return AnimatedDefaultTextStyle(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      child: Text(
                        daysLeft > 0 ? 'Days Left: $daysLeft' : 'Hatched',
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

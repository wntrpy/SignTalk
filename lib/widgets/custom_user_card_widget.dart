import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class CustomUserCardWidget extends StatelessWidget {
  const CustomUserCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Slidable(
      //mute block delete options
      endActionPane: ActionPane(
        motion: StretchMotion(),
        children: [
          SlidableAction(
            //mute
            onPressed: (context) {},
            icon: Icons.notifications,
            backgroundColor: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),

          //block
          SlidableAction(
            onPressed: (context) {},
            icon: Icons.block,
            backgroundColor: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),

          //delete
          SlidableAction(
            onPressed: (context) {},
            icon: Icons.delete,
            backgroundColor: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),

      //TODO: dito content
      child: Container(),
    );
  }
}

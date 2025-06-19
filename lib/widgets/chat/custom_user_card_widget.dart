import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:signtalk/app_constants.dart';
import 'package:signtalk/widgets/buttons/custom_circle_pfp_button.dart';

class CustomUserCardWidget extends StatelessWidget {
  const CustomUserCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {}, //TODO: lagyan function
            icon: Icons.notifications,
            backgroundColor: AppConstants.darkViolet,
            borderRadius: BorderRadius.circular(12),
          ),
          SlidableAction(
            onPressed: (context) {}, //TODO: lagyan function
            icon: Icons.block,
            backgroundColor: AppConstants.darkViolet,
            borderRadius: BorderRadius.circular(12),
          ),
          SlidableAction(
            onPressed: (context) {}, //TODO: lagyan function
            icon: Icons.delete,
            backgroundColor: AppConstants.darkViolet,
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            context.push('/chat_screen');
          },
          // splash and ripple fx
          splashColor: AppConstants.darkViolet.withOpacity(0.2),
          highlightColor: AppConstants.darkViolet.withOpacity(0.1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //--------------------------USER PFP---------------------------
              CustomCirclePfpButton(
                borderColor: AppConstants.darkViolet,
                userImage: null,
              ),

              //--------------------------FULL NAME AND CHAT---------------------------
              Expanded(child: _fullNameAndChat()),

              //--------------------------TIMESTAMP---------------------------
              Text(
                "12:11 AM", //TODO: palitan later
                style: TextStyle(
                  color: AppConstants.darkViolet,
                  fontSize: AppConstants.fontSizeSmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _fullNameAndChat() {
  return Padding(
    padding: const EdgeInsets.only(top: 8.0, left: 8.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //--------------------------FULL NAME---------------------------
        Text(
          "Asa Enami", //TODO: palitan later
          style: TextStyle(
            color: AppConstants.darkViolet,
            fontWeight: FontWeight.bold,
            fontSize: AppConstants.fontSizeLarge,
          ),
        ),

        //--------------------------CHAT---------------------------
        Text(
          //TODO: palitan later
          "Malaking ipikto sa bustun siltics",
          style: TextStyle(
            color: AppConstants.darkViolet,
            fontSize: AppConstants.fontSizeMedium,
          ),
        ),
      ],
    ),
  );
}

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
      //mute block delete options
      endActionPane: ActionPane(
        motion: StretchMotion(),
        children: [
          SlidableAction(
            //mute
            onPressed: (context) {},
            icon: Icons.notifications,
            backgroundColor: AppConstants.darkViolet,
            borderRadius: BorderRadius.circular(12),
          ),

          //block
          SlidableAction(
            onPressed: (context) {},
            icon: Icons.block,
            backgroundColor: AppConstants.darkViolet,
            borderRadius: BorderRadius.circular(12),
          ),

          //delete
          SlidableAction(
            onPressed: (context) {},
            icon: Icons.delete,
            backgroundColor: AppConstants.darkViolet,
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),

      //TODO: dito content
      child: InkWell(
        borderRadius: BorderRadius.circular(12), //  ripple effect pagpenendot
        onTap: () {
          //TODO: fix mo later = dapat mapunta lang sa chat screen
          context.push('/chat_screen');
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //--------------------------USER PFP---------------------------
            CustomCirclePfpButton(
              borderColor: AppConstants.darkViolet,
              userImage: null,
            ), //TODO: palitan ng pic galing sa db, if none edi default pic
            //--------------------------FULL NAME AND CHAT---------------------------
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //--------------------------FULL NAME---------------------------
                  Text(
                    "Asa Enami",
                    style: TextStyle(
                      color: AppConstants.darkViolet,
                      fontWeight: FontWeight.bold,
                      fontSize: AppConstants.fontSizeLarge,
                    ),
                  ),

                  //--------------------------CHAT---------------------------
                  Text(
                    "Malaking ipikto sa bustun siltics",
                    style: TextStyle(
                      color: AppConstants.darkViolet,
                      fontSize: AppConstants.fontSizeMedium,
                    ),
                  ),
                ],
              ),
            ),

            //--------------------------TIMESTAMP---------------------------
            Text(
              "12:11 AM",
              style: TextStyle(
                color: AppConstants.darkViolet,
                fontSize: AppConstants.fontSizeSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

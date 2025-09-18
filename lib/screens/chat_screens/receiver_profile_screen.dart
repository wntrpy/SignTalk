import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signtalk/app_constants.dart';
import 'package:signtalk/core/helper/helper_receiver_profile_screen.dart';
import 'package:signtalk/widgets/buttons/custom_circle_pfp_button.dart';
import 'package:signtalk/widgets/buttons/custom_icon_button.dart';
import 'package:signtalk/widgets/chat/custom_receiver_profile_option.dart';

class ReceiverProfileScreen extends StatelessWidget {
  // required constructor fields
  final Map<String, dynamic> receiverData;
  final String chatId;
  final String receiverId;
  final String nickname;

  const ReceiverProfileScreen({
    super.key,
    required this.receiverData,
    required this.chatId,
    required this.receiverId,
    required this.nickname,
  });

  @override
  Widget build(BuildContext context) {
    final loggedInUserId = FirebaseAuth.instance.currentUser!.uid;

    final finalReceiverProfileOptions = getReceiverProfileOptions(
      context,
      chatId: chatId,
      loggedInUserId: loggedInUserId,
      receiverId: receiverId,
    );

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) context.pop();
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(AppConstants.signtalk_bg, fit: BoxFit.cover),

            // back button
            Padding(
              padding: const EdgeInsets.only(top: 24, left: 16),
              child: Align(
                alignment: Alignment.topLeft,
                child: CustomIconButton(
                  icon: Icons.arrow_back,
                  color: Colors.white,
                  size: 30.0,
                  onPressed: () => context.pop(),
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.only(top: 100, right: 20, left: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // header uses nickname passed in constructor
                  _buildUserProfileHeader(receiverData, nickname),

                  // options
                  ...finalReceiverProfileOptions.map(
                    (option) => Column(
                      children: [
                        CustomReceiverProfileOption(
                          optionText: option['optionText'],
                          iconPath: option['iconPath'] ?? '',
                          fallbackIcon: option['fallbackIcon'],
                          trailingWidget: option['trailingWidget'],
                          onTap: option['onTap'],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildUserProfileHeader(
  Map<String, dynamic> receiverData,
  String nickname,
) {
  final display = (nickname.isNotEmpty)
      ? nickname
      : (receiverData['name'] as String?) ?? 'Unknown User';

  return Container(
    padding: const EdgeInsets.only(bottom: 15),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Colors.white, width: 1.5)),
    ),
    child: Row(
      children: [
        /*  CustomCirclePfpButton(
          borderColor: Colors.white,
          userImage: receiverData['photoUrl'] ?? AppConstants.default_user_pfp,
          width: 120,
          height: 120,
        ),*/
        SizedBox(
          width: 120,
          height: 120,
          child: CircleAvatar(
            child: Text(
              display[0].toUpperCase(),
              style: TextStyle(fontSize: 48),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //TODO: MAY PROBLEM SA FRONT END DITO SA TEXT, NAG-OOVERFLOW
            Text(
              display,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: AppConstants.fontSizeExtraLarge,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

void showChangeNicknameDialog(
  BuildContext context,
  Map<String, dynamic> receiverData,
) {
  final TextEditingController controller = TextEditingController(
    text: receiverData['nickname'] ?? receiverData['name'],
  );

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Change Nickname"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter nickname"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final uid = FirebaseAuth.instance.currentUser!.uid;
              final chatId = receiverData['chatId'];
              final receiverId = receiverData['uid'];
              final newNickname = controller.text.trim();

              if (chatId != null && newNickname.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('chats')
                    .doc(chatId)
                    .set({
                      'nicknames': {
                        uid: {receiverId: newNickname},
                      },
                    }, SetOptions(merge: true));
              }

              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      );
    },
  );
}

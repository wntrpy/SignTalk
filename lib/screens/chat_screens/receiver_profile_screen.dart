import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:signtalk/app_constants.dart';
import 'package:signtalk/core/helper/helper_receiver_profile_screen.dart';
import 'package:signtalk/widgets/buttons/custom_icon_button.dart';
import 'package:signtalk/widgets/chat/custom_receiver_profile_option.dart';

class ReceiverProfileScreen extends StatelessWidget {
  // required constructor fields (pass sa GoRouter route builder)
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

    // if chatId is missing, show header using passed nickname/name,
    if (chatId.trim().isEmpty) {
      final display = (nickname.isNotEmpty)
          ? nickname
          : (receiverData['name'] as String?) ?? 'Unknown User';

      final finalReceiverProfileOptions = getReceiverProfileOptions(
        context,
        chatId: chatId,
        loggedInUserId: loggedInUserId,
        receiverId: receiverId,
      );

      return PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          if (!didPop) Navigator.of(context).pop();
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
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.only(top: 100, right: 20, left: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildUserProfileHeader(receiverData, display),
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

    // listen for live nickname changes
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .snapshots(),
      builder: (context, chatSnap) {
        // default fallback display name is the user name from users collection
        String displayName =
            (receiverData['name'] as String?) ?? 'Unknown User';

        if (chatSnap.hasData && chatSnap.data!.exists) {
          final chatData = chatSnap.data!.data() as Map<String, dynamic>? ?? {};

          final rawNickMap = chatData['nicknames'];
          if (rawNickMap != null) {
            try {
              final Map<String, dynamic> nickMap = Map<String, dynamic>.from(
                rawNickMap,
              );
              if (nickMap.containsKey(loggedInUserId)) {
                final Map<String, dynamic> userNicknames =
                    Map<String, dynamic>.from(nickMap[loggedInUserId]);
                final dynamic nick = userNicknames[receiverId];
                if (nick != null && nick.toString().trim().isNotEmpty) {
                  displayName = nick.toString();
                }
              }
            } catch (e) {
              // ignore parse errors and keep fallback displayName
            }
          }
        }

        final finalReceiverProfileOptions = getReceiverProfileOptions(
          context,
          chatId: chatId,
          loggedInUserId: loggedInUserId,
          receiverId: receiverId,
        );

        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) {
            if (!didPop) Navigator.of(context).pop();
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
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(top: 100, right: 20, left: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildUserProfileHeader(receiverData, displayName),
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
      },
    );
  }
}

Widget _buildUserProfileHeader(
  Map<String, dynamic> receiverData,
  String displayName,
) {
  final display = (displayName.trim().isNotEmpty)
      ? displayName
      : (receiverData['name'] as String?) ?? 'Unknown User';

  return Container(
    padding: const EdgeInsets.only(bottom: 15),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Colors.white, width: 1.5)),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: CircleAvatar(
            child: Text(
              display[0].toUpperCase(),
              style: const TextStyle(fontSize: 48),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Flexible(
          child: Text(
            display,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: AppConstants.fontSizeExtraLarge,
            ),
          ),
        ),
      ],
    ),
  );
}

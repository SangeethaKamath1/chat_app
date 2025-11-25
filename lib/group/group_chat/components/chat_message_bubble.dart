

import 'package:chat_app/group/group_chat/components/reaction_list_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../constants/app_constant.dart';
import '../../../helpers.dart';

import '../../../src/theme/controller/chat_theme_controller.dart';
import '../controller/group_chat_controller.dart';
import '../group-message-info.dart';

class ChatMessageBubble extends StatelessWidget {
  final dynamic message;
  final int index;

  final bool isMine;
  final GroupChatController chatController;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.index,
    
    required this.isMine,
    required this.chatController,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
     () {
        return Container(
          
          color:chatController.chatIndex.value ==index?Colors.lightBlueAccent:Colors.transparent,
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: Stack(
           
            children: [
              GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
                    chatController.setReply(message);
                  }
                },
                onLongPressStart: (details) {
                //      chatController.fetchMessageStatus(message.id).then((_) {
                //   Get.to(
                //     () => GroupMessageInfoScreen(
                //       messageId: message.id,
                //       messageText: message.message,
                //       senderName: message.senderUsername ?? 'Unknown',
                //       chatController: chatController,
                //     ),
                //   );
                // });
                  chatController.chatIndex.value = index;
                  chatController.messageId.value = message.id ?? "";
                  final Offset position = details.globalPosition;
                  debugPrint("hellooo:${chatConfigController.config.prefs.getString(constant.userId) ==chatController.conversations[chatController.chatIndex.value].senderUUID},${chatController.currentGroupDetails.value.isAdmin},${chatController.currentGroupDetails.value.isOwner}");
          
                  showReactionOverlayForGroup(
                    context: context,
                    position: position,
                    messageId: message.id ?? "",
                    chatController: chatController,
                    isMine: isMine,
                  );
                },
                child: Align(
                  alignment:
                      isMine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Column(
                    children: [
                      // Text( chatConfigController.config.prefs.getString(constant.username)!=message.senderUsername?message.senderUsername:""),
                      Container(
                        margin: EdgeInsets.symmetric(
                            vertical:
                                message.reactions?.isNotEmpty == true ? 12 : 4),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 14),
                        decoration: BoxDecoration(
                          color: isMine ? chatConfigController.config.primaryColor : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                           
                            if (message.replayTo != null)
                              _buildReplyPreview(message, isMine),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                
                                Text(message.message ?? ""),
                                const SizedBox(width: 10),
                                if (isMine) _buildStatusIcon(message.status),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (message.reactions?.isNotEmpty == true)
                _buildReactionBubble(context, message, isMine),
            ],
          ),
        );
      }
    );
  }

  Widget _buildReplyPreview(message, bool isMine) {
    return Container(
      padding: const EdgeInsets.all(6),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isMine ? chatConfigController.config.primaryColor : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.replayTo!.senderUsername ?? "Unknown",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isMine ? chatConfigController.config.primaryColor : Colors.black87,
              fontSize: 12,
            ),
          ),
          Text(
            message.replayTo!.message ?? "",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(String? status) {
    switch (status) {
      case "SEND":
        return const Icon(Icons.check, size: 18);
      case "DELIVERED":
        return const Icon(Icons.done_all, size: 18);
      case "SEEN":
        return const Icon(Icons.done_all, color: Colors.lightBlue, size: 18);
      default:
        return const Icon(Icons.check, size: 18);
    }
  }

  Widget _buildReactionBubble(BuildContext context, message, bool isMine) {
    return Positioned(
     // top:40,
      top:message.replayTo != null&&isMine? 88:message.replayTo != null&&!isMine?95:40,
      right: isMine ? 12 : null,
      left: isMine ? null : 12,
      child: InkWell(
        onTap: () {
          chatController.isReactionLastPage = false;
         chatController.chatIndex.value=index;
         chatController.reactions.clear();
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => ReactionListBottomSheet(
              chatController: chatController,
              messageId: message.id ?? "",
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(blurRadius: 2, color: Colors.black26)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: message.reactions!
      .map<Widget>((emoji) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 14),
            ),
          ))
      .toList(),
),
        ),
      ),
    );
  }
}

// group/group_chat/screens/group_message_info_screen.dart
import 'package:chat_module/model/group_message_status.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_module/group/group_chat/controller/group_chat_controller.dart';
import 'package:chat_module/service/shared_preference.dart';
import 'package:chat_module/constants/app_constant.dart';

import '../../routes/app_routes.dart';


class GroupMessageInfoScreen extends StatelessWidget {
  final String messageId;
  final String messageText;
  final String senderName;
  final GroupChatController chatController;

  const GroupMessageInfoScreen({
    super.key,
    required this.messageId,
    required this.messageText,
    required this.senderName,
    required this.chatController,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Message Info'),
        backgroundColor: Colors.blue,
      ),
      body: Obx(() {
        
      

        return Column(
          children: [
            // Message Preview
            _buildMessagePreview(),
            
           
            
            // Tab Bar for Sent/Delivered
            _buildTabBar(),
          ],
        );
      }),
    );
  }





  Widget _buildMessagePreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          // Message bubble icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.message, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  messageText,
                  style: const TextStyle(fontSize: 16),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'From: $senderName',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryStatistics() {
   

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
        
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(title, style: TextStyle(fontSize: 12, color: color)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildTabBar() {
    return DefaultTabController(
      length: 2,
      child: Expanded(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              child: TabBar(
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blue,
                tabs: const [
                 
                  Tab(
                    icon: Icon(Icons.done_all, size: 20),
                    text: 'Delivered',
                  ),

                   Tab(
                    icon: Icon(Icons.remove_red_eye_outlined, size: 20),
                    text: 'Read',
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Delivered Tab
                
                  
                  // Sent Tab
                  _buildUserList(
                     chatController.deliveredList ?? [],
                    'Message is being sent...',
                    Icons.message,
                    Colors.grey
                   
                  ),
                   _buildUserList(
                     chatController.seen ?? [],
                    'Message is being sent...',
                    Icons.message,
                    Colors.grey,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(List<UserStatus> users, String emptyMessage, IconData icon, Color color) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final isCurrentUser = user.username == SharedPreference().getString(AppConstant.username);
        
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isCurrentUser ? color : Colors.grey,
            child: Text(
              user.username[0].toUpperCase(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Row(
            children: [
              Text(
                user.username,
                style: TextStyle(
                  fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (isCurrentUser) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'You',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Text(
            _formatTime(user.updatedAt),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          trailing: InkWell(
            onTap:(){
                Get.toNamed(AppRoutes.chat, arguments: {
                                "name": user.username,
                                // "description":user
                                "id": user.id,
                                "conversationId": user.id,
                                "status": ""
                              });
            },
            child: Icon(icon, color: color)),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    } else {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    }
  }
}
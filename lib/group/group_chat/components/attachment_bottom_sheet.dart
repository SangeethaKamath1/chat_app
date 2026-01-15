import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/group_chat_controller.dart';



class AttachmentBottomSheet extends StatelessWidget {
  final GroupChatController chatController;

  const AttachmentBottomSheet({super.key, required this.chatController});

  @override
  Widget build(BuildContext context) {
    Widget _buildItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.15),
        child: Icon(icon, color: color),
      ),
      title: Text(label, style:  TextStyle(fontSize: 16,color:MediaQuery.platformBrightnessOf(context)==Brightness.dark?Colors.white:Colors.black)),
      onTap: onTap,
    );
  }
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildItem(
              icon: Icons.image,
              label: "Gallery",
              color: Colors.purple,
              onTap: () {
                Get.back();
                chatController.pickMediaFromGallery(isCamera: false);
              },
            ),
            _buildItem(
              icon: Icons.camera_alt,
              label: "Camera",
              color: Colors.red,
              onTap: () {
               Get.back();
  chatController.openCameraPicker(context);
              },
            ),
            // _buildItem(
            //   icon: Icons.insert_drive_file,
            //   label: "Document",
            //   color: Colors.blue,
            //   onTap: () {
            //     Get.back();
            //     chatController.pickDocument();
            //   },
            // ),
          ],
        ),
      ),
    );
  }

  
}

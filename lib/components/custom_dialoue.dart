import 'package:chat_module/view_members/controller/view_members_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomAlertDialogue extends StatelessWidget {
  final String titleText;
  final String successText;
  final String? cancelText;
  final Function() onRemoveClicked;
  const CustomAlertDialogue({super.key, required this.titleText,required this.successText, this.cancelText,required this.onRemoveClicked});

  @override
  Widget build(BuildContext context) {
    Get.find<ViewMembersController>();
    return AlertDialog(shape: 
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(12),
    
    ),
    title: Text(titleText),
    actions: [
      TextButton(child: Text(successText,style: TextStyle(color:Colors.red,fontSize: 14,)),onPressed: (){
        Get.back();
onRemoveClicked();
      },),
      TextButton(child: Text("Cancel",style: TextStyle(fontSize: 14,)),onPressed: (){
        Get.back();
        
      },)
    ],

    );
  }
}
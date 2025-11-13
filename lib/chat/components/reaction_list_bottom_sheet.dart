
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../../constants/app_constant.dart';
import '../../service/shared_preference.dart';
import '../controller/chat_controller.dart';
import '../helpers/encryption_helper.dart';

class ReactionListBottomSheet extends StatefulWidget {
  final ChatController chatController;
  final String messageId;

  const ReactionListBottomSheet({super.key, required this.chatController,required this.messageId});

  @override
  State<ReactionListBottomSheet> createState() => _ReactionListBottomSheetState();
}

class _ReactionListBottomSheetState extends State<ReactionListBottomSheet>
    with SingleTickerProviderStateMixin {


 

  @override
  void initState() {
    super.initState();
  widget.chatController.getReactions(widget.messageId);
    // Collect unique emoji from reactions
   
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Tabs
          Text("Reactions",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18),),
          const Divider(height: 20),

          // Tab content
         Obx((){
              if(widget.chatController.reactions.isNotEmpty==true){
              return SizedBox(
                height: 300, // fixed height for scrollable list
                child:  ListView.builder(
                      itemCount: widget.chatController.reactions.length,
                      itemBuilder: (context, index) {
                        final reaction = widget.chatController.reactions[index];
                        final currentUser =
                            SharedPreference().getString(AppConstant.username);
              
                        return ListTile(
                          onTap: (){
                             int chatIndex = widget.chatController.chatIndex.value;
                            if(reaction.user?.username==SharedPreference().getString(AppConstant.username)){
                               widget.chatController.chatWebSocket.sendReaction(
                    widget.messageId,
                    "",
                    int.parse(widget.chatController.conversationId),
                  );
                   widget.chatController.reactions.removeWhere((ele)=>ele.user?.username==currentUser);
                   widget.chatController.reactions.refresh();
                   final conversation =widget.chatController.conversations[chatIndex];
                   debugPrint("conversation:$conversation");
                   conversation.reactions?.remove(EncryptionHelper.decryptText(conversation.reaction??""));
                   conversation.isReacted=false;
                   conversation.reaction="";
                   widget.chatController.conversations.refresh();
                   
                            }
                         
                          },
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue[100],
                            child: Text(
                              reaction.reaction ?? "",
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                          title: Text(
                            reaction.user?.username == currentUser
                                ? "You"
                                : (reaction.user?.username ?? "Unknown"),
                          ),
                          trailing: Text(
                            reaction.reaction ?? "",
                            style: const TextStyle(fontSize: 22),
                          ),
                        );
                      },
              )
                 
               
              );
              }else if( widget.chatController.reactions.isEmpty &&!widget.chatController.isReactionLoading){
               return            Text("No reaction");
              }
              
              else{
                return _buildShimmer();
              }
         }),
        ],
      ),
    );
  }
}
Widget _buildShimmer() {
    return SizedBox(
      height: 300,
      child: ListView.builder(
        itemCount: 6,
        itemBuilder: (_, __) {
          return Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: ListTile(
              leading: CircleAvatar(backgroundColor: Colors.white),
              title: Container(
                height: 14,
                color: Colors.white,
                margin: const EdgeInsets.only(right: 100),
              ),
              trailing: Container(
                width: 20,
                height: 20,
                color: Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }

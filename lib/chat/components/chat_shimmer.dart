import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:math';

class ChatShimmer extends StatelessWidget {
  const ChatShimmer({super.key});

  @override
  Widget build(BuildContext context) {
   
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      itemCount: 15,
      itemBuilder: (context, index) {
        final bool isMine = index % 2 == 0;

        // width variation
        final int bubbleWidth = 140 + Random().nextInt(70);

        return Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade100,
            highlightColor: Colors.black12,
              child: Container(
                height: 40, // 🔹 Increased height (was 40)
                width: bubbleWidth.toDouble(),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10), // 🔹 Less curve (was 18)
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

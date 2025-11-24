import 'dart:async';

import 'package:chat_app/search/repository/search_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';

import '../../model/group_member.dart';


class SearchUserController extends GetxController {
  final TextEditingController searchController = TextEditingController();
  final RxList<Member> results = <Member>[].obs;
  final RxBool isLoading = false.obs;
  bool isLastPage =false;
  
  int page=0;
  Timer? debounce;


  @override
  onInit(){
search();
    super.onInit();
  
    
  }
Future<void> search() async {
    if (isLastPage) {
     
      return;
    }

    try {
      isLoading.value = true;

 SearchRepository.searchUser(searchController.text, page.toString()).then((response){
          if(response.content?.isNotEmpty==true){
            if(page ==0){
              results.clear();
   results.addAll(response.content??[]);
            }else{
               results.assignAll(response.content??[]);
            }
         if(response.last==true){
          isLastPage=true;
         }else{
          page++;
         }
          }
      });
      
    } on DioException catch (e) {
      results.clear();
      debugPrint("❌ Search error: ${e.message}");
    } finally {
      isLoading.value = false;
    }
  }


void onSearchTextChanged(String query){
  if(debounce?.isActive??false) {
    debounce!.cancel();
  } 
debounce=Timer(const Duration(milliseconds: 500),(){
  isLastPage=false;
search();
});
    /// Call API to search users
  
}


}
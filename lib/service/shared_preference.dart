import 'package:shared_preferences/shared_preferences.dart';

class SharedPreference{
  static final SharedPreference _instance=SharedPreference._internal();
factory SharedPreference()=>_instance;
SharedPreference._internal();

late final   SharedPreferences _prefs;

 Future<void> init()async{
  _prefs = await SharedPreferences.getInstance();
}

 void setString(String key,String value){
  _prefs.setString(key, value);
}

String? getString(String key){
return   _prefs.getString(key);
}

 void setInt(String key,int value){
  _prefs.setInt(key, value);
}

int? getInt(String key){
return   _prefs.getInt(key);
}


void setBool(String key,bool value){

  _prefs.setBool(key,value);
}

bool? getBool(String key){
  return _prefs.getBool(key);
}
void remove(String key){
  _prefs.remove(key);
}

void clear(){
  _prefs.clear();
}

}
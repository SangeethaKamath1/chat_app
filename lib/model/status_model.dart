
class StatusModel{

  String? message;

  StatusModel({
    
    this.message}
  );

factory   StatusModel.fromJson(Map<String, dynamic> json){
return StatusModel( 
 message:json["message"]);
  }

Map<String, dynamic>  toJson()=>{
    "message":message
  };

}
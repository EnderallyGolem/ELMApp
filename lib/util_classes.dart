import 'package:flutter/material.dart';
//import 'package:provider/provider.dart';
//import '../main.dart';


///
/// Usage: 
/// [value]
///
class ElmModule {
  String value;
  TextEditingController _controllers = TextEditingController(
    text: '',
  );

  ElmModule({this.value = ''}) {
    //_display = 'Wave ${waveIndex + 1}';
    _controllers = TextEditingController(
      text: value,
  );
  }

  TextEditingController get controllers => _controllers;
  set controllers(TextEditingController controllers) => _controllers = controllers;
}
import 'package:flutter/material.dart';

class CustomFormField extends StatelessWidget{
  final String hintText;
  final double height;
  final RegExp validationRegExp;
  final bool obscureTest;
  final void Function(String?) onSaved;

  const CustomFormField({
    super.key,
    required this.hintText,
    required this.height,
    required this.validationRegExp,
    required this.onSaved,
    this.obscureTest = false,
  });

  @override
  Widget build(BuildContext context){
    return SizedBox(
      height: height,
      child: TextFormField(
        onSaved: onSaved,
        obscureText: obscureTest,
        validator: (value) {
          if (value != null && validationRegExp.hasMatch(value)){
            return null;
          }
          return "Enter a valid ${hintText.toLowerCase()}";
        },
        decoration: InputDecoration(
          hintText: hintText,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
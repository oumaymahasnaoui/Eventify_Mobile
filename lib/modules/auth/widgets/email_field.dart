import 'package:flutter/material.dart';

class EmailField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final FormFieldSetter<String>? onSaved;

  const EmailField({
    super.key,
    this.controller,
    this.onChanged,
    this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent),
      ),
      child: TextFormField(
        controller: controller,
        onChanged: onChanged,
        onSaved: onSaved,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        decoration: const InputDecoration(
          hintText: 'Adresse e-mail',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          prefixIcon: Icon(Icons.email_outlined, color: Colors.grey),
          errorMaxLines: 2,
        ),
        validator: _validateEmail,
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre adresse e-mail';
    }

    // Regex email corrigé - chaîne terminée correctement
    final regex = RegExp(
      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
      caseSensitive: false,
    );

    // Condition corrigée - point-virgule enlevé et bon usage de !
    if (!regex.hasMatch(value)) {
      return 'Veuillez entrer une adresse e-mail valide';
    }
    return null;
  }
}
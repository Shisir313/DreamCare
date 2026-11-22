import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/validators.dart';
import 'dermacare_text_field.dart';

/// Phone number input field with Nepal-specific formatting
class PhoneField extends StatelessWidget {
  const PhoneField({
    super.key,
    required this.controller,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.enabled = true,
  });

  final TextEditingController controller;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final TextInputAction? textInputAction;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DermaCareTextField(
      label: 'Phone Number',
      hint: '98XXXXXXXX',
      controller: controller,
      validator: Validators.phone,
      keyboardType: TextInputType.phone,
      textInputAction: textInputAction ?? TextInputAction.next,
      enabled: enabled,
      maxLength: 10,
      prefixIcon: const Icon(Icons.phone_outlined),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      autofillHints: const [AutofillHints.telephoneNumber],
    );
  }
}

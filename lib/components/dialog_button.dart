import 'package:flutter/material.dart';

class DialogActionButton extends StatelessWidget {
  final void Function() onPressed;
  final Widget textContent;
  final Color backgroundColor;
  final Color textColor;
  const DialogActionButton({
    Key? key,
    required this.onPressed,
    required this.textContent,
    required this.backgroundColor,
    required this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ElevatedButton(
        onPressed: onPressed,
        child: textContent,
        style: ElevatedButton.styleFrom(
          primary: backgroundColor,
          textStyle: TextStyle(
            color: textColor,
          ),
          elevation: 5,
        ),
      ),
    );
  }
}

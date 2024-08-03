import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';



ElevatedButton customButton(BuildContext context, Function() onPressed, String btnText, Icon icon) {
  return ElevatedButton.icon(
    // Defines the style of the button
    style: ElevatedButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      // Foreground color
      foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
    ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0)),
    // Calls the handlePressed function when the button is pressed
    onPressed: onPressed,
    // Text to be displayed on the button
    label: Text(btnText),
    icon: icon,
  );
}
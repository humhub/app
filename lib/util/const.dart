import 'package:flutter/material.dart';

const progress = Center(child: CircularProgressIndicator());

class StorageKeys {
  static String humhubInstance = "humHubInstance";
  static String lastInstanceUrl = "humHubLastUrl";
}

class Locales {
  static String helpTitle = "What is HumHub?";
  static String helpFirstPar =
      'HumHub is an Open Source software used by organizations, associations and companies mainly as social network, intranet or communication platform.';
  static String helpSecPar =
      'The software digitizes organizational structures and helps people around the world to connect, communicate and facilitates daily collaboration. The HumHub App is intuitive to use and allows every user to access and browse their network from anywhere.';
  static String helpThirdPar =
      'The HumHub app is intuitive to use and allows you to access your network from anywhere. When notifications are enabled, you will also receive push notifications about important information within your network and can use the app to keep up to date with any relevant news at any time.';
  static String helpForthPar =
      'HumHub networks are basically private (internal to the organization) communication platforms. It is only possible to log in to existing networks for which you have corresponding login data. Organizations or companies can of course set up and run their own HumHub network at any time. All information can be found at';

  static String howToConnectTitle = "How can I connect my network?";
  static String howToConnectFirstPar =
      "There are many thousands of networks worldwide. Therefore, to log in to your existing network, you need the exact URL of your individual network.";
  static String howToConnectSecPar = "Your URL can be found in the address bar of your browser in the login area of your network.";
  static String howToConnectThirdPar = "Please contact your administrator or network operator if you do not know your URL or login details.";

  static String moreInfoTitle = "What is HumHub?";
  static String moreInfoFirstPar =
      'HumHub networks are basically closed communication platforms (internal to the organization). It is only possible to log into existing networks.';
  static String moreInfoSecPar = 'Organizations or companies can of course set up and operate their own HumHub network at any time.';
  static String moreInfoThirdPar = 'All information can be found here:';
  static String moreInfoProEdition = "Professional Edition";
  static String moreInfoProEditionUrl = "https://www.humhub.com/en/professional-edition";
}

Color openerColor = const Color(0xFF21a1b3);

TextStyle? getHeaderStyle(context) {
  return Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600);
}

TextStyle paragraphStyle = const TextStyle(letterSpacing: 0.5, fontWeight: FontWeight.normal, color: Colors.black);

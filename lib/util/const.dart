import 'package:flutter/material.dart';

const progress = Center(child: CircularProgressIndicator());

class StorageKeys{
  static String humhubInstance = "humHubInstance";
  static String lastInstanceUrl = "humHubLastUrl";
}

class Locales {
  static String helpFirstPar = 'HumHub is a German open source software that is mainly used by organizations, associations and companies as social network, intranet or communication platform. The software digitizes organizational structures and helps people around the world to connect, communicate and facilitate everyday collaboration. The HumHub app allows any user to log into existing networks and use them on the go. There are many thousands of instances worldwide. Therefore, to log in to your existing network, you need the exact URL of the network you are registered in. You can find this specific URL for example in the address bar of your internet browser in the login area when you log in to your network. This URL corresponds to this format: \nhttps://networkname.humhub.com/.';
  static String helpSecPar = 'After entering the matching URL in the login window of the mobile app, you can log in with your user name (alternatively e-mail address) and password. After logging in via the app for the first time, you will not need to enter the URL again in the future. Please contact your administrator or network operator if you do not know your URL or login credentials.';
  static String helpThirdPar = 'The HumHub app is intuitive to use and allows you to access your network from anywhere. When notifications are enabled, you will also receive push notifications about important information within your network and can use the app to keep up to date with any relevant news at any time.';
  static String helpForthPar = 'HumHub networks are basically private (internal to the organization) communication platforms. It is only possible to log in to existing networks for which you have corresponding login data. Organizations or companies can of course set up and run their own HumHub network at any time. All information can be found at';
}
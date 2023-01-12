import 'package:flutter/material.dart';
import 'Help.dart';
import 'WebView.dart';

class Opener extends StatefulWidget {
  @override
  _OpenerState createState() => _OpenerState();
}

class _OpenerState extends State<Opener> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 60.0),
              child: Center(
                child: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 20),
                    //width: 400,
                    //height: 150,
                    /*decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(50.0)),*/
                    child: Image.asset('assets/images/logo.png')),
              ),
            ),
            const Padding(
              //padding: const EdgeInsets.only(left:15.0,right: 15.0,top:0,bottom: 0),
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 50),
              child: TextField(
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'URL',
                    hintText: 'https://community.humhub.com'),
              ),
            ),
            Container(
              height: 50,
              width: 250,
              decoration: BoxDecoration(
                  color: Colors.blue, borderRadius: BorderRadius.circular(20)),
              child: TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const WebViewApp()),
                  );

                  //Navigator.push(context, MaterialPageRoute(builder: (_) => HomePage()));
                },
                child: const Text(
                  'Connect',
                  style: TextStyle(color: Colors.white, fontSize: 25),
                ),
              ),
            ),
            SizedBox(
              height: 130,
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  new MaterialPageRoute(builder: (context) => new Help()),
                );
              },
              child: const Text("Need Help?"),
            ),
          ],
        ),
      ),
    );
  }
}

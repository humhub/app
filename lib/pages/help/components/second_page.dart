import 'package:flutter/material.dart';
import 'package:humhub/components/ease_out_container.dart';
import 'package:humhub/util/const.dart';

class SecondPage extends StatelessWidget {
  final bool fadeIn;
  const SecondPage({Key? key, required this.fadeIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                Locales.howToConnectTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              Locales.howToConnectFirstPar,
              style: const TextStyle(letterSpacing: 0.5),
            ),
          ),
          EaseOutContainer(
            fadeIn: fadeIn,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Container(
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                  color: Colors.grey[200],
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 4,
                    ),
                    Icon(
                      Icons.public,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: 'https://',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                          TextSpan(
                            text: 'nameofnetwork.humhub.com',
                            style: TextStyle(
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              Locales.howToConnectSecPar,
              style: const TextStyle(letterSpacing: 0.5),
            ),
          ),
          EaseOutContainer(
            fadeIn: fadeIn,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width / 2,
                    height: 50,
                    decoration: BoxDecoration(color: openerColor, borderRadius: BorderRadius.circular(5)),
                    child: const Center(
                      child: Text(
                        'Connect',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              Locales.howToConnectThirdPar,
              style: const TextStyle(letterSpacing: 0.5),
            ),
          )
        ],
      ),
    );
  }
}

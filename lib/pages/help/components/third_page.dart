import 'package:flutter/material.dart';

import '../../../util/const.dart';

class ThirdPage extends StatelessWidget {
  const ThirdPage({Key? key}) : super(key: key);

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
                Locales.moreInfoTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              Locales.moreInfoFirstPar,
              style: const TextStyle(letterSpacing: 0.5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              Locales.moreInfoSecPar,
              style: const TextStyle(letterSpacing: 0.5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              Locales.moreInfoThirdPar,
              style: const TextStyle(letterSpacing: 0.5),
            ),
          ),
          const SizedBox(
            height: 40,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  /*Navigator.pop(context);*/
                },
                child: Container(
                  width: MediaQuery.of(context).size.width / 1.5,
                  height: 50,
                  decoration: BoxDecoration(color: openerColor, borderRadius: BorderRadius.circular(5)),
                  child: Center(
                    child: Text(
                      Locales.moreInfoProEdition,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

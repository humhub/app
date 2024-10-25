import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/models/manifest.dart';
import 'package:humhub/util/const.dart';
import 'package:humhub/util/providers.dart';
import 'package:loggy/loggy.dart';

class LastLoginWidget extends ConsumerWidget {
  final void Function()? onAddNetwork;

  const LastLoginWidget({super.key, this.onAddNetwork});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final humHub = ref.watch(humHubProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 22, horizontal: 10),
            child: Text(
              "Last login: ",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 120,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: humHub.history.length + 1, // Include the add network tile
            itemBuilder: (context, index) {
              if (index < humHub.history.length) {
                final manifest = humHub.history[index];
                return _buildLoginTile(manifest); // Replace with your notification logic
              } else {
                return _buildAddNetworkTile();
              }
            },
          ),
        ],
      ),
    );
  }

  // Tile for last login with badge
  Widget _buildLoginTile(Manifest manifest) {
    return Card(
      //color: HexColor(manifest.themeColor),
      surfaceTintColor: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        splashColor: HumhubTheme.primaryColor.withOpacity(0.3),
        highlightColor: HumhubTheme.primaryColor.withOpacity(0.3),
        hoverColor: HumhubTheme.primaryColor.withOpacity(0.3),
        onTap: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                logError("Here");
              },
              child: const Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: EdgeInsets.only(top: 10, left: 10),
                  child: Icon(
                    Icons.close,
                    size: 14,
                  ),
                ),
              ),
            ),
            if (manifest.icons?.isNotEmpty ?? false)
              CachedNetworkImage(
                height: 40,
                width: 40,
                imageUrl: manifest.baseUrl + manifest.icons!.reversed.first.src,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                manifest.name,
                style: const TextStyle(fontSize: 14),
              ),
            )
          ],
        ),
      ),
    );
  }

  // Tile for adding a network
  Widget _buildAddNetworkTile() {
    return Card(
      color: const Color(0XFFDBEFF0),
      surfaceTintColor: Colors.white,
      margin: const EdgeInsets.only(bottom: 25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          splashColor: HumhubTheme.primaryColor.withOpacity(0.3),
          highlightColor: HumhubTheme.primaryColor.withOpacity(0.3),
          hoverColor: HumhubTheme.primaryColor.withOpacity(0.3),
          onTap: onAddNetwork,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0XFF1A8291),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(Icons.add, size: 30, color: Colors.white),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "Add Network",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

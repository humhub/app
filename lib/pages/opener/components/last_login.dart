import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/util/const.dart';
import 'package:humhub/util/providers.dart';

class LastLoginWidget extends ConsumerWidget {
  final void Function()? onAddNetwork;

  const LastLoginWidget({super.key, this.onAddNetwork});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final humHub = ref.watch(humHubProvider);
    return Container(
      color: Colors.red,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              //crossAxisSpacing: 10,
              //mainAxisSpacing: 10,
            ),
            itemCount: humHub.history.length + 1, // Include the add network tile
            itemBuilder: (context, index) {
              if (index < humHub.history.length) {
                // Get the Manifest for the current index
                final manifest = humHub.history[index];
                return _buildLoginTile(manifest.name, Icons.business, 0); // Replace with your notification logic
              } else {
                // Last item for adding a network
                return _buildAddNetworkTile();
              }
            },
          ),
          SizedBox.shrink(),
        ],
      ),
    );
  }

  // Tile for last login with badge
  Widget _buildLoginTile(String title, IconData icon, int notifications) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        splashColor: HumhubTheme.primaryColor.withOpacity(0.3),
        highlightColor: HumhubTheme.primaryColor.withOpacity(0.3),
        hoverColor: HumhubTheme.primaryColor.withOpacity(0.3),
        onTap: () {},
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 50, color: Colors.blue),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (notifications > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    notifications.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Tile for adding a network
  Widget _buildAddNetworkTile() {
    return InkWell(
      onTap: onAddNetwork,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 50, color: Colors.grey),
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
    );
  }
}

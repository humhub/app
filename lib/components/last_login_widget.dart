import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humhub/models/hum_hub.dart';
import 'package:humhub/pages/web_view.dart';
import 'package:humhub/util/providers.dart';

class LastLoginWidget extends ConsumerWidget {
  final List<HumHub> networks;
  final VoidCallback onAddNetwork;

  const LastLoginWidget({super.key, required this.networks, required this.onAddNetwork});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.6,
        crossAxisSpacing: 10.0,
        mainAxisSpacing: 10.0,
      ),
      itemCount: networks.length + 1,
      itemBuilder: (context, index) {
        if (index < networks.length) {
          return NetworkCard(
            network: networks[index],
            onTap: () {
              Navigator.pushNamed(context, WebView.path, arguments: ref.watch(humHubProvider).manifest);
            },
          );
        } else {
          return AddNetworkCard(
            onTap: onAddNetwork,
          );
        }
      },
      shrinkWrap: true,
    );
  }
}

class NetworkCardData {
  final String logo;
  final String name;
  final int notificationCount;

  NetworkCardData({
    required this.logo,
    required this.name,
    this.notificationCount = 0,
  });
}

class NetworkCard extends StatelessWidget {
  final HumHub network;
  final VoidCallback onTap;

  const NetworkCard({Key? key, required this.network, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Close button aligned to the top left
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      // Handle close action
                    },
                    child: const Icon(
                      Icons.close,
                      size: 16.0,
                      color: Colors.grey,
                    ),
                  ),
                  if (30 > 0)
                    CircleAvatar(
                      radius: 10.0,
                      backgroundColor: Colors.red,
                      child: Text(
                        30.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 12.0),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              /*Image.network(
                network.manifest.baseUrl+ network.manifest.
                fit: BoxFit.cover,
              ),*/
              const SizedBox(height: 10.0),
              // Centered text
              Text(
                network.manifest?.name ?? "",
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class AddNetworkCard extends StatelessWidget {
  final VoidCallback onTap;

  const AddNetworkCard({super.key, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.add, size: 40.0, color: Colors.blue),
              SizedBox(height: 10.0),
              Text(
                "Add Network",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

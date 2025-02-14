import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:humhub/models/manifest.dart';
import 'package:humhub/util/const.dart';

class LastLoginWidget extends StatelessWidget {
  final List<Manifest> history;
  final void Function(Manifest manifest) onSelectNetwork;
  final void Function(Manifest manifest, bool isLast) onDeleteNetwork;
  final void Function()? onAddNetwork;

  const LastLoginWidget({
    super.key,
    required this.history,
    this.onAddNetwork,
    required this.onSelectNetwork,
    required this.onDeleteNetwork,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            shrinkWrap: true,
            itemCount: history.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: InstanceTile(
                  manifest: history[index],
                  onSelectNetwork: onSelectNetwork,
                  onDeleteNetwork: (manifest) => onDeleteNetwork(manifest, history.length == 1),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
          child: AddNetworkTile(onAddNetwork: onAddNetwork),
        )
      ],
    );
  }
}

class InstanceTile extends StatelessWidget {
  final Manifest manifest;
  final void Function(Manifest manifest) onSelectNetwork;
  final void Function(Manifest manifest) onDeleteNetwork;

  static const double borderRadius = 15;

  const InstanceTile({
    super.key,
    required this.manifest,
    required this.onSelectNetwork,
    required this.onDeleteNetwork,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(borderRadius),
      splashColor: HumhubTheme.primaryColor,
      highlightColor: HumhubTheme.primaryColor,
      onTap: () => onSelectNetwork(manifest),
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: Colors.red,
        ),
        child: Dismissible(
          key: Key(manifest.baseUrl),
          direction: DismissDirection.endToStart,
          background: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            alignment: Alignment.centerRight,
            child: const Padding(
              padding: EdgeInsets.only(right: 20),
              child: Icon(
                Icons.close,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
          onDismissed: (direction) {
            onDeleteNetwork(manifest);
          },
          child: Container(
            height: 65,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  spreadRadius: 2,
                  blurRadius: 2,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (manifest.icons?.isNotEmpty ?? false)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5), // Adjust the radius as needed
                    child: CachedNetworkImage(
                      height: 40,
                      width: 40,
                      imageUrl: manifest.baseUrl + manifest.icons!.reversed.first.src,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(width: 20),
                Text(
                  manifest.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AddNetworkTile extends StatelessWidget {
  final void Function()? onAddNetwork;

  static const double borderRadius = 10;

  const AddNetworkTile({
    super.key,
    required this.onAddNetwork,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(borderRadius),
      onTap: onAddNetwork,
      child: Container(
        height: 55,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 28, color: HumhubTheme.primaryColor),
            const SizedBox(width: 10),
            Text(
              AppLocalizations.of(context)!.add_network,
              style: TextStyle(fontSize: 16, color: HumhubTheme.primaryColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

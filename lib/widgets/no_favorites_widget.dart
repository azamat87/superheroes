import 'package:flutter/material.dart';
import 'package:superheroes/resources/superheroes_images.dart';
import 'package:superheroes/widgets/info_with_button.dart';

class NoFavoritesWidget extends StatelessWidget {
  final FocusNode focusNode;
  const NoFavoritesWidget({Key? key, required this.focusNode}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
        child: InfoWithButton(
      title: "No favorites yet",
      subtitle: "Search and add",
      buttonText: "Search",
      assetImage: SuperheroesImages.ironman,
      imageHeight: 119,
      imageWidth: 108,
      imageTopPadding: 9,
      onTap: () => focusNode.requestFocus(),
    ));
  }
}

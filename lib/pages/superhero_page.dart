
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:superheroes/resources/superheroes_colors.dart';
import 'package:superheroes/widgets/action_button.dart';

class SuperheroPage extends StatelessWidget {

  final String name;

  const SuperheroPage({super.key, required this.name});



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SuperheroesColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Text(
                name.toUpperCase(),
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: ActionButton(
                text: "Back",
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
            )
          ],
        ),
      ),
    );
  }


}
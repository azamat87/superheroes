import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:superheroes/blocs/superhero_bloc.dart';
import 'package:superheroes/model/biography.dart';
import 'package:superheroes/model/powerstats.dart';
import 'package:superheroes/model/superhero.dart';
import 'package:superheroes/resources/superheroes_colors.dart';
import 'package:http/http.dart' as http;
import 'package:superheroes/resources/superheroes_icons.dart';
import 'package:superheroes/resources/superheroes_images.dart';
import 'package:superheroes/widgets/info_with_button.dart';
import 'package:superheroes/widgets/superhero_card.dart';

class SuperheroPage extends StatefulWidget {
  final http.Client? client;
  final String id;

  SuperheroPage({Key? key, this.client, required this.id}) : super(key: key);

  @override
  State<SuperheroPage> createState() => _SuperheroPageState();
}

class _SuperheroPageState extends State<SuperheroPage> {
  late SuperheroBloc bloc;

  @override
  void initState() {
    super.initState();
    bloc = SuperheroBloc(client: widget.client, id: widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: bloc,
      child: Scaffold(
          backgroundColor: SuperheroesColors.background,
          body: SuperheroContentPage()),
    );
  }

  @override
  void dispose() {
    super.dispose();
    bloc.dispose();
  }
}

class SuperheroContentPage extends StatelessWidget {
  const SuperheroContentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<SuperheroBloc>(context, listen: false);
    return StreamBuilder<SuperheroPageState>(
      stream: bloc.observeSuperheroPageState(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return SizedBox.shrink();
        }
        final state = snapshot.data;
        switch(state){
          case SuperheroPageState.loading: {
            return SuperheroLoadingWidget();
          }
          case SuperheroPageState.loaded: {
            return SuperheroLoadedPage();
          }
          case SuperheroPageState.error:
          default:
            return SuperheroErrorWidget();
        }
      }
    );
  }
}

class SuperheroErrorWidget extends StatelessWidget {
  const SuperheroErrorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<SuperheroBloc>(context, listen: false);
    return CustomScrollView(
      slivers: [
        const SliverAppBar(backgroundColor: SuperheroesColors.background,),
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.only(top: 60),
            alignment: Alignment.topCenter,
            child: InfoWithButton(
              title: "Error happened",
              subtitle: "Please, try again",
              buttonText: "Retry",
              assetImage: SuperheroesImages.superman,
              imageHeight: 106,
              imageWidth: 126,
              imageTopPadding: 22,
              onTap: bloc.retry,
            ),
          ),
        )
      ],
    );
  }

}

class SuperheroLoadingWidget extends StatelessWidget {
  const SuperheroLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverAppBar(backgroundColor: SuperheroesColors.background,),
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.only(top: 60),
            alignment: Alignment.topCenter,
            height: 44,
            width: 44,
            child: const CircularProgressIndicator(
              color: SuperheroesColors.blue,
            ),
          ),
        )
      ],
    );
  }

}

class SuperheroLoadedPage extends StatelessWidget {
  const SuperheroLoadedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<SuperheroBloc>(context, listen: false);
    return StreamBuilder<Superhero>(
        stream: bloc.superheroSubject,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return SizedBox.shrink();
          }
          final superhero = snapshot.data!;
          return CustomScrollView(
            slivers: [
              SuperheroAppBar(superhero: superhero),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(
                      height: 30,
                    ),
                    if (superhero.powerstats.isNotNull())
                      PowerstatsWidget(powerstats: superhero.powerstats),
                    BiographyWidget(biography: superhero.biography),
                    const SizedBox(height: 30.5),
                  ],
                ),
              )
            ],
          );
        });
  }
}



class BiographyWidget extends StatelessWidget {
  final Biography biography;

  const BiographyWidget({super.key, required this.biography});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          color: SuperheroesColors.indigo,
          borderRadius: BorderRadius.circular(20)),
      child: Stack(
        children: [
          Padding(
            padding:
                const EdgeInsets.only(right: 16, left: 16, top: 16, bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Text(
                    "Bio".toUpperCase(),
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Colors.white),
                  ),
                ),
                BioFields(title: "Full Name", text: biography.fullName),
                const SizedBox(
                  height: 19.5,
                ),
                BioFields(title: "Aliases", text: biography.aliases.join(", ")),
                const SizedBox(
                  height: 20,
                ),
                BioFields(
                    title: "Place of birth", text: biography.placeOfBirth),
              ],
            ),
          ),
          if (biography.alignmentInfo != null)
            Align(
              alignment: Alignment.topRight,
              child: AlignmentWidget(
                alignmentInfo: biography.alignmentInfo!,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20)),
              ),
            )
        ],
      ),
    );
  }
}

class BioFields extends StatelessWidget {
  final String title;
  final String text;

  const BioFields({super.key, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: SuperheroesColors.grey2),
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w400, color: Colors.white),
        )
      ],
    );
  }
}

class PowerstatsWidget extends StatelessWidget {
  final Powerstats powerstats;

  const PowerstatsWidget({super.key, required this.powerstats});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Text(
            "Powerstats".toUpperCase(),
            style: TextStyle(
                fontWeight: FontWeight.w700, color: Colors.white, fontSize: 18),
          ),
        ),
        const SizedBox(
          height: 24,
        ),
        Row(
          children: [
            SizedBox(width: 16),
            Expanded(
                child: Center(
              child: PowerstatWidget(
                name: "Intelligence",
                value: powerstats.intelligencePercent,
              ),
            )),
            Expanded(
                child: Center(
              child: PowerstatWidget(
                name: "Strength",
                value: powerstats.strengthPercent,
              ),
            )),
            Expanded(
                child: Center(
              child: PowerstatWidget(
                name: "Speed",
                value: powerstats.speedPercent,
              ),
            )),
            SizedBox(width: 16),
          ],
        ),
        const SizedBox(
          height: 20,
        ),
        Row(
          children: [
            SizedBox(width: 16),
            Expanded(
                child: Center(
              child: PowerstatWidget(
                name: "Durability",
                value: powerstats.durabilityPercent,
              ),
            )),
            Expanded(
                child: Center(
              child: PowerstatWidget(
                name: "Power",
                value: powerstats.powerPercent,
              ),
            )),
            Expanded(
                child: Center(
              child: PowerstatWidget(
                name: "Combat",
                value: powerstats.combatPercent,
              ),
            )),
            SizedBox(width: 16),
          ],
        ),
        const SizedBox(
          height: 36,
        )
      ],
    );
  }
}

class PowerstatWidget extends StatelessWidget {
  final String name;
  final double value;

  const PowerstatWidget({super.key, required this.name, required this.value});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        ArcWidget(value: value, color: calculateColorByValue()),
        Padding(
          padding: const EdgeInsets.only(top: 17),
          child: Text(
            "${(value * 100).toInt()}",
            style: TextStyle(
                color: calculateColorByValue(),
                fontWeight: FontWeight.w800,
                fontSize: 18),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 44),
          child: Text(
            name.toUpperCase(),
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        )
      ],
    );
  }

  Color calculateColorByValue() {
    if (value <= 0.5) {
      return Color.lerp(Colors.red, Colors.orangeAccent, value / 0.5)!;
    } else {
      return Color.lerp(
          Colors.orangeAccent, Colors.green, (value - 0.5) / 0.5)!;
    }
  }
}

class ArcWidget extends StatelessWidget {
  final double value;
  final Color color;

  const ArcWidget({super.key, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ArcCustomPainter(value, color),
      size: Size(66, 33),
    );
  }
}

class ArcCustomPainter extends CustomPainter {
  final double value;
  final Color color;

  ArcCustomPainter(this.value, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height * 2);
    final background = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6;
    canvas.drawArc(rect, pi, pi, false, background);
    canvas.drawArc(rect, pi, pi * value, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is ArcCustomPainter) {
      return oldDelegate.value != value && oldDelegate.color != color;
    }
    return true;
  }
}

class SuperheroAppBar extends StatelessWidget {
  const SuperheroAppBar({
    super.key,
    required this.superhero,
  });

  final Superhero superhero;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      stretch: true,
      pinned: true,
      floating: true,
      expandedHeight: 348,
      backgroundColor: SuperheroesColors.background,
      actions: [
        FavoriteButton(),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          superhero.name,
          style: TextStyle(
              fontWeight: FontWeight.w800, color: Colors.white, fontSize: 22),
        ),
        background: CachedNetworkImage(
          imageUrl: superhero.image.url,
          fit: BoxFit.cover,
          placeholder: (_, url) {
            return ColoredBox(
              color: SuperheroesColors.indigo,
            );
          },
          errorWidget: (context, url, error) {
            return Container(
              alignment: Alignment.center,
              color: SuperheroesColors.indigo,
              child: Image.asset(
                SuperheroesImages.unknownBig,
                height: 264,
                width: 85,
              ),
            );
          },
        ),
      ),
      centerTitle: true,
    );
  }
}

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<SuperheroBloc>(context, listen: false);

    return StreamBuilder<bool>(
      stream: bloc.observeIsFavorite(),
      initialData: false,
      builder: (context, snapshot) {
        final favorite =
            !snapshot.hasData || snapshot.data == null || snapshot.data!;
        return GestureDetector(
          onTap: () =>
              favorite ? bloc.removeFromFavorites() : bloc.addToFavorite(),
          child: Container(
            height: 52,
            width: 52,
            alignment: Alignment.center,
            child: Image.asset(
              favorite
                  ? SuperheroesIcons.starFilled
                  : SuperheroesIcons.starEmpty,
              height: 32,
              width: 32,
            ),
          ),
        );
      },
    );
  }
}

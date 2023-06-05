import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:superheroes/blocs/main_bloc.dart';
import 'package:superheroes/pages/superhero_page.dart';
import 'package:superheroes/resources/superheroes_colors.dart';
import 'package:superheroes/resources/superheroes_images.dart';
import 'package:superheroes/widgets/action_button.dart';
import 'package:superheroes/widgets/info_with_button.dart';
import 'package:superheroes/widgets/no_favorites_widget.dart';
import 'package:superheroes/widgets/superhero_card.dart';

class MainPage extends StatefulWidget {
  MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class MainBlocHolder extends InheritedWidget {
  final MainBloc bloc;

  MainBlocHolder({super.key, required this.bloc, required final Widget child})
      : super(child: child);

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;

  static MainBlocHolder of(final BuildContext context) {
    final InheritedElement element =
        context.getElementForInheritedWidgetOfExactType<MainBlocHolder>()!;
    return element.widget as MainBlocHolder;
  }
}

class _MainPageState extends State<MainPage> {
  MainBloc bloc = MainBloc();

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: bloc,
      child: Scaffold(
          backgroundColor: SuperheroesColors.background,
          body: SafeArea(child: MainPageContent())),
    );
  }

  @override
  void dispose() {
    super.dispose();
    bloc.dispose();
  }
}

class MainPageContent extends StatelessWidget {
  const MainPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    final MainBloc bloc = Provider.of<MainBloc>(context);

    return Stack(
      children: [
        MainPageStateWidget(),
        Align(
          alignment: Alignment.bottomCenter,
          child: ActionButton(
            onTap: () {
              bloc.nextState();
            },
            text: "Next state",
          ),
        )
      ],
    );
  }
}

class MainPageStateWidget extends StatelessWidget {
  const MainPageStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final MainBloc bloc = Provider.of<MainBloc>(context);

    return StreamBuilder<MainPageState>(
      stream: bloc.observeMainPageState(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return SizedBox();
        }
        final MainPageState state = snapshot.data!;
        switch (state) {
          case MainPageState.loading:
            return LoadingIndicator();
          case MainPageState.noFavorites:
            return NoFavoritesWidget();
          case MainPageState.minSymbols:
            return MinSymbolsWidget();
          case MainPageState.favorites:
            return FavoritesWidget();
          case MainPageState.nothingFound:
            return NothingFoundWidget();
          case MainPageState.loadingError:
            return LoadingErrorWidget();
          case MainPageState.searchResults:
            return SearchResultsWidget();
          default:
            return Center(
                child: Text(
              snapshot.data.toString(),
              style: TextStyle(color: Colors.white),
            ));
        }
      },
    );
  }
}

class FavoritesWidget extends StatelessWidget {
  const FavoritesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 90),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Your favorites",
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 24),
          ),
        ),
        SizedBox(
          height: 20,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: SuperheroCard(
            name: "Batman",
            realName: "Bruce Wayne",
            imageUrl:
                "https://www.superherodb.com/pictures2/portraits/10/100/639.jpg",
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => SuperheroPage(name: "Batman")
              ));
            },
          ),
        ),
        SizedBox(
          height: 8,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: SuperheroCard(
            name: "Ironman",
            realName: "Tony Stark",
            imageUrl:
                "https://www.superherodb.com/pictures2/portraits/10/100/85.jpg",
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => SuperheroPage(name: "Ironman")
              ));
            },
          ),
        ),
      ],
    );
  }
}

class SearchResultsWidget extends StatelessWidget {
  const SearchResultsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 90),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Your favorites",
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 24),
          ),
        ),
        SizedBox(
          height: 20,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: SuperheroCard(
              name: "Batman",
              realName: "Bruce Wayne",
              imageUrl:
                  "https://www.superherodb.com/pictures2/portraits/10/100/639.jpg",
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => SuperheroPage(name: "Batman")
                ));
              }),
        ),
        SizedBox(
          height: 8,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: SuperheroCard(
            name: "Venom",
            realName: "Eddie Brock",
            imageUrl:
                "https://www.superherodb.com/pictures2/portraits/10/100/22.jpg",
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => SuperheroPage(name: "Venom")
              ));
            },
          ),
        ),
      ],
    );
  }
}

class MinSymbolsWidget extends StatelessWidget {
  const MinSymbolsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(top: 110.0),
        child: Text(
          "Enter at least 3 symbols",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 20),
        ),
      ),
    );
  }
}

class LoadingErrorWidget extends StatelessWidget {
  const LoadingErrorWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
        child: InfoWithButton(
            title: "Error happened",
            subtitle: "Please, try again",
            buttonText: "Retry",
            assetImage: SuperheroesImages.superman,
            imageHeight: 106,
            imageWidth: 126,
            imageTopPadding: 22
        )
    );
  }
}

class NothingFoundWidget extends StatelessWidget {
  const NothingFoundWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
        child: InfoWithButton(
            title: "Nothing found",
            subtitle: "Search for something else",
            buttonText: "Search",
            assetImage: SuperheroesImages.hulk,
            imageHeight: 112,
            imageWidth: 84,
            imageTopPadding: 16
        )
    );
  }
}

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(top: 110),
        child: CircularProgressIndicator(
          color: SuperheroesColors.blue,
          strokeWidth: 4,
        ),
      ),
    );
  }
}

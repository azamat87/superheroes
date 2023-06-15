import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:superheroes/blocs/main_bloc.dart';
import 'package:superheroes/model/superhero.dart';
import 'package:superheroes/pages/superhero_page.dart';
import 'package:superheroes/resources/superheroes_colors.dart';
import 'package:superheroes/resources/superheroes_images.dart';
import 'package:superheroes/widgets/action_button.dart';
import 'package:superheroes/widgets/info_with_button.dart';
import 'package:superheroes/widgets/no_favorites_widget.dart';
import 'package:superheroes/widgets/superhero_card.dart';
import 'package:http/http.dart' as http;

class MainPage extends StatefulWidget {
  final http.Client? client;

  MainPage({Key? key, this.client}) : super(key: key);

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
  late MainBloc bloc;

  @override
  void initState() {
    super.initState();
    bloc = MainBloc(client: widget.client);
  }

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

class MainPageContent extends StatefulWidget {
  @override
  State<MainPageContent> createState() => _MainPageContentState();
}

class _MainPageContentState extends State<MainPageContent> {
  late final FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MainPageStateWidget(
          focusNode: _searchFocusNode,
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16, left: 16, top: 12),
          child: SearchWidget(searchFieldFocusNode: _searchFocusNode),
        )
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
    _searchFocusNode.dispose();
  }
}

class SearchWidget extends StatefulWidget {
  final FocusNode searchFieldFocusNode;

  const SearchWidget({super.key, required this.searchFieldFocusNode});

  @override
  State<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  final TextEditingController controller = TextEditingController();
  bool haveSearchedText = false;

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      MainBloc bloc = Provider.of<MainBloc>(context, listen: false);
      controller.addListener(() {
        bloc.updateText(controller.text);
        final haveText = controller.text.isNotEmpty;
        if (haveSearchedText != haveText) {
          setState(() {
            haveSearchedText = haveText;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final MainBloc bloc = Provider.of<MainBloc>(context, listen: false);

    return TextField(
      focusNode: widget.searchFieldFocusNode,
      cursorColor: Colors.white,
      textInputAction: TextInputAction.search,
      textCapitalization: TextCapitalization.words,
      controller: controller,
      onChanged: (text) => {bloc.updateText(text)},
      style: TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 20,
        color: Colors.white,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: SuperheroesColors.indigo75,
        isDense: true,
        prefixIcon: Icon(
          Icons.search,
          color: Colors.white54,
          size: 24,
        ),
        suffix: GestureDetector(
          child: Icon(
            Icons.clear,
            color: Colors.white,
          ),
          onTap: () => controller.clear(),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: haveSearchedText
              ? BorderSide(color: Colors.white, width: 2)
              : BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white, width: 2),
        ),
      ),
    );
  }
}

class MainPageStateWidget extends StatelessWidget {
  final FocusNode focusNode;

  const MainPageStateWidget({super.key, required this.focusNode});

  @override
  Widget build(BuildContext context) {
    final MainBloc bloc = Provider.of<MainBloc>(context, listen: false);

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
            return NoFavoritesWidget(focusNode: focusNode);
          case MainPageState.minSymbols:
            return MinSymbolsWidget();
          case MainPageState.favorites:
            return SuperheroesList(
              title: "Your favorites",
              stream: bloc.observeFavoriteSuperheroes(),
              ableToSwipe: true,
            );
          case MainPageState.nothingFound:
            return NothingFoundWidget(
              focusNode: focusNode,
            );
          case MainPageState.loadingError:
            return LoadingErrorWidget();
          case MainPageState.searchResults:
            return SuperheroesList(
              ableToSwipe: false,
              title: "Search results",
              stream: bloc.observeSearchSuperheroes(),
            );
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

class SuperheroesList extends StatelessWidget {
  final String title;
  final Stream<List<SuperheroInfo>> stream;
  final bool ableToSwipe;

  const SuperheroesList(
      {super.key,
      required this.title,
      required this.stream,
      required this.ableToSwipe});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SuperheroInfo>>(
        stream: stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return const SizedBox.shrink();
          }

          final List<SuperheroInfo> superheroes = snapshot.data!;
          return ListView.separated(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            itemCount: superheroes.length + 1,
            itemBuilder: (BuildContext context, int index) {
              if (index == 0) {
                return ListTitleWidget(title: title);
              }
              final SuperheroInfo item = superheroes[index - 1];
              return ListTile(
                superhero: item,
                ableToSwipe: ableToSwipe,
              );
            },
            separatorBuilder: (BuildContext context, int index) {
              return const SizedBox(height: 8);
            },
          );
        });
  }
}

class ListTile extends StatelessWidget {
  final SuperheroInfo superhero;
  final bool ableToSwipe;

  const ListTile(
      {super.key, required this.superhero, required this.ableToSwipe});

  @override
  Widget build(BuildContext context) {
    final MainBloc bloc = Provider.of<MainBloc>(context, listen: false);

    if (ableToSwipe) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Dismissible(
          key: ValueKey(superhero.id),
          child: SuperheroCard(
              superheroInfo: superhero,
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => SuperheroPage(id: superhero.id)));
              }),
          background: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: SuperheroesColors.red),
            child: Text(
              "Remove\nfrom\nfavorites".toUpperCase(),
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w700),
            ),
          ),
          secondaryBackground: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerRight,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: SuperheroesColors.red),
            child: Text(
              "Remove\nfrom\nfavorites".toUpperCase(),
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w700),
            ),
          ),
          onDismissed: (_) => bloc.removeFromFavorites(superhero.id),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SuperheroCard(
            superheroInfo: superhero,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => SuperheroPage(id: superhero.id)));
            }),
      );
    }
  }
}

class ListTitleWidget extends StatelessWidget {
  final String title;

  const ListTitleWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 90, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 24),
      ),
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
    final MainBloc mainBloc = Provider.of<MainBloc>(context, listen: false);
    return Center(
        child: InfoWithButton(
      title: "Error happened",
      subtitle: "Please, try again",
      buttonText: "Retry",
      assetImage: SuperheroesImages.superman,
      imageHeight: 106,
      imageWidth: 126,
      imageTopPadding: 22,
      onTap: mainBloc.retry,
    ));
  }
}

class NothingFoundWidget extends StatelessWidget {
  final FocusNode focusNode;

  const NothingFoundWidget({Key? key, required this.focusNode})
      : super(key: key);

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
      imageTopPadding: 16,
      onTap: () => focusNode.requestFocus(),
    ));
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

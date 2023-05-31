import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:superheroes/blocs/MainBloc.dart';
import 'package:superheroes/resources/superheroes_colors.dart';

class MainPage extends StatefulWidget {
  MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class MainBlocHolder extends InheritedWidget {
  
  final MainBloc bloc;
  
  MainBlocHolder({ required this.bloc, required final Widget child}): super(child: child);

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;

  static MainBlocHolder of(final BuildContext context) {
    final InheritedElement element = context.getElementForInheritedWidgetOfExactType<MainBlocHolder>()!;
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
          body: SafeArea(
              child: MainPageContent())),
    );
  }

  @override
  void dispose() {
    super.dispose();
    bloc.dispose();
  }
}

class MainPageContent extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final MainBloc bloc = Provider.of<MainBloc>(context);

    return Stack(
      children: [
        MainPageStateWidget(),
        Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {
              bloc.nextState();
            },
            child: Text(
              "Next step".toUpperCase(),
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
          ),
        )
      ],
    );
  }
}

class MainPageStateWidget extends StatelessWidget {

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
          case MainPageState.minSymbols:
          case MainPageState.nothingFound:
          case MainPageState.loadingError:
          case MainPageState.searchResults:
          case MainPageState.favorites:
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

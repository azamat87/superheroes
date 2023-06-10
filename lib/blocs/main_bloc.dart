import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rxdart/rxdart.dart';
import 'package:http/http.dart' as http;
import 'package:superheroes/exception/api_exception.dart';
import 'dart:convert';

import 'package:superheroes/model/superhero.dart';

class MainBloc {
  static const minSymbols = 3;

  final BehaviorSubject<MainPageState> stateSubject = BehaviorSubject();
  final favoritesSuperheroesSubject =
      BehaviorSubject<List<SuperheroInfo>>.seeded(SuperheroInfo.mocked);
  final searchedSuperheroesSubject = BehaviorSubject<List<SuperheroInfo>>();
  final currentTextSubject = BehaviorSubject<String>.seeded("");
  StreamSubscription? textSubscription;
  StreamSubscription? searchSubscription;

  http.Client? client;

  // Stream<MainPageState>? observeMainPageState() => stateSubject;
  // StreamSubscription<MainPageState>? stateSubscription;

  MainBloc({this.client}) {
    stateSubject.add(MainPageState.noFavorites);
    textSubscription =
        Rx.combineLatest2<String, List<SuperheroInfo>, MainPageStateInfo>(
                currentTextSubject
                    .distinct()
                    .debounceTime(const Duration(milliseconds: 500)),
                favoritesSuperheroesSubject,
                (searchText, favorites) =>
                    MainPageStateInfo(searchText, favorites.isNotEmpty))
            .listen((value) {
      searchSubscription?.cancel();
      if (value.searchText.isEmpty) {
        if (value.haveFavorites) {
          stateSubject.add(MainPageState.favorites);
        } else {
          stateSubject.add(MainPageState.noFavorites);
        }
      } else if (value.searchText.length < minSymbols) {
        stateSubject.add(MainPageState.minSymbols);
      } else {
        searchForSuperheroes(value.searchText);
      }
    });
  }

  Stream<List<SuperheroInfo>> observeFavoriteSuperheroes() =>
      favoritesSuperheroesSubject;

  Stream<List<SuperheroInfo>> observeSearchSuperheroes() =>
      searchedSuperheroesSubject;

  Stream<MainPageState> observeMainPageState() => stateSubject;

  void searchForSuperheroes(final String text) {
    stateSubject.add(MainPageState.loading);
    searchSubscription = search(text).asStream().listen((searchResult) {
      if (searchResult.isEmpty) {
        stateSubject.add(MainPageState.nothingFound);
      } else {
        searchedSuperheroesSubject.add(searchResult);
        stateSubject.add(MainPageState.searchResults);
      }
    }, onError: (error, stackTrace) {
      stateSubject.add(MainPageState.loadingError);
    });
  }

  void nextState() {
    final currentState = stateSubject.value;
    final nextState = MainPageState.values[
        (MainPageState.values.indexOf(currentState) + 1) %
            MainPageState.values.length];
    stateSubject.add(nextState);
  }

  void updateText(final String? text) {
    currentTextSubject.add(text ?? "");
  }

  void removeFavorite() {
    final List<SuperheroInfo> current = favoritesSuperheroesSubject.value;
    if (current.isEmpty) {
      favoritesSuperheroesSubject.add(SuperheroInfo.mocked);
    } else {
      favoritesSuperheroesSubject.add(current.sublist(0, current.length - 1));
    }
  }

  void dispose() {
    stateSubject.close();
    favoritesSuperheroesSubject.close();
    searchedSuperheroesSubject.close();
    currentTextSubject.close();
    searchSubscription?.cancel();
    client?.close();
  }

  void retry() {
    searchForSuperheroes(currentTextSubject.value);
  }

  Future<List<SuperheroInfo>> search(String text) async {
    await Future.delayed(const Duration(seconds: 1));
    final token = dotenv.env["SUPERHERO_TOKEN"];

    final response = await (client ??= http.Client()).get(Uri.parse("https://superheroapi.com/api/$token/search/$text"));
    final statusCode = response.statusCode;
    if (statusCode >= 500 && statusCode <= 599) {
      throw ApiException("Server error happened");
    }
    if (statusCode >= 400 && statusCode <= 499) {
      throw ApiException("Client error happened");
    }

    final decode = json.decode(response.body);
    if (decode['response'] == 'success') {
      final List<dynamic> results = decode['results'];
      final List<Superhero> superheroes = results.map((e) => Superhero.fromJson(e)).toList();
      final List<SuperheroInfo> found = superheroes.map((e) {
        return SuperheroInfo(
            name: e.name,
            realName: e.biography.fullName,
            imageUrl: e.image.url);
      }).toList();
      return found;
    } else if (decode['response'] == 'error') {
      if (decode['error'] == 'character with given name not found') {
        return [];
      }
      throw ApiException("Client error happened");
    }
    throw ApiException("Unknown error happened");
  }
}

enum MainPageState {
  noFavorites,
  minSymbols,
  loading,
  nothingFound,
  loadingError,
  searchResults,
  favorites
}

class MainPageStateInfo {
  final String searchText;
  final bool haveFavorites;

  const MainPageStateInfo(this.searchText, this.haveFavorites);

  @override
  String toString() {
    return 'MainPageInfState{searchText: $searchText, haveFavorites: $haveFavorites}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MainPageStateInfo &&
          runtimeType == other.runtimeType &&
          searchText == other.searchText &&
          haveFavorites == other.haveFavorites;

  @override
  int get hashCode => searchText.hashCode ^ haveFavorites.hashCode;
}

class SuperheroInfo {
  final String name;
  final String realName;
  final String imageUrl;

  const SuperheroInfo(
      {required this.name, required this.realName, required this.imageUrl});

  @override
  String toString() {
    return 'SuperheroInfo{name: $name, realName: $realName, imageUrl: $imageUrl}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SuperheroInfo &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          realName == other.realName &&
          imageUrl == other.imageUrl;

  @override
  int get hashCode => name.hashCode ^ realName.hashCode ^ imageUrl.hashCode;

  static const mocked = [
    SuperheroInfo(
        name: "Batman",
        realName: "Bruce Wayne",
        imageUrl:
            "https://www.superherodb.com/pictures2/portraits/10/100/639.jpg"),
    SuperheroInfo(
        name: "Ironman",
        realName: "Tony Stark",
        imageUrl:
            "https://www.superherodb.com/pictures2/portraits/10/100/85.jpg"),
    SuperheroInfo(
        name: "Venom",
        realName: "Eddie Brock",
        imageUrl:
            "https://www.superherodb.com/pictures2/portraits/10/100/22.jpg"),
  ];
}

import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rxdart/rxdart.dart';
import 'package:http/http.dart' as http;
import 'package:superheroes/exception/api_exception.dart';
import 'package:superheroes/favorite_superhero_storage.dart';
import 'package:superheroes/model/alignment_info.dart';
import 'dart:convert';

import 'package:superheroes/model/superhero.dart';

class MainBloc {
  static const minSymbols = 3;

  final BehaviorSubject<MainPageState> stateSubject = BehaviorSubject();
  final searchedSuperheroesSubject = BehaviorSubject<List<SuperheroInfo>>();
  final currentTextSubject = BehaviorSubject<String>.seeded("");

  StreamSubscription? textSubscription;
  StreamSubscription? searchSubscription;
  StreamSubscription? removeFromFavoriteSubscription;


  http.Client? client;

  // Stream<MainPageState>? observeMainPageState() => stateSubject;
  // StreamSubscription<MainPageState>? stateSubscription;

  MainBloc({this.client}) {
    textSubscription =
        Rx.combineLatest2<String, List<Superhero>, MainPageStateInfo>(
            currentTextSubject
                .distinct()
                .debounceTime(const Duration(milliseconds: 500)),
            FavoriteSuperheroStorage.getInstance().observeFavoriteSuperheroes(),
            (searchText, favorites) =>
                MainPageStateInfo(searchText, favorites.isNotEmpty)).listen(
            (value) {
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
      FavoriteSuperheroStorage.getInstance()
          .observeFavoriteSuperheroes()
          .map((superheroes) => superheroes.map((superhero) => SuperheroInfo.fromSuperhero(superhero)).toList());

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

  void removeFromFavorites(final String id) {
    removeFromFavoriteSubscription?.cancel();
    removeFromFavoriteSubscription = FavoriteSuperheroStorage.getInstance()
        .removeFromFavorites(id)
        .asStream()
        .listen((event) {
      print("$event");
    }, onError: (error, stack) {
      print("error");
    });
  }

  void dispose() {
    stateSubject.close();
    searchedSuperheroesSubject.close();
    currentTextSubject.close();
    searchSubscription?.cancel();
    removeFromFavoriteSubscription?.cancel();
    client?.close();
  }

  void retry() {
    searchForSuperheroes(currentTextSubject.value);
  }

  Future<List<SuperheroInfo>> search(String text) async {
    final token = dotenv.env["SUPERHERO_TOKEN"];

    final response = await (client ??= http.Client())
        .get(Uri.parse("https://superheroapi.com/api/$token/search/$text"));
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
      final List<Superhero> superheroes =
          results.map((e) => Superhero.fromJson(e)).toList();
      final List<SuperheroInfo> found = superheroes.map((element) {
        return SuperheroInfo.fromSuperhero(element);
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
  final String id;
  final String name;
  final String realName;
  final String imageUrl;
  final AlignmentInfo? alignmentInfo;

  const SuperheroInfo(
      {required this.id,
      required this.name,
      required this.realName,
      required this.imageUrl,
      required this.alignmentInfo});

  factory SuperheroInfo.fromSuperhero(final Superhero superhero) {
    return SuperheroInfo(
        id: superhero.id,
        name: superhero.name,
        realName: superhero.biography.fullName,
        imageUrl: superhero.image.url,
        alignmentInfo: superhero.biography.alignmentInfo
    );
  }

  @override
  String toString() {
    return 'SuperheroInfo{name: $name, realName: $realName, imageUrl: $imageUrl}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SuperheroInfo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          realName == other.realName &&
          imageUrl == other.imageUrl;

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ realName.hashCode ^ imageUrl.hashCode;
  static const mocked = [
    SuperheroInfo(
        id: "70",
        name: "Batman",
        realName: "Bruce Wayne",
        imageUrl:
            "https://www.superherodb.com/pictures2/portraits/10/100/639.jpg", alignmentInfo: null),
    SuperheroInfo(
        id: "732",
        name: "Ironman",
        realName: "Tony Stark",
        imageUrl:
            "https://www.superherodb.com/pictures2/portraits/10/100/85.jpg", alignmentInfo: null),
    SuperheroInfo(
        id: "687",
        name: "Venom",
        realName: "Eddie Brock",
        imageUrl:
            "https://www.superherodb.com/pictures2/portraits/10/100/22.jpg", alignmentInfo: null),
  ];
}

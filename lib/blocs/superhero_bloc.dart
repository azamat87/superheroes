import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rxdart/rxdart.dart';
import 'package:http/http.dart' as http;
import 'package:superheroes/exception/api_exception.dart';
import 'package:superheroes/favorite_superhero_storage.dart';
import 'dart:convert';

import 'package:superheroes/model/superhero.dart';

class SuperheroBloc {
  http.Client? client;
  String id;

  final superheroSubject = BehaviorSubject<Superhero>();
  final superheroPageStateSubject = BehaviorSubject<SuperheroPageState>();
  StreamSubscription? getFromFavoritesSubscription;
  StreamSubscription? requestSubscription;
  StreamSubscription? addToFavoriteSubscription;
  StreamSubscription? removeFromFavoriteSubscription;

  SuperheroBloc({this.client, required this.id}) {
    getFromFavorites();
  }

  Stream<Superhero> observeSuperhero() => superheroSubject.distinct();
  Stream<SuperheroPageState> observeSuperheroPageState() => superheroPageStateSubject.distinct();

  Stream<bool> observeIsFavorite() =>
      FavoriteSuperheroStorage.getInstance().observeIsFavorites(id);

  void requestSuperhero(final bool isInFavorites) {
    requestSubscription?.cancel();
    requestSubscription = request().asStream().listen((superhero) {
      superheroSubject.add(superhero);
      superheroPageStateSubject.add(SuperheroPageState.loaded);
    }, onError: (error, stackTrace) {
      if (!isInFavorites) {
        superheroPageStateSubject.add(SuperheroPageState.error);
      }
      print("Error $error");
    });
  }

  Future<Superhero> request() async {
    final token = dotenv.env["SUPERHERO_TOKEN"];
    final response = await (client ??= http.Client())
        .get(Uri.parse("https://superheroapi.com/api/$token/$id"));
    final statusCode = response.statusCode;
    if (statusCode >= 500 && statusCode <= 599) {
      throw ApiException("Server error happened");
    }
    if (statusCode >= 400 && statusCode <= 499) {
      throw ApiException("Client error happened");
    }

    final decode = json.decode(response.body);
    if (decode['response'] == 'success') {
      final superhero = Superhero.fromJson(decode);
      await FavoriteSuperheroStorage.getInstance().updateIfInFavorite(superhero);
      return superhero;
    } else if (decode['response'] == 'error') {
      throw ApiException("Client error happened");
    }
    throw ApiException("Unknown error happened");
  }

  void getFromFavorites() {
    getFromFavoritesSubscription?.cancel();
    getFromFavoritesSubscription = FavoriteSuperheroStorage.getInstance()
        .getSuperhero(id)
        .asStream()
        .listen((superhero) {
      if (superhero != null) {
        superheroSubject.add(superhero);
        superheroPageStateSubject.add(SuperheroPageState.loaded);
      } else {
        superheroPageStateSubject.add(SuperheroPageState.loading);
      }
      requestSuperhero(superhero != null);
    },
        onError: (error, stack) {
      print("error");
    });
  }

  void addToFavorite() {
    final superhero = superheroSubject.valueOrNull;
    if (superhero == null) {
      print("ERROR");
      return;
    }

    addToFavoriteSubscription?.cancel();
    addToFavoriteSubscription = FavoriteSuperheroStorage.getInstance()
        .addToFavorite(superhero)
        .asStream()
        .listen((event) {
      print("$event");
    }, onError: (error, stack) {
      print("error");
    });
  }

  void removeFromFavorites() {
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
    requestSubscription?.cancel();
    getFromFavoritesSubscription?.cancel();
    addToFavoriteSubscription?.cancel();
    removeFromFavoriteSubscription?.cancel();
    client?.close();

    superheroSubject.close();
    superheroPageStateSubject.close();
  }

  void retry() {
    superheroPageStateSubject.add(SuperheroPageState.loading);
    requestSuperhero(false);
  }
}

enum SuperheroPageState {
  loading, loaded, error
}

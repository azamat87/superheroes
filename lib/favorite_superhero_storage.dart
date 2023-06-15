import 'dart:convert';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'model/superhero.dart';

class FavoriteSuperheroStorage {
  static const _key = "favorite_superheroes";

  final update = PublishSubject();

  static FavoriteSuperheroStorage? _instance;

  factory FavoriteSuperheroStorage.getInstance()=> _instance ?? FavoriteSuperheroStorage._internal();

  FavoriteSuperheroStorage._internal();

  Future<bool> addToFavorite(final Superhero superhero) async {
    final rawSuperheros = await _getRawSuperheros();
    rawSuperheros.add(json.encode(superhero.toJson()));
    return _setRawSuperheros(rawSuperheros);
  }

  Future<bool> removeFromFavorites(final String id) async {
    final superheros = await _getSuperheroes();
    superheros.removeWhere((element) => element.id == id);

    return _setSuperheroes(superheros);
  }

  Future<List<Superhero>> _getSuperheroes() async {
    final rawSuperheros = await _getRawSuperheros();
    return rawSuperheros
        .map((rawSuperhero) => Superhero.fromJson(json.decode(rawSuperhero)))
        .toList();
  }

  Future<bool> _setSuperheroes(final List<Superhero> superheros) async {
    final updatedRawSuperheros = superheros.map((e) => json.encode(e.toJson())).toList();
    return _setRawSuperheros(updatedRawSuperheros);
  }

  Future<List<String>> _getRawSuperheros() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getStringList(_key) ?? [];
  }

  Future<bool> _setRawSuperheros(final List<String> rawSuperheros) async {
    final sp = await SharedPreferences.getInstance();
    final result = await sp.setStringList(_key, rawSuperheros);
    update.add(null);
    return result;
  }

  Future<Superhero?> getSuperhero(final String id) async {
    final superheroes = await _getSuperheroes();
    for (final superhero in superheroes) {
      if (superhero.id == id) {
        return superhero;
      }
    }
    return null;
  }

  Stream<List<Superhero>> observeFavoriteSuperheroes() async* {
    yield await _getSuperheroes();
    await for(final _ in update) {
      yield await _getSuperheroes();
    }
  }

  Stream<bool> observeIsFavorites(final String id) {
    return observeFavoriteSuperheroes()
        .map((superhero) => superhero.any((element) => element.id == id));
  }

  Future<bool> updateIfInFavorite(final Superhero newSuperhero) async{
    final superheroes = await _getSuperheroes();
    final index = superheroes.indexWhere((element) => element.id == newSuperhero.id);
    if (index == -1) {
      return false;
    }

    superheroes[index] = newSuperhero;
    return _setSuperheroes(superheroes);
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import '../services/DatabaseServices.dart';
import '../models/tmdb.dart';
import 'film_card.dart';
import '../models/movie.dart';

class MatchDetailsPage extends StatelessWidget {
  final String sessionId;
  final String movieId;

  const MatchDetailsPage({Key? key, required this.sessionId, required this.movieId}) : super(key: key);

  Future<void> _endSession(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_id');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session ended due to match.')),
    );
  }

  Future<void> _addMatch(BuildContext context) async {
    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

    final prefs = await SharedPreferences.getInstance();
    int? currentUserId = prefs.getInt('userID');

    if (currentUserId != null) {
      String timestamp = DateTime.now().toIso8601String();

      await DatabaseServices.saveMatch(movieId, currentUserId, timestamp);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID not found.')),
      );
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen(navigatorKey: navigatorKey)),
    );
  }

  Future<void> _displayMatch(BuildContext context) async {
    final movie = await MovieFunctions.fetchMovieById(movieId);
    String title = movie?.movieTitle ?? '';
    String plot = movie?.moviePlot ?? '';
    String posterUrl = movie?.posterPath ?? '';
    FilmCard(title: title, plot: plot, posterUrl: posterUrl); 
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _endSession(context);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Details'),
      ),
      body: FutureBuilder<Movie?>(
        future: MovieFunctions.fetchMovieById(movieId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final movie = snapshot.data;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (movie != null)
                  FilmCard(
                    title: movie.movieTitle,
                    plot: movie.moviePlot,
                    posterUrl: movie.posterPath ?? '',
                  )
                else
                  const Text("Failed to load movie info."),
                const SizedBox(height: 20),
                Text('Session ID: $sessionId', style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 10),
                Text('Movie ID: $movieId', style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _addMatch(context),
                  child: const Text("Save Match & Go Home"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

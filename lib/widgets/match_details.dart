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

  // Fetch otherUserID from session or preferences or pass as a parameter.
  Future<void> _addMatch(BuildContext context) async {
    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

    final prefs = await SharedPreferences.getInstance();
    int? currentUserId = prefs.getInt('userID');
    int? otherUserID = prefs.getInt('otherUserID');  

    if (currentUserId != null && otherUserID != null) {
      String timestamp = DateTime.now().toIso8601String();

      // Convert otherUserID to String if needed
      await DatabaseServices.saveMatch(movieId, currentUserId.toString(), timestamp);
      await DatabaseServices.saveMatch(movieId, otherUserID.toString(), timestamp);  // Convert to String here

      await prefs.remove('session_id');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session ended due to match.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID or Other User ID not found.')),
      );
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen(navigatorKey: navigatorKey)),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    posterUrl: 'https://image.tmdb.org/t/p/w500${movie.posterPath}',
                  )
                else
                  const Text("Failed to load movie info."),
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


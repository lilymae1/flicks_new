import 'package:flicks_new/Theme/colours.dart';
import 'package:flutter/material.dart';
import 'package:tcard/tcard.dart';
import '../models/tmdb.dart';
import '../models/movie.dart';
import 'film_card.dart';
import '../services/DatabaseServices.dart';
import '../services/FirebaseServices.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Theme/themeData.dart';

class NewSwipe extends StatefulWidget {
  final String sessionId;
  const NewSwipe({super.key, required this.sessionId});

  @override
  State<NewSwipe> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<NewSwipe> {
  final TCardController _controller = TCardController();

  Map<int, String> genres = {};
  Map<String, dynamic>? selectedFriend;
  List<Movie> _selectedMovies = [];
  int? currentUserId;
  bool _showForm = true;
  Map<int, String> _friendMap = {};
  int? _selectedFriendId;

  List<Movie> likedMovies = [];
  List<Movie> dislikedMovies = [];

  late String _sessionId = '';
  int _savedSwipeIndex = 0;

  @override
  void initState() {
    super.initState();
    loadSession();
    loadGenres();
    loadFriends();
  }

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionId = widget.sessionId;

    if (sessionId.isNotEmpty) {
      final savedIndex = prefs.getInt('swipe_index_$sessionId') ?? 0;

      setState(() {
        _sessionId = sessionId;
        _savedSwipeIndex = savedIndex;
      });

      try {
        final sessionDoc = await FirebaseFirestore.instance
            .collection('sessions')
            .doc(sessionId)
            .get();

        if (!sessionDoc.exists) throw Exception('Session document not found');

        final data = sessionDoc.data();
        final movieIds = List<String>.from(data?['movies'] ?? []);
        if (movieIds.isEmpty) throw Exception('No movies in session');

        final movies = await MovieFunctions.fetchMoviesByIds(movieIds);
        final remainingMovies = _savedSwipeIndex < movies.length
            ? movies.sublist(_savedSwipeIndex).cast<Movie>()
            : <Movie>[];

        setState(() {
          _selectedMovies = remainingMovies;
          _showForm = false;
        });

        print("Loaded ${remainingMovies.length} movies from session, starting at index $_savedSwipeIndex");
      } catch (e) {
        print("Invalid session or failed to load: $e");
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('session_id');
        setState(() {
          _showForm = true;
          _sessionId = '';
          _selectedMovies = [];
        });
      }
    }
  }

  Future<void> resetSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_id');
    await prefs.remove('swipe_index_$_sessionId');

    setState(() {
      _sessionId = '';
      _savedSwipeIndex = 0;
      _selectedMovies = [];
      _showForm = true;
    });

    print("Session has been reset.");
  }

  Future<void> loadGenres() async {
    try {
      genres = await MovieFunctions.fetchGenres();
      setState(() {});
    } catch (error) {
      print("Error loading genres: $error");
    }
  }

  Future<void> loadFriends() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userID');

    if (userId != null) {
      currentUserId = userId;
      final friends = await DatabaseServices.getFriends(userId);
      setState(() {
        _friendMap = {
          for (var friend in friends)
            friend['userID'] as int: friend['userName'] as String
        };
      });
    }
  }

  Future<void> startSwipe() async {
    final userA = currentUserId.toString();
    final userB = _selectedFriendId.toString();
    final movieIds = _selectedMovies.map((m) => m.movieID.toString()).toList();

    final sessionId = await createSession(userA, userB, movieIds);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_id', sessionId);
    await prefs.setInt('swipe_index_$sessionId', 0);

    setState(() {
      _sessionId = sessionId;
      _savedSwipeIndex = 0;
      _showForm = false;
    });

    print("Session created and stored: $_sessionId");
  }

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("New swipe", style: FlicksTheme.pageHeader()),
        actions: [
          if (!_showForm)
            IconButton(
              icon: Icon(Icons.refresh),
              tooltip: 'Reset session',
              onPressed: resetSession,
            ),
        ],
      ),
      body: SafeArea(
        child: _showForm
            ? Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
                    child: DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: "Who would you like to swipe with?",
                        prefixIcon: Icon(Icons.group),
                      ),
                      items: _friendMap.entries
                          .map((entry) => DropdownMenuItem<int>(
                                value: entry.key,
                                child: Text(entry.value,
                                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                              ))
                          .toList(),
                      onChanged: (friendID) {
  setState(() {
    _selectedFriendId = friendID; // Updating the selected friend's ID
  });
  print("Selected Friend ID: $_selectedFriendId"); // Debugging print
},

                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: genres.isEmpty
                        ? CircularProgressIndicator()
                        : DropdownButtonFormField<int>(
                            decoration: InputDecoration(
                              labelText: "Pick a genre",
                              prefixIcon: Icon(Icons.theater_comedy),
                            ),
                            items: genres.entries
                                .map((entry) => DropdownMenuItem<int>(
                                      value: entry.key,
                                      child: Text(entry.value,
                                          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                                    ))
                                .toList(),
                            onChanged: (genreId) async {
                              if (genreId != null) {
                                final movies = await MovieFunctions.fetchMoviesByGenre(genreId);
                                setState(() {
                                  _selectedMovies = movies;
                                });
                              }
                            },
                          ),
                  ),
                  ElevatedButton(
                    onPressed: startSwipe,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.swipe, color: FlicksColours.Yellow, size: 20),
                        SizedBox(width: 8),
                        Text('Start swipe'),
                      ],
                    ),
                  ),
                ],
              )
            : _selectedMovies.isEmpty
                ? Center(child: Text("No movies loaded"))
                : TCard(
                    controller: _controller,
                    cards: _selectedMovies.map((movie) {
                      return FilmCard(
                        title: movie.movieTitle,
                        plot: movie.moviePlot,
                        posterUrl: movie.posterUrl,
                      );
                    }).toList(),
                    size: Size(
                      MediaQuery.of(context).size.width * 0.9,
                      MediaQuery.of(context).size.height * 0.6,
                    ),
                    onForward: (index, info) async {
                      final swipedMovie = _selectedMovies[_currentIndex];

                      print("Swiping movie: ${swipedMovie.movieTitle}, index: $_currentIndex");

                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setInt('swipe_index_$_sessionId', _currentIndex + 1);

                      // Ensure `otherUserID` is selected before calling `movieMatch`
                      if (_selectedFriendId == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("Please select a friend before swiping."))
  );
  return;
}


                      if (info.direction == SwipDirection.Right) {
                        storeSwipe(
                          sessionID: _sessionId,
                          userID: currentUserId.toString(),
                          movieID: swipedMovie.movieID.toString(),
                          liked: true,
                        );

                        // Pass selected friend ID as `otherUserID`
                        movieMatch(
                          sessionID: _sessionId,
                          currentUserID: currentUserId.toString(),
                          otherUserID: _selectedFriendId.toString(),  // Use _selectedFriendId here
                          movieID: swipedMovie.movieID.toString(),
                          liked: true,
                        );

                        likedMovies.add(swipedMovie);
                        print("Liked movie: ${swipedMovie.movieTitle}");
                      } else if (info.direction == SwipDirection.Left) {
                        storeSwipe(
                          sessionID: _sessionId,
                          userID: currentUserId.toString(),
                          movieID: swipedMovie.movieID.toString(),
                          liked: false,
                        );
                        dislikedMovies.add(swipedMovie);
                        print("Disliked movie: ${swipedMovie.movieTitle}");
                      }

                      setState(() {
                        _currentIndex++;
                      });

                      if (_currentIndex >= _selectedMovies.length) {
                        print("All cards swiped!");
                        print("Liked movies: ${likedMovies.map((m) => m.movieTitle)}");
                        print("Disliked movies: ${dislikedMovies.map((m) => m.movieTitle)}");
                      }
                    },
                    onEnd: () {
                      print("All cards swiped!");
                      print("Liked movies: ${likedMovies.map((m) => m.movieTitle)}");
                      print("Disliked movies: ${dislikedMovies.map((m) => m.movieTitle)}");
                    },
                  ),
      ),
    );
  }
}


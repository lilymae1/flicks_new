import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flicks_new/widgets/login_screen.dart';
import 'package:flicks_new/services/NotificationServices.dart';
import 'package:flicks_new/Theme/colours.dart';
import 'package:flicks_new/Theme/themeData.dart';

import '../services/DatabaseServices.dart';
import '../models/movie.dart';
import '../models/tmdb.dart';

import 'add_friends.dart';
import 'new_swipe.dart';
import 'update_account.dart';
import 'h_film_card.dart';

class HomeScreen extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final int initialTabIndex;
  final String? deepLinkSessionId;

  const HomeScreen({
    super.key,
    required this.navigatorKey,
    this.initialTabIndex = 0,
    this.deepLinkSessionId,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late Timer _refreshTimer;
  List<Map<String, dynamic>> _friends = [];
  int? _userID;
  late String _sessionId = '';
  String? _profilePicturePath;

  late TabController _tabController;

  final List<Tab> _tabs = const [
    Tab(icon: Icon(Icons.home)),
    Tab(icon: Icon(Icons.person)),
    Tab(icon: Icon(Icons.movie)),
    Tab(icon: Icon(Icons.settings)),
    Tab(icon: Icon(Icons.logout)),
  ];

  List<Movie> _matchedMovies = [];

  Future<void> _loadMatches() async {
    final allMatches = await DatabaseServices.displayMatches();
    final prefs = await SharedPreferences.getInstance();
    final userID = prefs.getInt('userID');

    final matches = allMatches.where((m) => m['userID'] == userID).toList();

    List<Movie> movies = [];
    for (var match in matches) {
      final movieId = match['movieID'];
      if (movieId != null) {
        final movie = await MovieFunctions.fetchMovieById(movieId.toString());
        if (movie != null) {
          movies.add(movie);
        }
      }
    }

    setState(() {
      _matchedMovies = movies;
    });
  }

  Future<void> _loadProfilePicture() async {
    if (_userID != null) {
      final path = await DatabaseServices.getProfilePicturePath(_userID!);
      setState(() {
        _profilePicturePath = path;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _loadFriends();
    _loadMatches();

    _tabController = TabController(length: _tabs.length, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialTabIndex >= 0 && widget.initialTabIndex < _tabs.length) {
        _tabController.index = widget.initialTabIndex;
      }
    });

    if (widget.deepLinkSessionId != null && widget.deepLinkSessionId!.isNotEmpty) {
      _sessionId = widget.deepLinkSessionId!;
    } else {
      _loadSessionId();
    }

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _loadFriends(),
    );

    _tabController.addListener(() {
      if (_tabController.index == 0) {
        _loadFriends();
      }
    });
  }

  Future<void> _loadFriends() async {
    final prefs = await SharedPreferences.getInstance();
    int? userID = prefs.getInt('userID');
    if (userID != null) {
      List<Map<String, dynamic>> friends = await DatabaseServices.getFriends(userID);
      final path = await DatabaseServices.getProfilePicturePath(userID);

      setState(() {
        _userID = userID;
        _friends = friends;
        _profilePicturePath = path;
      });

      await NotificationServices.checkPendingNotifications(userID.toString());
    }
  }

  Future<void> _loadSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    String sessionId = prefs.getString('session_id') ?? '';
    setState(() {
      _sessionId = sessionId;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Flicks',
          style: TextStyle(fontFamily: 'RubikMonoOne', color: FlicksColours.Black),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            color: FlicksColours.Grey,
            child: TabBar(
              controller: _tabController,
              tabs: _tabs,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: FlicksColours.Yellow,
              unselectedLabelColor: Colors.black,
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Home Page',
                  style: FlicksTheme.pageHeader(),
                ),
                const SizedBox(height: 20),
                Center(
                  child: ClipOval(
                    child: _profilePicturePath != null && File(_profilePicturePath!).existsSync()
                        ? Image.file(
                            File(_profilePicturePath!),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          )
                        : Image.asset(
                            'assets/default_profile.png',
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Your Friends',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: _friends.isEmpty
                      ? const Text(
                          "You haven't added any friends yet.",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _friends.length,
                          itemBuilder: (context, index) {
                            final friend = _friends[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.9,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: FlicksColours.Grey,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(2, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.person, size: 32),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        friend['userName'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () async {
                                        await DatabaseServices.deleteFriend(_userID!, friend['userID']);
                                        await DatabaseServices.deleteFriend(friend['userID'], _userID!);
                                        _loadFriends();
                                      },
                                      icon: const Icon(Icons.delete, color: FlicksColours.Red),
                                      label: const Text(
                                        'Delete',
                                        style: TextStyle(color: FlicksColours.Red),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const Divider(),
                const SizedBox(height: 20),
                const Text('Matched Movies', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                if (_matchedMovies.isEmpty)
                  const Text("You haven't matched any movies yet.", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ..._matchedMovies.map((movie) {
                  return FilmCard_H(
                    title: movie.movieTitle,
                    plot: movie.moviePlot,
                    posterUrl: movie.posterPath,
                  );
                }).toList(),
              ],
            ),
          ),
          AddFriends(onFriendAdded: _loadFriends),
          NewSwipe(sessionId: _sessionId),
          UpdateDetailsPage(),
          LogoutTab(logoutCallback: _logout),
        ],
      ),
    );
  }
}

class LogoutTab extends StatefulWidget {
  final Future<void> Function() logoutCallback;

  const LogoutTab({super.key, required this.logoutCallback});

  @override
  State<LogoutTab> createState() => _LogoutTabState();
}

class _LogoutTabState extends State<LogoutTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.logoutCallback();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Logging out..."));
  }
}


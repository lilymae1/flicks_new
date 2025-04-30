class Movie {
  final int movieID;
  final String movieTitle;
  final String moviePlot;
  final String posterPath;

  Movie({
    required this.movieID,
    required this.movieTitle,
    required this.moviePlot,
    required this.posterPath,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      movieID: json['id'],
      movieTitle: json['title'] ?? 'No Title',
      moviePlot: json['overview'] ?? '',
      posterPath: json['poster_path'] ?? '',
    );
  }

  String get posterUrl => 'https://image.tmdb.org/t/p/w500$posterPath';
}
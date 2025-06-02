import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../main_screen/home/components/tournament_card.dart';

class LiveTournamentsScreen extends StatefulWidget {
  const LiveTournamentsScreen({Key? key}) : super(key: key);

  @override
  State<LiveTournamentsScreen> createState() => _LiveTournamentsScreenState();
}

class _LiveTournamentsScreenState extends State<LiveTournamentsScreen> {
  bool isLoading = true;
  List<LiveMatch> liveMatches = [];

  @override
  void initState() {
    super.initState();
    _loadLiveMatches();
  }

  void _loadLiveMatches() {
    // TODO: Replace with actual API call to fetch live matches
    // For now, using sample data
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        liveMatches = [
          LiveMatch(
            id: '1',
            title: 'Nairobi Premier League',
            players: 32,
            prize: 'KSh 50,000',
            venue: 'City Hall',
            youtubeUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          ),
          LiveMatch(
            id: '2',
            title: 'Kenya Championship',
            players: 24,
            prize: 'KSh 30,000',
            venue: 'Sports Complex',
            youtubeUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          ),
          LiveMatch(
            id: '3',
            title: 'Mombasa Open',
            players: 16,
            prize: 'KSh 25,000',
            venue: 'Ocean View Club',
            youtubeUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          ),
        ];
        isLoading = false;
      });
    });
  }

  Future<void> _launchYoutube(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        _showErrorDialog('Cannot open YouTube link');
      }
    } catch (e) {
      _showErrorDialog('Error opening YouTube link: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Live Tournaments',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {
                isLoading = true;
              });
              _loadLiveMatches();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : liveMatches.isEmpty
              ? _buildEmptyState()
              : _buildLiveMatchesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.live_tv_outlined,
            size: 64,
            color: Colors.white54,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Live Matches',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'There are no live matches at the moment.\nCheck back later!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                isLoading = true;
              });
              _loadLiveMatches();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16543A),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Refresh',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveMatchesList() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${liveMatches.length} Live Match${liveMatches.length == 1 ? '' : 'es'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: liveMatches.length,
              itemBuilder: (context, index) {
                final match = liveMatches[index];
                return TournamentCard(
                  title: match.title,
                  players: match.players,
                  prize: match.prize,
                  venue: match.venue,
                  isLive: true,
                  youtubeUrl: match.youtubeUrl,
                  onTap: () => _launchYoutube(match.youtubeUrl),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class LiveMatch {
  final String id;
  final String title;
  final int players;
  final String prize;
  final String venue;
  final String youtubeUrl;

  LiveMatch({
    required this.id,
    required this.title,
    required this.players,
    required this.prize,
    required this.venue,
    required this.youtubeUrl,
  });
}

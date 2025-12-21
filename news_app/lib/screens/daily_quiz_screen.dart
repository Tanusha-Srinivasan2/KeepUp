import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // Import this
import '../providers/news_provider.dart';
import '../models/news_story.dart';

class DailyQuizScreen extends StatelessWidget {
  final CardSwiperController controller = CardSwiperController();
  final ValueNotifier<bool> _allowSwipeNotifier = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NewsProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text(
          "Daily Quiz",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: provider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE94560)),
            )
          : CardSwiper(
              controller: controller,
              cardsCount: provider.stories.length,
              numberOfCardsDisplayed: 3,
              onSwipe: (previousIndex, currentIndex, direction) {
                if (_allowSwipeNotifier.value) {
                  _allowSwipeNotifier.value = false;
                  return true;
                }
                return false;
              },
              cardBuilder: (context, index, x, y) {
                final story = provider.stories[index];
                bool isLast = index == provider.stories.length - 1;

                return NewsQuizCard(
                  key: ValueKey(story.headline),
                  story: story,
                  isLastCard: isLast,
                  onNext: () {
                    if (isLast)
                      Navigator.pop(context);
                    else {
                      _allowSwipeNotifier.value = true;
                      controller.swipe(CardSwiperDirection.right);
                    }
                  },
                );
              },
            ),
    );
  }
}

class NewsQuizCard extends StatefulWidget {
  final NewsStory story;
  final VoidCallback onNext;
  final bool isLastCard;

  const NewsQuizCard({
    required Key key,
    required this.story,
    required this.onNext,
    required this.isLastCard,
  }) : super(key: key);

  @override
  State<NewsQuizCard> createState() => _NewsQuizCardState();
}

class _NewsQuizCardState extends State<NewsQuizCard> {
  bool showSummary = false;
  int? selectedIndex;
  bool? wasCorrect;

  void _handleAnswer(int index) async {
    setState(() {
      selectedIndex = index;
      wasCorrect = index == widget.story.quizQuestion!.correctAnswerIndex;
    });
    await Future.delayed(Duration(milliseconds: 1000));
    if (mounted) setState(() => showSummary = true);
  }

  // Helper to open Google Search for the headline
  Future<void> _launchSource() async {
    final query = Uri.encodeComponent(widget.story.headline);
    final url = Uri.parse("https://www.google.com/search?q=$query");
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.story.quizQuestion == null)
      return Center(child: Text("Loading..."));

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Color(0xFFE94560).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              widget.story.sourceName,
              style: TextStyle(
                color: Color(0xFFE94560),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Spacer(),
          if (!showSummary) ...[
            Text(
              widget.story.quizQuestion!.questionText,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ...List.generate(widget.story.quizQuestion!.options.length, (
              index,
            ) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedIndex == null
                        ? Colors.white
                        : (index ==
                                  widget.story.quizQuestion!.correctAnswerIndex
                              ? Colors.green[100]
                              : (index == selectedIndex
                                    ? Colors.red[100]
                                    : Colors.white)),
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                  onPressed: selectedIndex == null
                      ? () => _handleAnswer(index)
                      : null,
                  child: Text(widget.story.quizQuestion!.options[index]),
                ),
              );
            }),
          ] else ...[
            Icon(
              wasCorrect! ? Icons.check_circle : Icons.cancel,
              color: wasCorrect! ? Colors.green : Colors.red,
              size: 60,
            ),
            SizedBox(height: 10),
            Text(
              wasCorrect! ? "Correct!" : "Oops!",
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(widget.story.summary, textAlign: TextAlign.center),
            SizedBox(height: 10),
            TextButton.icon(
              icon: Icon(Icons.link),
              label: Text("Read Full Source"),
              onPressed: _launchSource,
            ),
            SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1A1A2E),
                foregroundColor: Colors.white,
              ),
              onPressed: widget.onNext,
              child: Text(widget.isLastCard ? "Finish Quiz" : "Next Question"),
            ),
          ],
          Spacer(),
        ],
      ),
    );
  }
}

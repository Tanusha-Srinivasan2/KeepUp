import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/news_provider.dart';
import '../models/news_story.dart';

class CategoryListScreen extends StatelessWidget {
  final String categoryName;
  const CategoryListScreen({required this.categoryName});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NewsProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text(
          "$categoryName News",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: provider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CC9F0)),
            )
          : ListView.builder(
              padding: EdgeInsets.all(20),
              itemCount: provider.stories.length,
              itemBuilder: (context, index) {
                final story = provider.stories[index];
                return _buildNewsCard(context, story);
              },
            ),
    );
  }

  Widget _buildNewsCard(BuildContext context, NewsStory story) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  story.sourceName,
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            story.headline,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 15),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1A1A2E),
                foregroundColor: Colors.white,
              ),
              onPressed: () => _showDetailDialog(context, story),
              child: Text("Learn More"),
            ),
          ),
        ],
      ),
    );
  }

  // THE POPUP DIALOG
  void _showDetailDialog(BuildContext context, NewsStory story) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          story.headline,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(story.summary, style: TextStyle(fontSize: 16, height: 1.5)),
            SizedBox(height: 20),
            OutlinedButton.icon(
              icon: Icon(Icons.public),
              label: Text("Visit Source"),
              onPressed: () async {
                final query = Uri.encodeComponent(story.headline);
                final url = Uri.parse("https://www.google.com/search?q=$query");
                if (await canLaunchUrl(url)) await launchUrl(url);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

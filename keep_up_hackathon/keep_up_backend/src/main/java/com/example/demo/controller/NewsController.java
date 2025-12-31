package com.example.demo.controller;

import com.example.demo.model.Toon;
import com.example.demo.service.NewsIndexingService;
import com.example.demo.service.QuizService;
import com.example.demo.service.UserService;
import com.example.demo.service.VertexAiService;
import com.example.demo.service.CatchUpService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.concurrent.ExecutionException;
import java.util.List;

@RestController
@RequestMapping("/api/news")
public class NewsController {

    private final VertexAiService vertexAiService;
    private final NewsIndexingService newsIndexingService;
    private final QuizService quizService;

    @Autowired
    private UserService userService;

    @Autowired
    private CatchUpService catchUpService;

    public NewsController(VertexAiService vertexAiService,
                          NewsIndexingService newsIndexingService,
                          QuizService quizService) {
        this.vertexAiService = vertexAiService;
        this.newsIndexingService = newsIndexingService;
        this.quizService = quizService;
    }

    // GENERATE NEWS (Call this to refresh the database with new cards)
    @GetMapping("/generate")
    public String generateNews(@RequestParam String region) {
        System.out.println("🔎 Starting Research...");
        String rawFacts = vertexAiService.researchNews(region);

        System.out.println("🎨 Formatting News...");
        String toonJson = vertexAiService.formatToToonJson(rawFacts);
        newsIndexingService.processAndSave(toonJson);

        System.out.println("🎓 Creating Daily Quiz...");
        String quizJson = vertexAiService.generateQuizFromNews(rawFacts);
        quizService.saveDailyQuiz(quizJson);

        return "Generation Complete! \nNews: " + toonJson + "\n\nQuiz: " + quizJson;
    }

    // CHAT WITH NEWS
    @GetMapping("/chat")
    public String chatWithNews(@RequestParam String question) {
        System.out.println("🗣️ Chat Request: " + question);
        List<Toon> allNews = newsIndexingService.getAllNewsSegments();

        if (allNews.isEmpty()) {
            // Fallback: If DB is empty, just ask the AI directly (it will use Google Search if configured)
            return vertexAiService.chatWithNews(question, "No local news context available.");
        }

        StringBuilder contextBuilder = new StringBuilder();
        for (Toon segment : allNews) {
            // Ensure we are passing the rich description to the AI
            contextBuilder.append("Title: ").append(segment.getTitle())
                    .append(". Description: ").append(segment.getDescription())
                    .append("\n");
        }

        return vertexAiService.chatWithNews(question, contextBuilder.toString());
    }

    // GET NEWS FEED
    @GetMapping("/feed")
    public List<Toon> getNewsFeed() {
        return newsIndexingService.getAllNewsSegments();
    }

    // GET QUIZ
    @GetMapping("/quiz")
    public String getQuiz() throws ExecutionException, InterruptedException {
        return quizService.getDailyQuiz();
    }

    // LEADERBOARD ENDPOINTS
    @GetMapping("/leaderboard")
    public List<Map<String, Object>> getLeaderboard() throws ExecutionException, InterruptedException {
        return userService.getGlobalLeaderboard();
    }

    @GetMapping("/leaderboard/init")
    public String initLeaderboard() {
        return userService.initDummyData();
    }

    // USER MANAGEMENT
    @PostMapping("/user/create")
    public String createUser(@RequestParam String userId, @RequestParam String name) {
        return userService.createUser(userId, name);
    }

    @PostMapping("/user/xp")
    public String addXp(@RequestParam String userId, @RequestParam int points) throws Exception {
        return userService.addXp(userId, points);
    }

    @GetMapping("/user/{userId}")
    public Map<String, Object> getUserProfile(@PathVariable String userId) throws Exception {
        return userService.getUserProfile(userId);
    }

    // --- FIX IS HERE ---
    // CATCH UP ENDPOINT (Updated to use Database Context)
    @GetMapping("/catchup")
    public String getCatchUp() throws Exception {
        System.out.println("⚡ Generating Catch Up from Database...");

        // 1. Fetch all news from YOUR database
        List<Toon> allNews = newsIndexingService.getAllNewsSegments();

        // 2. Build the "Database News" String
        StringBuilder contextBuilder = new StringBuilder();

        if (allNews.isEmpty()) {
            System.out.println("⚠️ Database is empty. Sending blank context.");
        } else {
            for (Toon t : allNews) {
                // Combine Title and Description for the AI to read
                String line = String.format("Topic: %s | Title: %s | Description: %s",
                        t.getTopic(), t.getTitle(), t.getDescription());
                contextBuilder.append(line).append("\n");
            }
        }

        String databaseContext = contextBuilder.toString();
        // System.out.println("Context being sent to AI: " + databaseContext); // Uncomment to debug

        // 3. Send this string to the AI Service
        return vertexAiService.generateCatchUpContent(databaseContext);
    }
}
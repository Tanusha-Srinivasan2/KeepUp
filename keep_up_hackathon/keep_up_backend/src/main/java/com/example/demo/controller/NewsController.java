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

    // GENERATE NEWS
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

        // CLEAR OLD CACHE when new news is generated
        // (Optional: You might want to delete old catchups here)

        return "Generation Complete! \nNews: " + toonJson + "\n\nQuiz: " + quizJson;
    }

    // CHAT WITH NEWS
    @GetMapping("/chat")
    public String chatWithNews(@RequestParam String question) {
        List<Toon> allNews = newsIndexingService.getAllNewsSegments();
        if (allNews.isEmpty()) {
            return vertexAiService.chatWithNews(question, "No local news context available.");
        }
        StringBuilder contextBuilder = new StringBuilder();
        for (Toon segment : allNews) {
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

    // LEADERBOARD
    @GetMapping("/leaderboard")
    public List<Map<String, Object>> getLeaderboard() throws ExecutionException, InterruptedException {
        return userService.getGlobalLeaderboard();
    }

    @GetMapping("/leaderboard/init")
    public String initLeaderboard() {
        return userService.initDummyData();
    }

    // USER
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

    // --- CATCH UP (WITH CACHING) ---
    @GetMapping("/catchup")
    public String getCatchUp() throws Exception {
        // 1. CHECK CACHE: Do we already have a summary for today?
        // (Assuming your CatchUpService has this method. If not, add it!)
        String cachedSummary = catchUpService.getTodaySummary();
        if (cachedSummary != null && !cachedSummary.isEmpty()) {
            System.out.println("🚀 Serving CatchUp from Cache (Database)");
            return cachedSummary;
        }

        System.out.println("⚡ Cache Miss. Generating Fresh Catch Up...");

        // 2. FETCH CONTEXT: Get data from DB
        List<Toon> allNews = newsIndexingService.getAllNewsSegments();
        StringBuilder contextBuilder = new StringBuilder();

        if (allNews.isEmpty()) {
            System.out.println("⚠️ Database is empty. Context will be blank.");
        } else {
            for (Toon t : allNews) {
                String line = String.format("Topic: %s | Title: %s | Description: %s",
                        t.getTopic(), t.getTitle(), t.getDescription());
                contextBuilder.append(line).append("\n");
            }
        }

        // 3. GENERATE: Call AI
        String generatedJson = vertexAiService.generateCatchUpContent(contextBuilder.toString());

        // 4. SAVE TO CACHE: Store it so we don't regenerate next time
        if (generatedJson != null && generatedJson.length() > 10) {
            catchUpService.saveDailyCatchUp(generatedJson);
            System.out.println("💾 CatchUp Saved to Database!");
        }

        return generatedJson;
    }
    // ... inside NewsController class ...

    @PostMapping("/user/{userId}/bookmark")
    public String addBookmark(@PathVariable String userId, @RequestBody Toon newsItem) {
        return userService.addBookmark(userId, newsItem);
    }

    @DeleteMapping("/user/{userId}/bookmark/{newsId}")
    public String removeBookmark(@PathVariable String userId, @PathVariable String newsId) {
        return userService.removeBookmark(userId, newsId);
    }

    @GetMapping("/user/{userId}/bookmarks")
    public List<Toon> getBookmarks(@PathVariable String userId) throws Exception {
        return userService.getBookmarks(userId);
    }
}
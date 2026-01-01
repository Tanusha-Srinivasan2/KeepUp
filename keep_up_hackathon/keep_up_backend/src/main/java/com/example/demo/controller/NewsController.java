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
        String rawFacts = vertexAiService.researchNews(region);
        String toonJson = vertexAiService.formatToToonJson(rawFacts);
        newsIndexingService.processAndSave(toonJson);

        String quizJson = vertexAiService.generateQuizFromNews(rawFacts);
        quizService.saveDailyQuiz(quizJson);

        return "Generation Complete!";
    }

    // ✅ FEED ENDPOINT (Fixed: No direct Firestore calls)
    @GetMapping("/feed")
    public List<Toon> getNewsFeed(@RequestParam(required = false) String date) {
        // Pass the date to the service. If date is null, service handles it.
        return newsIndexingService.getAllNewsSegments(date);
    }

    // ... (Keep Chat, Quiz, User endpoints the same) ...

    @GetMapping("/chat")
    public String chatWithNews(@RequestParam String question) {
        List<Toon> allNews = newsIndexingService.getAllNewsSegments(null); // Fetch all for context
        if (allNews.isEmpty()) return "No news context available.";

        StringBuilder contextBuilder = new StringBuilder();
        for (Toon segment : allNews) {
            contextBuilder.append(segment.toToonString()).append("\n");
        }
        return vertexAiService.chatWithNews(question, contextBuilder.toString());
    }

    // ... Bookmarks ...
    @PostMapping("/user/{userId}/bookmark")
    public String addBookmark(@PathVariable String userId, @RequestBody Toon newsItem) {
        return userService.addBookmark(userId, newsItem);
    }

    @DeleteMapping("/user/{userId}/bookmark/{newsId}")
    public String removeBookmark(@PathVariable String userId, @PathVariable String newsId) {
        return userService.removeBookmark(userId, newsId);
    }

    @GetMapping("/user/{userId}/bookmarks")
    public List<Toon> getUserBookmarks(@PathVariable String userId) throws Exception {
        return userService.getBookmarks(userId);
    }

    // ... Quiz & Leaderboard ...
    @GetMapping("/quiz")
    public String getQuiz() throws ExecutionException, InterruptedException {
        return quizService.getDailyQuiz();
    }

    @GetMapping("/leaderboard")
    public List<Map<String, Object>> getLeaderboard() throws ExecutionException, InterruptedException {
        return userService.getGlobalLeaderboard();
    }

    @GetMapping("/catchup")
    public String getCatchUp() throws Exception {
        return catchUpService.getDailyCatchUp("US"); // Default region
    }

    // ... User ...
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
}
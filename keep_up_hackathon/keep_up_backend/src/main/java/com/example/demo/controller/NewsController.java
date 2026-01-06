package com.example.demo.controller;

import com.example.demo.model.Toon;
import com.example.demo.service.NewsIndexingService;
import com.example.demo.service.QuizService;
import com.example.demo.service.UserService;
import com.example.demo.service.VertexAiService;
import com.example.demo.service.CatchUpService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.Map;
import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.stream.Collectors;

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

    // --- NEWS GENERATION ---
    @GetMapping("/generate")
    public String generateNews(@RequestParam String region, @RequestParam(required = false) String date) {
        String targetDate = (date != null && !date.isEmpty()) ? date : LocalDate.now().toString();

        System.out.println("1. Researching News for " + targetDate + "...");
        String rawFacts = vertexAiService.researchNews(region, targetDate);

        System.out.println("2. Formatting Cards...");
        String toonJson = vertexAiService.formatToToonJson(rawFacts);
        newsIndexingService.processAndSave(toonJson, targetDate);

        System.out.println("3. Generating Main Daily Challenge...");
        String mainQuizJson = vertexAiService.generateQuizFromNews(rawFacts);
        quizService.saveDailyQuiz(mainQuizJson);

        System.out.println("4. Generating Category Quizzes...");
        String categoryQuizJson = vertexAiService.generateCategoryWiseQuiz(rawFacts);
        quizService.saveCategoryQuizzes(categoryQuizJson, targetDate);

        return "Generation Complete for " + targetDate;
    }

    // --- QUIZ ENDPOINTS ---

    // 1. Get Main Daily Challenge (Home Screen)
    @GetMapping("/quiz")
    public ResponseEntity<?> getQuiz(@RequestParam(required = false) String userId) throws ExecutionException, InterruptedException {
        String quizJson = quizService.getDailyQuiz();
        return ResponseEntity.ok(quizJson);
    }

    // 2. Get Specific Category Quiz (Explore Screen)
    @GetMapping("/quiz/category")
    public ResponseEntity<?> getCategoryQuiz(@RequestParam String category) throws ExecutionException, InterruptedException {
        String today = LocalDate.now().toString();
        List<Map<String, Object>> questions = quizService.getQuizByCategory(today, category);

        if (questions.isEmpty()) {
            return ResponseEntity.status(404).body("No quiz available for " + category);
        }
        return ResponseEntity.ok(questions);
    }

    // --- ✅ USER & XP (UPDATED) ---
    // This is the critical fix. It now accepts 'category' so the backend knows which quiz you finished.
    @PostMapping("/user/xp")
    public String addXp(
            @RequestParam String userId,
            @RequestParam int points,
            @RequestParam String category // <--- Added parameter
    ) throws Exception {
        return userService.addXp(userId, points, category);
    }

    // --- FEED & CHAT ---
    @GetMapping("/feed")
    public List<Toon> getNewsFeed(@RequestParam(required = false) String date) {
        return newsIndexingService.getAllNewsSegments(date);
    }

    @GetMapping("/chat")
    public String chatWithNews(@RequestParam String question) {
        String keywords = vertexAiService.extractSearchKeywords(question);
        List<Toon> matches = newsIndexingService.searchNewsByKeywords(keywords);
        List<String> matchStrings = matches.stream()
                .map(t -> t.getTitle() + ": " + t.getDescription())
                .collect(Collectors.toList());
        return vertexAiService.chatWithSmartRouting(question, matchStrings);
    }

    // --- USER MANAGEMENT ---
    @PostMapping("/user/create")
    public String createUser(@RequestParam String userId, @RequestParam String name) {
        return userService.createUser(userId, name);
    }

    @GetMapping("/user/{userId}")
    public Map<String, Object> getUserProfile(@PathVariable String userId) throws Exception {
        return userService.getUserProfile(userId);
    }

    @PostMapping("/user/updateName")
    public String updateUserName(@RequestParam String userId, @RequestParam String newName) throws ExecutionException, InterruptedException {
        return userService.updateUserName(userId, newName);
    }

    @GetMapping("/catchup")
    public List<Map<String, Object>> getCatchUp() throws Exception {
        return catchUpService.getWeeklyCatchUp("US");
    }

    @GetMapping("/leaderboard")
    public List<Map<String, Object>> getLeaderboard() throws ExecutionException, InterruptedException {
        return userService.getGlobalLeaderboard();
    }

    // --- BOOKMARKS ---
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
}
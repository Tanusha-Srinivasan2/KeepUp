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

    // --- USER ENDPOINTS ---
    @PostMapping("/user/create")
    public String createUser(@RequestParam String userId, @RequestParam String name) {
        return userService.createUser(userId, name);
    }

    @PostMapping("/user/updateName")
    public String updateName(@RequestParam String userId, @RequestParam String newName) throws ExecutionException, InterruptedException {
        return userService.updateUserName(userId, newName);
    }

    @GetMapping("/user/{userId}")
    public Map<String, Object> getUserProfile(@PathVariable String userId) throws Exception {
        return userService.getUserProfile(userId);
    }

    // --- NEWS GENERATION & FEED ---
    @GetMapping("/generate")
    public String generateNews(@RequestParam String region, @RequestParam(required = false) String date) {
        String targetDate = (date != null && !date.isEmpty()) ? date : LocalDate.now().toString();
        String rawFacts = vertexAiService.researchNews(region, targetDate);
        String toonJson = vertexAiService.formatToToonJson(rawFacts);
        newsIndexingService.processAndSave(toonJson, targetDate);
        String quizJson = vertexAiService.generateQuizFromNews(rawFacts);
        quizService.saveDailyQuiz(quizJson);
        return "Generation Complete for " + targetDate;
    }

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

    // --- QUIZ & XP (CRITICAL UPDATES) ---

    // ✅ FIXED: userId is now OPTIONAL (required = false)
    // This stops the "MissingServletRequestParameterException" crash.
    @GetMapping("/quiz")
    public ResponseEntity<?> getQuiz(@RequestParam(required = false) String userId) throws ExecutionException, InterruptedException {
        // We deliver the quiz to everyone so the app doesn't break.
        // The "Limit" is enforced in the /user/xp endpoint instead.
        String quizJson = quizService.getDailyQuiz();
        return ResponseEntity.ok(quizJson);
    }

    @PostMapping("/user/xp")
    public String addXp(@RequestParam String userId, @RequestParam int points) throws Exception {
        // The Service will now check if they played today before adding points.
        return userService.addXp(userId, points);
    }

    // --- LEADERBOARD & BOOKMARKS ---
    @GetMapping("/leaderboard")
    public List<Map<String, Object>> getLeaderboard() throws ExecutionException, InterruptedException {
        return userService.getGlobalLeaderboard();
    }

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

    @GetMapping("/catchup")
    public List<Map<String, Object>> getCatchUp() throws Exception {
        return catchUpService.getWeeklyCatchUp("US");
    }
}
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

    // ✅ 1. USER CREATION ENDPOINT (Matches Flutter's call)
    @PostMapping("/user/create")
    public String createUser(@RequestParam String userId, @RequestParam String name) {
        System.out.println("🆕 Creating User: " + name + " (" + userId + ")");
        return userService.createUser(userId, name);
    }

    // ✅ 2. UPDATE NAME ENDPOINT (Matches Pencil Icon)
    @PostMapping("/user/updateName")
    public String updateName(@RequestParam String userId, @RequestParam String newName) throws ExecutionException, InterruptedException {
        System.out.println("✏️ Updating Name for " + userId + " to " + newName);
        return userService.updateUserName(userId, newName);
    }

    // ✅ 3. GET PROFILE ENDPOINT
    @GetMapping("/user/{userId}")
    public Map<String, Object> getUserProfile(@PathVariable String userId) throws Exception {
        return userService.getUserProfile(userId);
    }

    // ... (KEEP ALL YOUR EXISTING NEWS, FEED, CHAT, QUIZ ENDPOINTS BELOW) ...

    // ✅ UPDATED: Pass 'date' to researchNews to force strict date matching
    @GetMapping("/generate")
    public String generateNews(@RequestParam String region, @RequestParam(required = false) String date) {
        // Use provided date, or default to today
        String targetDate = (date != null && !date.isEmpty()) ? date : java.time.LocalDate.now().toString();

        System.out.println("🔎 Starting Strict Research for " + targetDate + "...");

        // 1. Pass the DATE to the AI (This is the key fix!)
        String rawFacts = vertexAiService.researchNews(region, targetDate);

        System.out.println("🎨 Formatting News...");
        String toonJson = vertexAiService.formatToToonJson(rawFacts);

        // 2. Save with the SAME date so it goes into the correct "Day Box"
        newsIndexingService.processAndSave(toonJson, targetDate);

        System.out.println("🎓 Creating Daily Quiz...");
        String quizJson = vertexAiService.generateQuizFromNews(rawFacts);
        quizService.saveDailyQuiz(quizJson);

        return "Generation Complete for " + targetDate;
    }

    @GetMapping("/feed")
    public List<Toon> getNewsFeed(@RequestParam(required = false) String date) {
        return newsIndexingService.getAllNewsSegments(date);
    }

    @GetMapping("/catchup")
    public List<Map<String, Object>> getCatchUp() throws Exception {
        return catchUpService.getWeeklyCatchUp("US");
    }

    @GetMapping("/chat")
    public String chatWithNews(@RequestParam String question) {
        // 1. Get Keywords (Cheap)
        String keywords = vertexAiService.extractSearchKeywords(question);
        System.out.println("🔍 Search Keywords: " + keywords);

        // 2. Search Database (Free)
        List<Toon> matches = newsIndexingService.searchNewsByKeywords(keywords);

        // 3. Prepare Content
        List<String> matchStrings = matches.stream()
                .map(t -> t.getTitle() + ": " + t.getDescription())
                .collect(Collectors.toList());

        // 4. Generate Answer (Smart Cost Routing)
        return vertexAiService.chatWithSmartRouting(question, matchStrings);
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

    @GetMapping("/quiz")
    public String getQuiz() throws ExecutionException, InterruptedException {
        return quizService.getDailyQuiz();
    }

    @GetMapping("/leaderboard")
    public List<Map<String, Object>> getLeaderboard() throws ExecutionException, InterruptedException {
        return userService.getGlobalLeaderboard();
    }

    @PostMapping("/user/xp")
    public String addXp(@RequestParam String userId, @RequestParam int points) throws Exception {
        return userService.addXp(userId, points);
    }
}
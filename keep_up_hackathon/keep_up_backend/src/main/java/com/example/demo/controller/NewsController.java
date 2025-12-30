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
        newsIndexingService.processAndSave(toonJson); // Saves new Toons with titles/images

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
            return "I don't have any news data to answer that right now. Try generating news first!";
        }

        StringBuilder contextBuilder = new StringBuilder();
        for (Toon segment : allNews) {
            contextBuilder.append(segment.toToonString()).append("\n");
        }

        return vertexAiService.chatWithNews(question, contextBuilder.toString());
    }

    // GET NEWS FEED (Used by Flutter 'Discover' screen)
    @GetMapping("/feed")
    public List<Toon> getNewsFeed() {
        return newsIndexingService.getAllNewsSegments(); // Returns List<Toon>
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

    // CATCH UP ENDPOINT
    @GetMapping("/catchup")
    public String getCatchUp(@RequestParam(defaultValue = "US") String region) throws Exception {
        return catchUpService.getDailyCatchUp(region);
    }
}
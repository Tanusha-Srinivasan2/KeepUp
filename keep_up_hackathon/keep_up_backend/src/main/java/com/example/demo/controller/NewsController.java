package com.example.demo.controller;

import com.example.demo.model.ToonSegment;
import com.example.demo.service.NewsIndexingService;
import com.example.demo.service.QuizService; // Import the new service
import com.example.demo.service.VertexAiService;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/news")
public class NewsController {

    private final VertexAiService vertexAiService;
    private final NewsIndexingService newsIndexingService;
    private final QuizService quizService; // Add this

    public NewsController(VertexAiService vertexAiService,
                          NewsIndexingService newsIndexingService,
                          QuizService quizService) {
        this.vertexAiService = vertexAiService;
        this.newsIndexingService = newsIndexingService;
        this.quizService = quizService;
    }

    @GetMapping("/generate")
    public String generateNews(@RequestParam String region) {

        // 1. Research News
        System.out.println("🔎 Starting Research...");
        String rawFacts = vertexAiService.researchNews(region);

        // 2. Generate & Save News Cards
        System.out.println("🎨 Formatting News...");
        String toonJson = vertexAiService.formatToToonJson(rawFacts);
        newsIndexingService.processAndSave(toonJson);

        // 3. Generate & Save Daily Quiz (NEW!)
        System.out.println("🎓 Creating Daily Quiz...");
        String quizJson = vertexAiService.generateQuizFromNews(rawFacts);
        quizService.saveDailyQuiz(quizJson);

        return "Generation Complete! \nNews: " + toonJson + "\n\nQuiz: " + quizJson;
    }
    // URL: http://localhost:8080/api/news/chat?question=What happened to the stocks?
    @GetMapping("/chat")
    public String chatWithNews(@RequestParam String question) {
        System.out.println("🗣️ Chat Request: " + question);

        // 1. Fetch News
        List<ToonSegment> allNews = newsIndexingService.getAllNewsSegments();

        if (allNews.isEmpty()) {
            return "I don't have any news data to answer that right now. Try generating news first!";
        }

        // 2. Build Context
        StringBuilder contextBuilder = new StringBuilder();
        for (ToonSegment segment : allNews) {
            // Using your EXISTING helper method!
            contextBuilder.append(segment.toToonString()).append("\n");
        }

        // 3. Chat
        return vertexAiService.chatWithNews(question, contextBuilder.toString());
    }
    // URL: http://localhost:8080/api/news/feed
    @GetMapping("/feed")
    public List<ToonSegment> getNewsFeed() {
        // This reuses the method you already wrote!
        return newsIndexingService.getAllNewsSegments();
    }
}
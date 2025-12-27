package com.example.demo.controller;



import com.example.demo.service.NewsIndexingService;
import com.example.demo.service.VertexAiService;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/news")
public class NewsController {

    private final VertexAiService vertexAiService;
    private final NewsIndexingService newsIndexingService;

    public NewsController(VertexAiService vertexAiService, NewsIndexingService newsIndexingService) {
        this.vertexAiService = vertexAiService;
        this.newsIndexingService = newsIndexingService;
    }

    @GetMapping("/generate")
    public String generateNews(@RequestParam String region) {
        // Step 1: Research (The "Pro" Agent)
        String rawFacts = vertexAiService.researchNews(region);

        // Step 2: Format (The "Flash" Agent)
        String toonJson = vertexAiService.formatToToonJson(rawFacts);

        // Step 3: Index (Save to Database)
        newsIndexingService.processAndSave(toonJson);

        return "Generation Complete! Raw JSON: " + toonJson;
    }
}

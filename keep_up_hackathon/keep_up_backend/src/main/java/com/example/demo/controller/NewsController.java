package com.example.demo.controller;

import com.example.demo.model.*;
import com.example.demo.repository.*;
import com.example.demo.service.CatchUpService;
import com.example.demo.service.UserService;
import com.example.demo.service.VertexAiService;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/news")
@CrossOrigin(origins = "*")
public class NewsController {

    private final VertexAiService vertexAiService;
    private final ToonRepository toonRepository;
    private final LatestQuizRepository latestQuizRepository;
    private final CategoryQuizRepository categoryQuizRepository;
    private final CatchUpService catchUpService; // ✅ Correct Injection
    private final ObjectMapper objectMapper = new ObjectMapper();

    public NewsController(VertexAiService vertexAiService,
                          ToonRepository toonRepository,
                          LatestQuizRepository latestQuizRepository,
                          CategoryQuizRepository categoryQuizRepository,
                          CatchUpService catchUpService) { // ✅ Add to Constructor
        this.vertexAiService = vertexAiService;
        this.toonRepository = toonRepository;
        this.latestQuizRepository = latestQuizRepository;
        this.categoryQuizRepository = categoryQuizRepository;
        this.catchUpService = catchUpService;
    }

    @GetMapping("/generate")
    public String generateDailyNews(@RequestParam(defaultValue = "US") String region) {
        try {
            String today = LocalDate.now().toString();

            // 1. Generate & Save News
            String rawFacts = vertexAiService.researchNews(region, today);
            String jsonOutput = vertexAiService.formatToToonJson(rawFacts);
            List<Toon> newToons = objectMapper.readValue(jsonOutput, new TypeReference<>() {});

            for (Toon t : newToons) {
                t.setId(UUID.randomUUID().toString());
                t.setPublishedDate(today);
                t.setTimestamp(System.currentTimeMillis());
            }
            toonRepository.saveAll(newToons).blockLast();

            String newsContext = newToons.stream()
                    .map(t -> t.getTitle() + ": " + t.getDescription())
                    .collect(Collectors.joining("\n"));

            // 2. Generate Daily Quiz
            String quizJson = vertexAiService.generateQuizFromNews(newsContext);
            latestQuizRepository.save(new LatestQuiz("latest_quiz", quizJson)).block();

            // 3. Generate Category Quizzes
            List<String> categories = Arrays.asList("Technology", "Science", "Sports", "Business", "Politics");
            for (String category : categories) {
                try {
                    String singleCatJson = vertexAiService.generateSingleCategoryQuiz(newsContext, category);
                    List<QuizQuestion> questions = objectMapper.readValue(singleCatJson, new TypeReference<>() {});
                    categoryQuizRepository.save(new CategoryQuiz(today + "_" + category, today, category, questions)).block();
                } catch (Exception e) {
                    System.err.println("⚠️ Quiz generation failed for " + category);
                }
            }

            // 4. ✅ Trigger Catch-Up Generation immediately
            catchUpService.getWeeklyCatchUp(region);

            return "Generation Complete for " + today;
        } catch (Exception e) {
            return "Error: " + e.getMessage();
        }
    }

    @GetMapping("/catchup")
    public List<Map<String, Object>> getCatchUp(@RequestParam(defaultValue = "US") String region) throws Exception {
        return catchUpService.getWeeklyCatchUp(region); // ✅ Instance call
    }

    @GetMapping("/feed")
    public List<Toon> getNewsFeed(@RequestParam(required = false) String date) {
        if (date == null) date = LocalDate.now().toString();
        List<Toon> news = toonRepository.findByPublishedDate(date).collectList().block();
        return (news != null && !news.isEmpty()) ? news : toonRepository.findAll().collectList().block();
    }
}
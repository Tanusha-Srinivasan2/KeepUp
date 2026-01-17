package com.example.demo.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.ai.vertexai.gemini.VertexAiGeminiChatOptions;
import org.springframework.stereotype.Service;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@Service
public class VertexAiService {

    private final ChatModel chatModel;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public VertexAiService(ChatModel chatModel) {
        this.chatModel = chatModel;
    }

    // --- PHASE 1: RESEARCH (Fixed Date Logic) ---
    public String researchNews(String region, String date) {
        // 1. Validate Date: If null, empty, or IN THE FUTURE, use Today.
        String targetDate;
        try {
            LocalDate parsedDate = (date != null && !date.isEmpty()) ? LocalDate.parse(date) : LocalDate.now();
            if (parsedDate.isAfter(LocalDate.now())) {
                System.out.println("⚠️ Future date detected (" + date + "). Reverting to TODAY.");
                targetDate = LocalDate.now().toString();
            } else {
                targetDate = parsedDate.toString();
            }
        } catch (Exception e) {
            targetDate = LocalDate.now().toString();
        }

        String prompt = """
        Role: Chief Editor of KeepUp News.
        Task: Curate the Top 5 most impactful news stories for: %s in %s.
        
        CRITICAL RULES:
        1. REAL NEWS ONLY: Do not output meta-text like "I cannot find news" or "As an AI". If no specific news is found for this date, find the LATEST available news.
        2. CATEGORIES: Select exactly 1 most recent story each for: Technology, Sports, Politics, Business, and Science.
        3. DATE MATCH: Prioritize events from %s, but if none exist, use the most recent major events from this week.
        
        OUTPUT FORMAT PER STORY:
        - Category: [Category Name]
        - Headline: [Catchy Title]
        - Facts: [Core details of the event]
        - Source: [Publisher URL]
        """.formatted(targetDate, region, targetDate);

        return chatModel.call(new Prompt(prompt,
                VertexAiGeminiChatOptions.builder()
                        .model("gemini-2.5-flash")
                        .googleSearchRetrieval(true) // ✅ Search Enabled
                        .build()
        )).getResult().getOutput().getText();
    }

    // --- PHASE 2: FORMATTER ---
    public String formatToToonJson(String rawFacts) {
        String prompt = """
            You are a backend API. Convert these news facts into a JSON list.
            
            RULES:
            1. Return strictly valid JSON.
            2. imageUrl should be empty "".
            3. Do NOT make up fake news. Use the input provided.
            
            SCHEMA:
            [
              {
                "topic": "Technology",
                "title": "Headline",
                "description": "Summary",
                "time": "Today",
                "imageUrl": "",
                "sourceUrl": "...", 
                "keywords": ["tag1", "tag2"]
              }
            ]
            INPUT FACTS:
            """ + rawFacts;

        String jsonResponse = cleanJson(chatModel.call(new Prompt(prompt,
                VertexAiGeminiChatOptions.builder().model("gemini-2.5-flash").temperature(0.2).build()
        )).getResult().getOutput().getText());

        return sanitizeToonJson(jsonResponse);
    }

    private String sanitizeToonJson(String jsonArray) {
        try {
            List<Map<String, Object>> cards = objectMapper.readValue(jsonArray, new TypeReference<>() {});
            for (Map<String, Object> card : cards) {
                String originalUrl = (String) card.get("sourceUrl");
                String title = (String) card.get("title");
                String verifiedNewsSearch = "https://www.google.com/search?tbm=nws&q=" +
                        URLEncoder.encode(title, StandardCharsets.UTF_8);

                if (originalUrl == null || !originalUrl.startsWith("http") || originalUrl.contains("google.com/url")) {
                    card.put("sourceUrl", verifiedNewsSearch);
                }
            }
            return objectMapper.writeValueAsString(cards);
        } catch (Exception e) {
            return jsonArray;
        }
    }

    // --- PHASE 3: MAIN DAILY QUIZ (Anti-Hallucination Fix) ---
    public String generateQuizFromNews(String rawFacts) {
        String prompt = """
            Create a Daily Quiz of 3 questions based on these news facts.
            
            🚨 STRICT RULES:
            1. Generate questions ONLY about the actual news events (e.g., "Who won the game?", "What company merged?").
            2. NEVER generate questions about the "Chief Editor", "AI limitations", "Curating process", or "Date validity".
            3. If the news text is about an error, generate generic General Knowledge questions instead.
            
            SCHEMA:
            [
              {
                "topic": "Technology",
                "question": "Question text?",
                "options": ["A", "B", "C", "D"],
                "correctIndex": 0,
                "explanation": "Why it is correct."
              }
            ]
            NEWS FACTS:
            """ + rawFacts;

        return cleanJson(chatModel.call(new Prompt(prompt,
                VertexAiGeminiChatOptions.builder().model("gemini-2.5-flash").temperature(0.3).build()
        )).getResult().getOutput().getText());
    }

    // --- PHASE 4: SINGLE CATEGORY QUIZ (Loop Support) ---
    public String generateSingleCategoryQuiz(String newsContext, String category) {
        String prompt = """
            Generate 3 multiple-choice quiz questions specifically about %s based on this news.
            
            🚨 STRICT RULES:
            1. Questions must be about REAL WORLD EVENTS mentioned in the context.
            2. Do NOT ask about "AI", "Chief Editor", or "Missing Data".
            3. If no specific news exists for %s, generate High-Quality General Knowledge questions about %s.
            
            SCHEMA:
            [
              {
                "topic": "Specific Topic",
                "question": "Question text?",
                "options": ["A", "B", "C", "D"],
                "correctIndex": 0,
                "explanation": "Why it is correct."
              }
            ]
            
            NEWS CONTEXT:
            %s
            """.formatted(category, category, category, newsContext);

        return cleanJson(chatModel.call(new Prompt(prompt,
                VertexAiGeminiChatOptions.builder().model("gemini-2.5-flash").temperature(0.4).build()
        )).getResult().getOutput().getText());
    }

    // --- CHAT & KEYWORDS ---
    public String extractSearchKeywords(String userQuestion) {
        return chatModel.call(new Prompt("Extract 1-3 search keywords from: " + userQuestion)).getResult().getOutput().getText().trim();
    }

    public String chatWithSmartRouting(String userQuestion, List<String> localMatches) {
        boolean hasLocalNews = !localMatches.isEmpty();
        String context = hasLocalNews ? "LOCAL NEWS DATABASE:\n" + String.join("\n", localMatches) : "No local news match.";
        String prompt = "You are Nexus, a News Analyst. Answer concisely using: " + context + "\nQuestion: " + userQuestion;

        return chatModel.call(new Prompt(prompt,
                VertexAiGeminiChatOptions.builder().model("gemini-2.5-flash").googleSearchRetrieval(!hasLocalNews).build()
        )).getResult().getOutput().getText();
    }

    public String generateCatchUpContent(String databaseNews) {
        String prompt = "Summarize these stories into a JSON 'Daily Recap' list. SCHEMA: [{topic, title, description, time}]. INPUT: " + databaseNews;
        return cleanJson(chatModel.call(new Prompt(prompt)).getResult().getOutput().getText());
    }

    private String cleanJson(String text) {
        return text.replace("```json", "").replace("```", "").trim();
    }
}
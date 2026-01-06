package com.example.demo.service;

import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.ai.vertexai.gemini.VertexAiGeminiChatOptions;
import org.springframework.stereotype.Service;
import java.time.LocalDate;
import java.util.List;

@Service
public class VertexAiService {

    private final ChatModel chatModel;

    public VertexAiService(ChatModel chatModel) {
        this.chatModel = chatModel;
    }

    // --- PHASE 1: RESEARCH ---
    public String researchNews(String region, String date) {
        String targetDate = (date != null && !date.isEmpty()) ? date : LocalDate.now().toString();

        String prompt = """
        Role: Chief Editor of KeepUp News.
        Task: Curate the Top 5 most impactful stories specifically for the date: %s in %s.
        
        QUALITY GATE RULES:
        1. STRICT DATE MATCH: Only include events that happened on %s.
        2. IMPACT: Must affect >1 million people.
        3. CATEGORIES: Select exactly 1 story for: Technology, Sports, Politics, Business, and Science.
        
        OUTPUT LIMITS:
        - Provide ONLY a brief summary of core facts for each story.
        - DO NOT pull full articles.
        """.formatted(targetDate, region, targetDate);

        return chatModel.call(new Prompt(prompt,
                VertexAiGeminiChatOptions.builder()
                        .model("gemini-2.5-flash")
                        .googleSearchRetrieval(true)
                        .build()
        )).getResult().getOutput().getText();
    }

    // --- PHASE 2: FORMATTER ---
    public String formatToToonJson(String rawFacts) {
        String prompt = """
            You are a backend API. Convert the news facts into a strict JSON list of 5 items.
            RULES:
            1. EXTRACT 5 COMPLETELY DIFFERENT STORIES (Tech, Sports, Politics, Business, Science).
            2. "imageUrl": Provide a valid Unsplash placeholder URL related to the topic.
            
            SCHEMA:
            [
              {
                "topic": "Technology",
                "title": "Headline text here",
                "description": "Short summary.",
                "time": "4h ago",
                "imageUrl": "https://images.unsplash.com/...",
                "sourceUrl": "https://google.com/search?q=...",
                "keywords": ["tag1", "tag2"]
              }
            ]
            INPUT FACTS:
            """ + rawFacts;

        return chatModel.call(new Prompt(prompt,
                VertexAiGeminiChatOptions.builder()
                        .model("gemini-2.5-flash")
                        .temperature(0.2)
                        .build()
        )).getResult().getOutput().getText().replace("```json", "").replace("```", "").trim();
    }

    // --- PHASE 3: MAIN DAILY QUIZ ---
    public String generateQuizFromNews(String rawFacts) {
        String prompt = """
            Create a Daily Quiz of 3 questions based on these news facts.
            Output strict JSON only.
            SCHEMA:
            [
              {
                "question": "The actual question?",
                "options": ["Wrong 1", "Correct Answer", "Wrong 2"],
                "correctIndex": 1,
                "explanation": "Short explanation (EL15)."
              }
            ]
            NEWS FACTS:
            """ + rawFacts;

        return chatModel.call(new Prompt(prompt,
                VertexAiGeminiChatOptions.builder()
                        .model("gemini-2.5-flash")
                        .temperature(0.4)
                        .build()
        )).getResult().getOutput().getText().replace("```json", "").replace("```", "").trim();
    }

    // --- PHASE 4: CATEGORY-WISE QUIZ (NEW) ---
    public String generateCategoryWiseQuiz(String dailyNewsContext) {
        String prompt = """
        You are a Quiz Master. Based on the provided news context, generate 3 multiple-choice questions for EACH distinct category found.
        
        RULES:
        1. Output STRICT JSON only. Do not use Markdown.
        2. The keys must be the Category Names (Title Case).
        3. Each category must have a list of 3 questions.
        
        SCHEMA:
        {
          "Technology": [
            { "question": "...", "options": ["A", "B", "C", "D"], "answer": "A", "explanation": "..." },
            { ... }
          ],
          "Sports": [ ... ],
          "Politics": [ ... ]
        }
        
        NEWS CONTEXT:
        """ + dailyNewsContext;

        return chatModel.call(new Prompt(prompt,
                VertexAiGeminiChatOptions.builder()
                        .model("gemini-2.5-flash")
                        .temperature(0.4)
                        .build()
        )).getResult().getOutput().getText().replace("```json", "").replace("```", "").trim();
    }

    // --- OPTIMIZATION: KEYWORDS ---
    public String extractSearchKeywords(String userQuestion) {
        return chatModel.call(new Prompt("Extract 1-3 search keywords from: " + userQuestion,
                VertexAiGeminiChatOptions.builder().model("gemini-2.5-flash").temperature(0.0).build()
        )).getResult().getOutput().getText().trim();
    }

    // --- SMART ROUTING ---
    public String chatWithSmartRouting(String userQuestion, List<String> localMatches) {
        boolean hasLocalNews = !localMatches.isEmpty();
        String context = hasLocalNews ? "LOCAL NEWS:\n" + String.join("\n", localMatches) : "No local match.";

        return chatModel.call(new Prompt("Context: " + context + "\nUser Question: " + userQuestion,
                VertexAiGeminiChatOptions.builder()
                        .model("gemini-2.5-flash")
                        .temperature(0.3)
                        .googleSearchRetrieval(!hasLocalNews)
                        .build()
        )).getResult().getOutput().getText();
    }

    // --- ✅ PHASE 5: CATCH UP (RESTORED THIS METHOD) ---
    public String generateCatchUpContent(String databaseNews) {
        String prompt = """
            You are a News Recap Assistant.
            Task: Summarize the provided news stories into a 'Daily Recap' format.
            
            RULES:
            1. Use ONLY the provided input text.
            2. Summarize the events in very simple, easy-to-understand language.
            3. Output strict JSON only.
            
            SCHEMA:
            [
              {
                "topic": "Technology",
                "title": "Headline text here",
                "description": "Short summary of the event.",
                "time": "4h ago",
                "imageUrl": "https://images.unsplash.com/..."
              }
            ]
            
            INPUT NEWS CONTEXT:
            """ + databaseNews;

        return chatModel.call(new Prompt(prompt,
                VertexAiGeminiChatOptions.builder()
                        .model("gemini-2.5-flash")
                        .temperature(0.5)
                        .build()
        )).getResult().getOutput().getText().replace("```json", "").replace("```", "").trim();
    }
}
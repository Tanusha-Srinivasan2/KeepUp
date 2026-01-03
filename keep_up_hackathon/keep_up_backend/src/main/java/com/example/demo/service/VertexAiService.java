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

    // ✅ PHASE 1: UPDATED (Accepts 'date' to prevent overlaps)
    public String researchNews(String region, String date) {
        // If no date provided, use today.
        String targetDate = (date != null && !date.isEmpty()) ? date : LocalDate.now().toString();

        String prompt = """
        Role: Chief Editor of KeepUp News.
        Task: Curate the Top 5 most impactful stories specifically for the date: %s in %s.
        
        QUALITY GATE RULES:
        1. STRICT DATE MATCH: Only include events that happened on %s. Do NOT include news from today if the date is in the past.
        2. IMPACT: Must affect >1 million people or major markets.
        3. CREDIBILITY: Must be verified by major sources (e.g., Reuters, AP, Bloomberg).
        4. CATEGORIES: Select exactly 1 story for: Technology, Sports, Politics, Business, and Science.
        
        OUTPUT LIMITS:
        - Provide ONLY a brief summary of core facts for each story.
        - DO NOT pull full articles or long transcripts.
        - List the facts as bullet points for each category.
        """.formatted(targetDate, region, targetDate);

        return chatModel.call(new Prompt(prompt,
                VertexAiGeminiChatOptions.builder()
                        .model("gemini-2.5-flash") // Updated to latest model if available, or keep 1.5-flash
                        .googleSearchRetrieval(true)
                        .build()
        )).getResult().getOutput().getText();
    }

    // PHASE 2: The Formatter (Unchanged)
    public String formatToToonJson(String rawFacts) {
        String prompt = """
            You are a backend API. Convert the following news facts into a strict JSON list of 5 items.
            
            RULES:
            1. EXTRACT 5 COMPLETELY DIFFERENT STORIES. Do not repeat the same story.
            2. Each item must be a different topic (Tech, Sports, Politics, Business, Science).
            3. "title": Punchy headline, max 10 words.
            4. "description": Engaging summary, max 20 words.
            5. "time": Use relative time (e.g., "2h ago", "Just now").
            6. "imageUrl": Provide a valid placeholder URL related to the topic.
               - Technology: "https://images.unsplash.com/photo-1518770660439-4636190af475"
               - Sports: "https://images.unsplash.com/photo-1461896836934-ffe607ba8211"
               - Science: "https://images.unsplash.com/photo-1507413245164-6160d8298b31"
               - Business: "https://images.unsplash.com/photo-1460925895917-afdab827c52f"
               - Politics: "https://images.unsplash.com/photo-1529101091760-6149d4c81f22"
            7. "sourceUrl": Provide a direct link to a credible source (Reuters, BBC, TechCrunch) relevant to this specific story. If unknown, generate a Google Search URL for the title.
            
            SCHEMA:
            [
              {
                "topic": "Technology",
                "title": "Headline text here",
                "description": "Short summary of the event.",
                "time": "4h ago",
                "imageUrl": "https://images.unsplash.com/...",
                "sourceUrl": "https://www.reuters.com/...",
                "keywords": ["tag1", "tag2"]
              }
            ]
            
            INPUT FACTS:
            """ + rawFacts;

        return chatModel.call(new Prompt(prompt,
                VertexAiGeminiChatOptions.builder()
                        .model("gemini-2.5-flash") // Changed back to stable 1.5 if 2.5 errors
                        .temperature(0.2)
                        .build()
        )).getResult().getOutput().getText().replace("```json", "").replace("```", "").trim();
    }

    // PHASE 3: Daily Quiz (Unchanged)
    public String generateQuizFromNews(String rawFacts) {
        String prompt = """
            Create a Daily Quiz of 3 questions based on these news facts.
            Output strict JSON only.
            
            RULES:
            1. "explanation": MUST be very short (Max 15 words). Simple language.
            2. "topic": Must be one of [Technology, Sports, Politics, Business, Science].
            
            SCHEMA:
            [
              {
                "question": "The actual question?",
                "options": ["Wrong 1", "Correct Answer", "Wrong 2"],
                "correctIndex": 1,
                "explanation": "A short explanation of how it impacts a users life directly(explanation like im a 10 year old)"
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

    // ✅ OPTIMIZATION 1: Extract Keywords (Cheap & Fast)
    public String extractSearchKeywords(String userQuestion) {
        String prompt = """
            Extract 1-3 most important search keywords or proper nouns from this question. 
            Output ONLY the keywords separated by spaces. No text.
            Question: "%s"
            """.formatted(userQuestion);

        return chatModel.call(new Prompt(prompt,
                VertexAiGeminiChatOptions.builder()
                        .model("gemini-2.5-flash") // Cheapest model
                        .temperature(0.0) // Deterministic
                        .build()
        )).getResult().getOutput().getText().trim();
    }

    public String chatWithSmartRouting(String userQuestion, List<String> localMatches) {
        // 1. Check if we found anything in our local database
        boolean hasLocalNews = !localMatches.isEmpty();

        // 2. Prepare the context string
        String context = hasLocalNews
                ? "LOCAL NEWS TIMELINE (Correlate these records to answer):\n" + String.join("\n---\n", localMatches)
                : "No matches found in our local database. Please provide an answer using your internal knowledge and Google Search.";

        String systemPrompt = """
            You are 'KeepUp', a smart news analyst. 
            
            DIRECTIONS:
            1. CORRELATE: If multiple news records are provided in the context, connect them logically (e.g., 'Building on yesterday's report...').
            2. NEVER SAY "I don't know" or "I lack context". 
            3. FALLBACK: If the provided 'LOCAL NEWS TIMELINE' is empty or doesn't answer the user, use Google Search grounding to find real-time info.
            4. Keep answers under 4 lines and very punchy.

            CONTEXT:
            %s
            """.formatted(context);

        return chatModel.call(new Prompt(systemPrompt + "\nUser Question: " + userQuestion,
                VertexAiGeminiChatOptions.builder()
                        .model("gemini-2.5-flash") // Flash is cheapest for grounding
                        .temperature(0.3)
                        // ✅ CONDITIONAL TOGGLE: Search is only PAID FOR if local matches are empty
                        .googleSearchRetrieval(!hasLocalNews)
                        .build()
        )).getResult().getOutput().getText();
    }

    // PHASE 5: Catch Up / Recap Generation (Unchanged)
    public String generateCatchUpContent(String databaseNews) {
        String prompt = """
            You are a News Recap Assistant.
            Task: Summarize the provided news stories into a 'Daily Recap' format.
            
            RULES:
            1. Use ONLY the provided input text. Do not search the internet.
            2. Summarize the events in very simple, easy-to-understand language (EL15).
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
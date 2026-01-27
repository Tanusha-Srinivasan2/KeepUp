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
        
        🚫 SAFETY GUARDRAILS (MANDATORY):
        - Do NOT generate sexual content, graphic violence, hate speech, or promotion of self-harm.
        - Handle sensitive events (deaths, disasters, tragedies) with an Educational, objective, and fact-based (EDSA) tone. Never sensationalize or capitalize on tragedies.
        - Do NOT generate, describe, or reference deepfake images/recordings of real individuals for any deceptive purpose.
        - Always maintain journalistic integrity and respect for victims and affected communities.
        
        👶 CHILD SAFETY FILTERS (MANDATORY - App targets young audiences):
        - NEVER generate content related to plastic surgery, extreme weight loss methods, eating disorders, or cosmetic body adjustments.
        - NEVER provide instructions for dangerous activities including weapon manufacturing, explosive creation, drug synthesis, or any illegal activities.
        - NEVER generate any content that sexualizes minors or could be considered Child Sexual Abuse Material (CSAM).
        - Keep all content appropriate for ages 13+ with educational value.
        
        📰 SOURCE ATTRIBUTION (MANDATORY):
        - Every news story MUST include a "Source: [Publisher Name]" with the original article URL.
        - Use the actual source URL from Google Search grounding metadata when available.
        - If no direct URL is available, use the publisher's main website.
        
        ✍️ TRANSFORMATIVE CONTENT (MANDATORY):
        - Keep summaries brief: 3-4 bullet points of key facts only.
        - Do NOT copy the expressive narrative style of the original article.
        - Use your own factual, neutral language to describe events.
        - Focus on WHO, WHAT, WHEN, WHERE - not opinion or editorial tone.
        
        OUTPUT FORMAT PER STORY:
        - Category: [Category Name]
        - Headline: [Catchy but factual Title]
        - Facts: [3-4 bullet points summarizing key facts in neutral language]
        - Source: [Publisher Name]
        - SourceUrl: [Direct article URL or publisher website]
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
            
            🚫 SAFETY GUARDRAILS (MANDATORY):
            - Do NOT include sexual content, graphic violence, hate speech, or content promoting self-harm.
            - For sensitive events (deaths, disasters), use Educational and objective (EDSA) language. Never sensationalize tragedies.
            - Do NOT reference or describe deepfakes of real individuals.
            
            👶 CHILD SAFETY FILTERS (MANDATORY):
            - NEVER include content about plastic surgery, extreme weight loss, eating disorders, or cosmetic body modifications.
            - NEVER include instructions for weapons, explosives, drugs, or dangerous activities.
            - All content must be appropriate for ages 13+.
            
            📰 SOURCE ATTRIBUTION (MANDATORY):
            - The "sourceUrl" field MUST contain a valid, clickable URL to the original article.
            - The "sourceName" field MUST contain the publisher's name for display (e.g., "Reuters", "BBC", "TechCrunch").
            - If no direct URL exists, use a Google News search URL for the headline.
            
            ✍️ TRANSFORMATIVE CONTENT (MANDATORY):
            - "description" must be 3-4 bullet points of key facts, NOT a narrative paragraph.
            - Do NOT copy the expressive style or exact phrasing from the original article.
            - Use neutral, factual language. Focus on core facts only.
            
            SCHEMA:
            [
              {
                "topic": "Technology",
                "title": "Factual Headline",
                "description": "• Key fact 1\n• Key fact 2\n• Key fact 3",
                "time": "Today",
                "imageUrl": "",
                "sourceUrl": "https://example.com/article",
                "sourceName": "Publisher Name",
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
            
            // ✅ POLICY COMPLIANCE: Filter out cards without valid sourceUrl
            // Google Play requires all news items to have proper source attribution
            cards.removeIf(card -> {
                String url = (String) card.get("sourceUrl");
                return url == null || url.isEmpty() || !url.startsWith("http");
            });
            
            for (Map<String, Object> card : cards) {
                String originalUrl = (String) card.get("sourceUrl");
                String title = (String) card.get("title");
                String verifiedNewsSearch = "https://www.google.com/search?tbm=nws&q=" +
                        URLEncoder.encode(title, StandardCharsets.UTF_8);

                // 📰 Ensure valid sourceUrl
                if (originalUrl == null || !originalUrl.startsWith("http") || originalUrl.contains("google.com/url")) {
                    card.put("sourceUrl", verifiedNewsSearch);
                    originalUrl = verifiedNewsSearch;
                }

                // 📰 Ensure sourceName is always populated for attribution display
                String sourceName = (String) card.get("sourceName");
                if (sourceName == null || sourceName.isEmpty()) {
                    // Extract publisher name from URL
                    try {
                        java.net.URL url = new java.net.URL(originalUrl);
                        String host = url.getHost().replace("www.", "");
                        if (host.contains(".")) {
                            String[] parts = host.split("\\.");
                            sourceName = parts[0].substring(0, 1).toUpperCase() + parts[0].substring(1);
                        } else {
                            sourceName = "News Source";
                        }
                    } catch (Exception e) {
                        sourceName = "News Source";
                    }
                    card.put("sourceName", sourceName);
                }

                // 🏥 MEDICAL DISCLAIMER (MANDATORY for Google Play compliance)
                card.put("disclaimer", "This is for informational purposes only. Consult a healthcare professional for medical advice.");
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
            
            🚫 SAFETY GUARDRAILS (MANDATORY):
            - Do NOT create questions containing sexual content, graphic violence, hate speech, or self-harm references.
            - For questions about tragedies/sensitive events, use Educational and objective (EDSA) framing. Focus on factual learning, not sensationalism.
            - Do NOT reference deepfakes or manipulated media of real individuals.
            
            👶 CHILD SAFETY FILTERS (MANDATORY):
            - NEVER create questions about plastic surgery, extreme dieting, eating disorders, or body modification procedures.
            - NEVER create questions that provide or hint at instructions for weapons, explosives, or dangerous activities.
            - All quiz content must be educational and appropriate for ages 13+.
            
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
            
            🚫 SAFETY GUARDRAILS (MANDATORY):
            - Do NOT generate questions with sexual content, graphic violence, hate speech, or self-harm promotion.
            - Handle tragedy-related questions (deaths, disasters) with Educational and objective (EDSA) tone. Never exploit or sensationalize.
            - Do NOT include references to deepfakes or AI-generated media impersonating real people.
            
            👶 CHILD SAFETY FILTERS (MANDATORY):
            - NEVER generate questions about plastic surgery, extreme weight loss, or cosmetic procedures.
            - NEVER include content about weapon/explosive manufacturing or dangerous activities.
            - Ensure all content is age-appropriate for 13+ audiences.
            
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
        String prompt = """
            You are Nexus, a News Analyst. Answer concisely and helpfully.
            
            🚫 SAFETY GUARDRAILS (MANDATORY):
            - Do NOT generate sexual content, graphic violence, hate speech, or self-harm promotion.
            - Handle sensitive topics (deaths, disasters) with Educational and objective (EDSA) tone.
            - Do NOT create, describe, or reference deepfake content of real individuals.
            - Refuse requests that violate these guidelines politely.
            
            👶 CHILD SAFETY FILTERS (MANDATORY):
            - NEVER discuss plastic surgery, extreme weight loss methods, eating disorders, or cosmetic body modifications.
            - NEVER provide instructions for weapons, explosives, drugs, or any dangerous/illegal activities.
            - If asked about prohibited topics, politely decline and redirect to safe, educational content.
            - All responses must be appropriate for ages 13+.
            
            CONTEXT: %s
            QUESTION: %s
            """.formatted(context, userQuestion);

        return chatModel.call(new Prompt(prompt,
                VertexAiGeminiChatOptions.builder().model("gemini-2.5-flash").googleSearchRetrieval(!hasLocalNews).build()
        )).getResult().getOutput().getText();
    }

    public String generateCatchUpContent(String databaseNews) {
        String prompt = """
            Summarize these stories into a JSON 'Daily Recap' list.
            
            🚫 SAFETY GUARDRAILS (MANDATORY):
            - Do NOT include sexual content, graphic violence, hate speech, or self-harm references.
            - Summarize tragedies/sensitive events with Educational and objective (EDSA) language.
            - Do NOT reference deepfakes or manipulated media of real people.
            
            👶 CHILD SAFETY FILTERS (MANDATORY):
            - NEVER include content about plastic surgery, extreme dieting, or cosmetic procedures.
            - NEVER include references to weapon/explosive manufacturing or dangerous activities.
            - All content must be educational and appropriate for ages 13+.
            
            📰 SOURCE ATTRIBUTION (MANDATORY):
            - Include "sourceUrl" with the original article link when available.
            - Include "sourceName" with the publisher name for display.
            
            ✍️ TRANSFORMATIVE CONTENT (MANDATORY):
            - Keep "description" as 3-4 bullet points of key facts.
            - Do NOT copy the narrative style of original articles.
            - Use neutral, factual language only.
            
            SCHEMA: [{topic, title, description (bullet points), time, sourceUrl, sourceName}]
            INPUT: %s
            """.formatted(databaseNews);
        return cleanJson(chatModel.call(new Prompt(prompt)).getResult().getOutput().getText());
    }

    private String cleanJson(String text) {
        return text.replace("```json", "").replace("```", "").trim();
    }
}
package com.example.demo.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class VertexAiService {
    
    @Value("${gemini.api.key}")
    private String geminiApiKey;

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final RestTemplate restTemplate = new RestTemplate();

    public VertexAiService() {
    }

    private String geminiCall(String prompt, boolean useSearch, double temperature) {
        String url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=" + geminiApiKey;
        int maxRetries = 3;
        int currentRetry = 0;

        while (currentRetry < maxRetries) {
            try {
                Map<String, Object> textPart = Map.of("text", prompt);
                Map<String, Object> partContainer = Map.of("parts", List.of(textPart));
                Map<String, Object> requestBody = new HashMap<>();
                requestBody.put("contents", List.of(partContainer));
                requestBody.put("generationConfig", Map.of("temperature", temperature));

                if (useSearch) {
                    // Natively add free tier Google Search via AI Studio
                    requestBody.put("tools", List.of(Map.of("googleSearch", Map.of())));
                }

                HttpHeaders headers = new HttpHeaders();
                headers.setContentType(MediaType.APPLICATION_JSON);
                HttpEntity<String> entity = new HttpEntity<>(objectMapper.writeValueAsString(requestBody), headers);

                ResponseEntity<String> response = restTemplate.postForEntity(url, entity, String.class);
                JsonNode root = objectMapper.readTree(response.getBody());

                // Extract the generated text safely from JSON
                JsonNode textNode = root.at("/candidates/0/content/parts/0/text");
                return textNode.isMissingNode() ? "" : textNode.asText();
            } catch (org.springframework.web.client.HttpClientErrorException.TooManyRequests e) {
                currentRetry++;
                System.err.println("⚠️ Google API Rate Limit Hit (429). Retrying in " + (currentRetry * 5) + " seconds...");
                try {
                    Thread.sleep(currentRetry * 5000L); // Wait 5s, 10s, 15s instead of immediately crashing
                } catch (InterruptedException ie) {
                    Thread.currentThread().interrupt();
                }
            } catch (Exception e) {
                System.err.println("Gemini AI Studio Error: " + e.getMessage());
                return "{\"error\": \"AI request failed\"}";
            }
        }
        return "{\"error\": \"Rate limit exceeded after retries\"}";
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
        - Every news story MUST include "Source: [Publisher Name]" (e.g., "Reuters", "CNN", "Fox News", "BBC"). NEVER output "Google" as the source.
        - You MUST find the specific URL of the original article. Do NOT provide google.com tracking links or search links. Provide the true root article URL.
        - UNDER NO CIRCUMSTANCES should you use or output "vertexaisearch.cloud.google.com" URLs. They will break the system. Output the actual publisher's URL (e.g., "https://www.bbc.com/news/123").
        
        ✍️ TRANSFORMATIVE CONTENT (MANDATORY):
        - Keep summaries brief: 3-4 bullet points of key facts only.
        - First, read the original article and assess its political bias based on its loaded language, spin, or entity sentiment.
        - Second, write your OWN factual, neutral summary, stripped of any of the original article's spin or emotion.
        
        OUTPUT FORMAT PER STORY:
        - Category: [Category Name]
        - Headline: [Catchy but factual Title]
        - Facts: [3-4 bullet points summarizing key facts in neutral language]
        - Source: [Actual News Publisher Name, e.g., CNN, WSJ, BBC. NOT Google]
        - SourceUrl: [Exact Direct Article URL, NOT a Google Search Link]
        - BiasRating: [Left, Center, or Right] - Based on the ORIGINAL article's tone, NOT your summary. Evaluate loaded words, political leaning, and sentiment.
        - BiasExplanation: [1 short sentence explaining why the ORIGINAL article was given this bias rating]
        """.formatted(targetDate, region, targetDate);

        return geminiCall(prompt, true, 0.7);
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
            - The "sourceUrl" field MUST contain the exact direct, clickable URL to the original article. No Google tracking URLs.
            - UNDER NO CIRCUMSTANCES include "vertexaisearch.cloud.google.com" in the "sourceUrl" field. Provide the publisher URL (e.g. "https://nytimes.com/...").
            - The "sourceName" field MUST contain the actual publisher's name (e.g., "Reuters", "BBC", "TechCrunch"). NEVER use "Google News" or "Google".
            
            ✍️ TRANSFORMATIVE CONTENT & BIAS DETECTION:
            - "description" must be 3-4 bullet points of the provided key facts.
            - Map the "BiasRating" from the input strictly into "biasRating" (Left, Center, or Right).
            - Map the "BiasExplanation" from the input strictly into "biasExplanation".
            
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
                "biasRating": "Center",
                "biasExplanation": "Reports only verified facts without emotional language.",
                "keywords": ["tag1", "tag2"]
              }
            ]
            INPUT FACTS:
            """ + rawFacts;

        String jsonResponse = cleanJson(geminiCall(prompt, false, 0.2));

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

                // 📰 Ensure valid sourceUrl, avoid overriding strong URLs automatically unless they're dangerously broken
                if (originalUrl == null || !originalUrl.startsWith("http") || originalUrl.contains("vertexaisearch")) {
                    card.put("sourceUrl", verifiedNewsSearch);
                    originalUrl = verifiedNewsSearch;
                }
                // Do NOT block google.com/url. We will let the Python Bias Engine unwrap Google URLs natively.

                // ==== ADD BIAS ENGINE HTTP CALL ====
                try {
                    // Call http://127.0.0.1:5000/analyze
                    java.net.URL urlObj = new java.net.URL("http://127.0.0.1:5000/analyze");
                    java.net.HttpURLConnection conn = (java.net.HttpURLConnection) urlObj.openConnection();
                    conn.setRequestMethod("POST");
                    conn.setRequestProperty("Content-Type", "application/json; utf-8");
                    conn.setRequestProperty("Accept", "application/json");
                    conn.setDoOutput(true);
                    
                    String jsonInputString = "{\"url\": \"" + originalUrl + "\", \"headline\": \"" + title.replace("\"", "\\\"") + "\"}";
                    
                    try(java.io.OutputStream os = conn.getOutputStream()) {
                        byte[] input = jsonInputString.getBytes("utf-8");
                        os.write(input, 0, input.length);
                    }
                    
                    if(conn.getResponseCode() == 200) {
                        try(java.io.BufferedReader br = new java.io.BufferedReader(
                                new java.io.InputStreamReader(conn.getInputStream(), "utf-8"))) {
                            StringBuilder response = new StringBuilder();
                            String responseLine = null;
                            while ((responseLine = br.readLine()) != null) {
                                response.append(responseLine.trim());
                            }
                            
                            Map<String, Object> pythonResult = objectMapper.readValue(response.toString(), new TypeReference<>() {});
                            if (pythonResult.get("trueUrl") != null) card.put("sourceUrl", pythonResult.get("trueUrl"));
                            if (pythonResult.get("sourceName") != null) card.put("sourceName", pythonResult.get("sourceName"));
                            if (pythonResult.get("biasRating") != null) card.put("biasRating", pythonResult.get("biasRating"));
                            if (pythonResult.get("biasExplanation") != null) card.put("biasExplanation", pythonResult.get("biasExplanation"));
                        }
                    }
                } catch (Exception e) {
                    System.out.println("Bias Engine error: " + e.getMessage());
                }

                // 📰 Ensure sourceName is always populated for attribution display (Fallback)
                String sourceName = (String) card.get("sourceName");
                if (sourceName == null || sourceName.isEmpty()) {
                    // Extract publisher name from URL
                    try {
                        java.net.URL url = new java.net.URL((String) card.get("sourceUrl"));
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

        return cleanJson(geminiCall(prompt, false, 0.3));
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

        return cleanJson(geminiCall(prompt, false, 0.4));
    }

    // --- CHAT & KEYWORDS ---
    public String extractSearchKeywords(String userQuestion) {
        return geminiCall("Extract 1-3 search keywords from: " + userQuestion, false, 0.3).trim();
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

        return geminiCall(prompt, !hasLocalNews, 0.7);
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
            
            SCHEMA: [{topic, title, description (bullet points), time, sourceUrl, sourceName, biasRating, biasExplanation}]
            INPUT: %s
            """.formatted(databaseNews);
        return cleanJson(geminiCall(prompt, false, 0.5));
    }

    private String cleanJson(String text) {
        return text.replace("```json", "").replace("```", "").trim();
    }
}
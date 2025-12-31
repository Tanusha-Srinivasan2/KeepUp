package com.example.demo.service;

import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.ai.vertexai.gemini.VertexAiGeminiChatOptions;
import org.springframework.stereotype.Service;

@Service
public class VertexAiService {

    private final ChatModel chatModel;

    public VertexAiService(ChatModel chatModel) {
        this.chatModel = chatModel;
    }

    // PHASE 1: The Researcher (Now with Google Search Grounding)
    public String researchNews(String region) {
        String prompt = """
        Role: Chief Editor of KeepUp News.
        Task: Curate the Top 5 most impactful stories from the LAST 24 HOURS in %s.
        
        QUALITY GATE RULES:
        1. IMPACT: Must affect >1 million people or major markets.
        2. RECENCY: Must be published within the last 24 hours.
        3. CREDIBILITY: Must be verified by major sources (e.g., Reuters, AP, Bloomberg).
        4. CATEGORIES: Select exactly 1 story for: Tech, Sports, Politics, Business, and Science.
        
        OUTPUT LIMITS:
        - Provide ONLY a brief summary of core facts for each story.
        - DO NOT pull full articles or long transcripts.
        - List the facts as bullet points for each category.
        """.formatted(region);

        // FIX: Using "gemini-1.5-flash" & googleSearchRetrieval (No "with")
        return chatModel.call(new Prompt(prompt,
                VertexAiGeminiChatOptions.builder()
                        .model("gemini-2.5-flash")
                        .googleSearchRetrieval(true) // FIX: Removed "with"
                        .build()
        )).getResult().getOutput().getText();
    }

    // PHASE 2: The Formatter (Now requests fields for Flutter Cards)
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
               - Tech: "https://images.unsplash.com/photo-1518770660439-4636190af475"
               - Sports: "https://images.unsplash.com/photo-1461896836934-ffe607ba8211"
               - Science: "https://images.unsplash.com/photo-1507413245164-6160d8298b31"
               - Business: "https://images.unsplash.com/photo-1460925895917-afdab827c52f"
               - Politics: "https://images.unsplash.com/photo-1529101091760-6149d4c81f22"
            
            SCHEMA:
            [
              {
                "topic": "Tech",
                "title": "Headline text here",
                "description": "Short summary of the event.",
                "time": "4h ago",
                "imageUrl": "https://images.unsplash.com/...",
                "keywords": ["tag1", "tag2"]
              }
            ]
            
            INPUT FACTS:
            """ + rawFacts;

        return chatModel.call(new Prompt(prompt,
                VertexAiGeminiChatOptions.builder()
                        .model("gemini-2.5-flash")
                        .temperature(0.2) // Low temp for strict JSON
                        .build()
        )).getResult().getOutput().getText().replace("```json", "").replace("```", "").trim();
    }

    // PHASE 3: Daily Quiz
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

    // PHASE 4: Chat Assistant (HYBRID MODE: Context + Google Search)
    public String chatWithNews(String userQuestion, String newsContext) {
        String systemPrompt = """
            You are 'KeepUp', a smart AI assistant.
            
            INSTRUCTIONS:
            1. PRIORITY: Check the 'NEWS CONTEXT' below. If the answer is there, use it.
            2. FALLBACK: If the answer is NOT in the context, use your General Knowledge and Google Search to answer.
            3. DO NOT say "I don't know" or "It's not in the context". Always provide an answer.
            4. Keep answers under 3 lines.
            
            NEWS CONTEXT:
            """ + newsContext;

        return chatModel.call(new Prompt(systemPrompt + "\nUser: " + userQuestion,
                VertexAiGeminiChatOptions.builder()
                        .model("gemini-2.5-flash") // ✅ FIXED
                        .googleSearchRetrieval(true) // ✅ ADDED: Enables fallback search
                        .build()
        )).getResult().getOutput().getText();
    }

    // PHASE 5: Catch Up / Recap Generation
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
                "topic": "Tech",
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
                        .model("gemini-2.5-flash") // FIXED: 2.5 -> 1.5
                        .temperature(0.5)
                        // REMOVED: .googleSearchRetrieval(true) -> No longer needed
                        .build()
        )).getResult().getOutput().getText().replace("```json", "").replace("```", "").trim();
    }
}
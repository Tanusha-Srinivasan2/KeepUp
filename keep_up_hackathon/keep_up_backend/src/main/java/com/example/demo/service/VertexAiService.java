package com.example.demo.service;

// 1. VERIFY THESE IMPORTS CAREFULLY
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.chat.model.ChatResponse;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.ai.vertexai.gemini.VertexAiGeminiChatOptions;
import org.springframework.stereotype.Service;

@Service
public class VertexAiService {

    private final ChatModel chatModel;

    public VertexAiService(ChatModel chatModel) {
        this.chatModel = chatModel;
    }

    // PHASE 1: The Researcher (Gemini Pro)
    public String researchNews(String region) {
        String prompt = "Role: You are the Chief Editor of a high-stakes news app. Your goal is to curate only the top 5 most impactful, verified, and actionable news formatted in a way that can be easily understood by any age group\n" +
                "\n" +
                "Filtering Rules for the news story(The \"Quality Gate\"):\n" +
                "\n" +
                "Impact: The story must affect at least 1 million people or move a major financial market.\n" +
                "\n" +
                "Recency: Must be less than 24 hours old.\n" +
                "\n" +
                "Credibility: Must be verified by at least 2 distinct major sources (e.g., Reuters, AP, Bloomberg).\n" +
                "\n" +
                "No Fluff: Ignore celebrity gossip, minor sports updates, or rumors.Search for 10 potential top stories.\n" +
                "\n" +
                "Rank them internally based on the \"Filtering Rules\" above.\n" +
                "\n" +
                "Select ONLY the top 5 stories. so in this way Find 5 distinct, trending news headlines for today in " + region + ". Cover 1 news each for each of the topics (Tech, Sports, Politics, Business, Science). Just list the facts.";

        // FIX: Using "gemini-1.5-flash" (Correct Version)
        return chatModel.call(new Prompt(prompt,
                VertexAiGeminiChatOptions.builder()
                        .model("gemini-2.5-flash")
                        .build()
        )).getResult().getOutput().getText();


    }

    // PHASE 2: The Formatter (Gemini Flash -> JSON)
    public String formatToToonJson(String rawFacts) {
        String prompt = """
            You are a backend API. Convert the following news facts into a strict JSON list of 5 items.
            
            RULES:
            1. EXTRACT 5 COMPLETELY DIFFERENT STORIES. Do not repeat the same story.
            2. Each item must be a different topic (e.g., one Tech, one Sport, one World).
            3. "contentLine" must be punchy and under 12 words and easy to understand.
            4. Output ONLY the raw JSON string (no markdown, no ```json).
            
            SCHEMA:
            [
              {
                "topic": "CATEGORY",
                "contentLine": "Headline text here.",
                "keywords": ["tag1", "tag2"]
              }
            ]
            
            INPUT FACTS:
            """ + rawFacts;

        return chatModel.call(new Prompt(prompt,
                VertexAiGeminiChatOptions.builder()
                        .model("gemini-2.5-flash")
                        .temperature(0.5)
                        .build()
        )).getResult().getOutput().getText().replace("```json", "").replace("```", "").trim();}
    // --- PHASE 3: THE NEW ADDITION (Daily Quiz) ---
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
        )).getResult().getOutput().getText().replace("```json", "").replace("```", "").trim();}
    // --- PHASE 4: VOICE ASSISTANT BRAIN ---
    // 4. Chat Assistant (SMART HYBRID MODE)
    public String chatWithNews(String userQuestion, String newsContext) {
        String systemPrompt = """
            You are 'KeepUp', a smart AI assistant.
            
            INSTRUCTIONS:
            1. I will provide you with a list of 'News Context' below.
            2. IF the user's question is about current events or topics found in that context, use the context to answer in not more than 3 lines.
            3. IF the user asks a general question (e.g., "Hi", "What is Java?", "Tell me a joke"), IGNORE the context and answer directly using your general knowledge in not more than 3 lines.
            4. Do NOT say "I don't see that in the context" for general questions. Just answer them.
            
            NEWS CONTEXT:
            """ + newsContext;

        return chatModel.call(new Prompt(systemPrompt + "\nUser: " + userQuestion,
                VertexAiGeminiChatOptions.builder()
                        .model("gemini-2.5-flash")
                        .build()
        )).getResult().getOutput().getText();
    }
    // 5. Catch Up / Recap Generation
    public String generateCatchUpContent(String region) {
        // FIX: Use %s and .formatted() instead of concatenation
        String prompt = """
            You are a News Recap Assistant.
            Find 5 MAJOR events from the LAST 48 HOURS in %s.
            
            RULES:
            1. Summarize each event in very simple, easy-to-understand language (EL15 - Explain Like I'm 5).
            2. Output strict JSON only.
            
            SCHEMA:
            [
              {
                "headline": "Short Headline",
                "summary": "2-3 sentences maximum explaining exactly what happened and why it matters.",
                "timeAgo": "Yesterday"
              }
            ]
            """.formatted(region);

        return chatModel.call(new Prompt(prompt,
                VertexAiGeminiChatOptions.builder()
                        .model("gemini-2.5-flash")
                        .temperature(0.5)
                        .build()
        )).getResult().getOutput().getText().replace("```json", "").replace("```", "").trim();
    }
}
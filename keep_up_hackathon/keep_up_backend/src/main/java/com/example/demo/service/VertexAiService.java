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
        String systemPrompt = "You are a senior news editor. Find the top 3 most viral news stories in " + region + " today. " +
                "Verify facts using Google Search. Output a raw summary.";

        ChatResponse response = chatModel.call(new Prompt(systemPrompt,
                VertexAiGeminiChatOptions.builder()
                        .model("gemini-2.5-pro") // FIX: .withModel -> .model
                        .temperature(0.4)        // FIX: .withTemperature -> .temperature
                        .build()
        ));

        // FIX: Ensure you get the content from the output message
        return response.getResult().getOutput().getText();
    }

    // PHASE 2: The Formatter (Gemini Flash -> JSON)
    public String formatToToonJson(String rawFacts) {
        String instructions = """
            Convert the following news summary into a JSON list of 'ToonSegments'.
            Each segment must be a single fact/sentence.
            JSON Format:
            [
              {
                "id": "T-01",
                "topic": "Business",
                "contentLine": "Stock markets rallied today.",
                "keywords": ["Stocks", "Money"]
              }
            ]
            """;

        String finalPrompt = instructions + "\n\nNEWS DATA:\n" + rawFacts;

        ChatResponse response = chatModel.call(new Prompt(finalPrompt,
                VertexAiGeminiChatOptions.builder()
                        .model("gemini-2.5-flash") // FIX: .withModel -> .model
                        .temperature(0.1)        // FIX: .withTemperature -> .temperature
                        .build()
        ));

        return response.getResult().getOutput().getText();
    }
    // --- PHASE 3: THE NEW ADDITION (Daily Quiz) ---
    public String generateQuizFromNews(String rawNewsFacts) {
        String instructions = """
                Based on the news summary below, generate 3 multiple-choice quiz questions.
                Output ONLY raw JSON.
                
                JSON Format:
                [
                  {
                    "id": "Q-01",
                    "question": "Which company's stock rallied today?",
                    "options": ["Apple", "Tesla", "Nvidia", "Amazon"],
                    "correctAnswer": "Nvidia",
                    "xpReward": 50
                  }
                ]
                """;

        String finalPrompt = instructions + "\n\nNEWS SOURCE:\n" + rawNewsFacts;

        ChatResponse response = chatModel.call(new Prompt(finalPrompt,
                VertexAiGeminiChatOptions.builder()
                        .model("gemini-2.5-flash")
                        .temperature(0.2) // Low temp for factual accuracy
                        .build()
        ));

        return response.getResult().getOutput().getText();
    }
    // --- PHASE 4: VOICE ASSISTANT BRAIN ---
    public String chatWithNews(String userQuestion, String newsContext) {
        String systemPrompt = """
            You are 'KeepUp', a helpful AI news assistant. 
            Answer the user's question using ONLY the provided news context.
            Keep your answer short (under 2 sentences) and conversational.
            If the answer isn't in the context, say "I don't see that in today's news."
            """;

        String fullPrompt = systemPrompt + "\n\nCONTEXT:\n" + newsContext + "\n\nUSER QUESTION:\n" + userQuestion;

        org.springframework.ai.chat.model.ChatResponse response = chatModel.call(new org.springframework.ai.chat.prompt.Prompt(fullPrompt,
                org.springframework.ai.vertexai.gemini.VertexAiGeminiChatOptions.builder()
                        .model("gemini-2.5-flash")
                        .temperature(0.3)
                        .build()
        ));

        return response.getResult().getOutput().getText();
    }
}
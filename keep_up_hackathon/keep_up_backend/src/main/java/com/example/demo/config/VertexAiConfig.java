package com.example.demo.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.cloud.vertexai.VertexAI;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.vertexai.gemini.VertexAiGeminiChatModel;
import org.springframework.ai.vertexai.gemini.VertexAiGeminiChatOptions;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.io.FileInputStream;
import java.io.IOException;

@Configuration
public class VertexAiConfig {

    @Bean
    public VertexAI vertexAI() throws IOException {
        System.out.println("🔐 LOADING CREDENTIALS FROM: secrets/service-account.json");

        // 1. Load the credentials
        GoogleCredentials credentials = GoogleCredentials.fromStream(
                        new FileInputStream("secrets/service-account.json"))
                .createScoped("https://www.googleapis.com/auth/cloud-platform");

        // 2. Create VertexAI using the BUILDER (Fixes your error)
        System.out.println("✅ MANUALLY STARTING VERTEX AI WITH AUTH");
        return new VertexAI.Builder()
                .setProjectId("project-e0914f81-9c04-40ed-a44")
                .setLocation("asia-south1")
                .setCredentials(credentials)
                .build();
    }

    @Bean
    public ChatModel chatModel(VertexAI vertexAI) {
        System.out.println("✅ MANUALLY STARTING GEMINI CHAT MODEL");

        // 3. Create ChatModel using the BUILDER
        return VertexAiGeminiChatModel.builder()
                .vertexAI(vertexAI)
                .defaultOptions(VertexAiGeminiChatOptions.builder()
                        .model("gemini-2.5-flash")
                        .temperature(0.4)
                        .build())
                .build();
    }
}
package com.example.demo.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.example.demo.model.ToonSegment;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
public class NewsIndexingService {

    private final FirestoreService firestoreService;
    private final ObjectMapper objectMapper;

    public NewsIndexingService(FirestoreService firestoreService) {
        this.firestoreService = firestoreService;
        this.objectMapper = new ObjectMapper();
    }

    // 1. Process and Save News (Gemini -> Database)
    public void processAndSave(String jsonOutput) {
        try {
            // Clean the JSON string
            String cleanJson = jsonOutput.replace("```json", "").replace("```", "").trim();

            // Convert string to Java Objects
            List<ToonSegment> segments = objectMapper.readValue(cleanJson, new TypeReference<List<ToonSegment>>(){});

            // Save each segment
            for (ToonSegment segment : segments) {
                if (segment.getId() == null) segment.setId(UUID.randomUUID().toString());
                firestoreService.saveToonSegment(segment);
            }
            System.out.println("Successfully indexed " + segments.size() + " segments!");

        } catch (Exception e) {
            System.err.println("Error parsing JSON: " + e.getMessage());
        }
    }

    // 2. Fetch all news for the Chatbot
    public List<ToonSegment> getAllNewsSegments() {
        try {
            return firestoreService.getAllToonSegments();
        } catch (Exception e) {
            System.err.println("Error fetching news: " + e.getMessage());
            return java.util.Collections.emptyList();
        }
    }
}
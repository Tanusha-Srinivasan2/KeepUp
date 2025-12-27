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
    private final ObjectMapper objectMapper; // Converts String <-> JSON

    public NewsIndexingService(FirestoreService firestoreService) {
        this.firestoreService = firestoreService;
        this.objectMapper = new ObjectMapper();
    }

    public void processAndSave(String jsonOutput) {
        try {
            // 1. Clean up the string (Gemini sometimes adds ```json markers)
            String cleanJson = jsonOutput.replace("```json", "").replace("```", "").trim();

            // 2. Convert string to Java Objects
            List<ToonSegment> segments = objectMapper.readValue(cleanJson, new TypeReference<List<ToonSegment>>(){});

            // 3. Save each segment individually
            for (ToonSegment segment : segments) {
                // Ensure it has an ID
                if (segment.getId() == null) segment.setId(UUID.randomUUID().toString());

                // Save to 'toon_index' collection
                firestoreService.saveToonSegment(segment);
            }
            System.out.println("Successfully indexed " + segments.size() + " segments!");

        } catch (Exception e) {
            System.err.println("Error parsing JSON: " + e.getMessage());
        }
    }
}
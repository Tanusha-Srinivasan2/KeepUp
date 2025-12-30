package com.example.demo.service;

import com.example.demo.model.Toon; // <--- FIX: Import the new Toon class
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import com.google.firebase.cloud.FirestoreClient; // <--- FIX: Direct Firestore access
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.ExecutionException;

@Service
public class NewsIndexingService {

    private final ObjectMapper objectMapper;
    private static final String COLLECTION_NAME = "toon_index"; // The collection in your DB screenshot

    public NewsIndexingService() {
        this.objectMapper = new ObjectMapper();
    }

    // 1. Process and Save News (Gemini -> Database)
    public void processAndSave(String jsonOutput) {
        try {
            // Clean the JSON string (Gemini sometimes adds markdown blocks)
            String cleanJson = jsonOutput.replace("```json", "").replace("```", "").trim();

            // Convert string to List of 'Toon' objects
            List<Toon> newToons = objectMapper.readValue(cleanJson, new TypeReference<List<Toon>>() {});

            Firestore db = FirestoreClient.getFirestore();

            // Save each Toon to Firestore
            for (Toon toon : newToons) {
                // Generate ID if missing
                if (toon.getId() == null || toon.getId().isEmpty()) {
                    toon.setId(UUID.randomUUID().toString());
                }

                // Save to 'toon_index' collection
                db.collection(COLLECTION_NAME).document(toon.getId()).set(toon);
                System.out.println("✅ Saved Toon: " + toon.getTitle());
            }

        } catch (Exception e) {
            System.err.println("❌ Error processing news JSON: " + e.getMessage());
            e.printStackTrace();
        }
    }

    // 2. Fetch all news for the Feed and Chat
    public List<Toon> getAllNewsSegments() {
        List<Toon> newsList = new ArrayList<>();
        Firestore db = FirestoreClient.getFirestore();

        try {
            // Fetch all documents from 'toon_index'
            List<QueryDocumentSnapshot> documents = db.collection(COLLECTION_NAME).get().get().getDocuments();

            for (QueryDocumentSnapshot document : documents) {
                // Map Firestore document to 'Toon' class
                Toon toon = document.toObject(Toon.class);
                toon.setId(document.getId());
                newsList.add(toon);
            }
        } catch (InterruptedException | ExecutionException e) {
            System.err.println("❌ Error fetching news: " + e.getMessage());
        }

        return newsList;
    }
}
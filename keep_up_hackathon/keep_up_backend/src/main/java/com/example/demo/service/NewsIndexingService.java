package com.example.demo.service;

import com.example.demo.model.Toon;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.Query;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import com.google.firebase.cloud.FirestoreClient;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.ExecutionException;

@Service
public class NewsIndexingService {

    private final ObjectMapper objectMapper;
    // ✅ FIX: Use "toon_index" to match your database screenshot
    private static final String COLLECTION_NAME = "toon_index";

    public NewsIndexingService() {
        this.objectMapper = new ObjectMapper();
    }

    // 1. Process and Save (Gemini -> DB)
    public void processAndSave(String jsonOutput) {
        try {
            String cleanJson = jsonOutput.replace("```json", "").replace("```", "").trim();
            List<Toon> newToons = objectMapper.readValue(cleanJson, new TypeReference<List<Toon>>() {});

            Firestore db = FirestoreClient.getFirestore();
            String todayDate = LocalDate.now().toString();
            long nowTimestamp = System.currentTimeMillis();

            for (Toon toon : newToons) {
                if (toon.getId() == null || toon.getId().isEmpty()) {
                    toon.setId(UUID.randomUUID().toString());
                }
                // Auto-stamp date
                toon.setPublishedDate(todayDate);
                toon.setTimestamp(nowTimestamp);

                db.collection(COLLECTION_NAME).document(toon.getId()).set(toon);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    // ✅ 2. FETCH NEWS (Logic moved here!)
    public List<Toon> getAllNewsSegments(String dateFilter) {
        List<Toon> newsList = new ArrayList<>();
        Firestore db = FirestoreClient.getFirestore();

        try {
            Query query;

            if (dateFilter != null && !dateFilter.isEmpty()) {
                // 🗓️ FILTER: Get news for specific date
                System.out.println("🔎 Filtering for date: " + dateFilter);
                query = db.collection(COLLECTION_NAME).whereEqualTo("publishedDate", dateFilter);
            } else {
                // ⚡ DEFAULT: Sort by Newest First
                query = db.collection(COLLECTION_NAME)
                        .orderBy("timestamp", Query.Direction.DESCENDING)
                        .limit(50);
            }

            List<QueryDocumentSnapshot> documents = query.get().get().getDocuments();

            for (QueryDocumentSnapshot document : documents) {
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
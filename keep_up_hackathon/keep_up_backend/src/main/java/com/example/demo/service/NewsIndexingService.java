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
import java.util.stream.Collectors;

@Service
public class NewsIndexingService {

    private final ObjectMapper objectMapper;
    private static final String COLLECTION_NAME = "toon_index";

    public NewsIndexingService() {
        this.objectMapper = new ObjectMapper();
    }

    // ✅ 1. Process and Save (Now accepts optional dateOverride)
    public void processAndSave(String jsonOutput, String dateOverride) {
        try {
            String cleanJson = jsonOutput.replace("```json", "").replace("```", "").trim();
            List<Toon> newToons = objectMapper.readValue(cleanJson, new TypeReference<List<Toon>>() {});

            Firestore db = FirestoreClient.getFirestore();

            // Logic: Use override if provided, otherwise Today
            String targetDate;
            long timestamp;

            if (dateOverride != null && !dateOverride.isEmpty()) {
                targetDate = dateOverride;
                // Create a dummy timestamp for that day
                timestamp = java.sql.Date.valueOf(targetDate).getTime();
            } else {
                targetDate = LocalDate.now().toString();
                timestamp = System.currentTimeMillis();
            }

            for (Toon toon : newToons) {
                if (toon.getId() == null || toon.getId().isEmpty()) {
                    toon.setId(UUID.randomUUID().toString());
                }

                // Apply the date
                toon.setPublishedDate(targetDate);
                toon.setTimestamp(timestamp);

                db.collection(COLLECTION_NAME).document(toon.getId()).set(toon);
                System.out.println("✅ Saved Toon: " + toon.getTitle() + " [" + targetDate + "]");
            }

        } catch (Exception e) {
            System.err.println("❌ Error processing news JSON: " + e.getMessage());
            e.printStackTrace();
        }
    }

    // ✅ 2. Fetch News (Supports Date Filtering)
    public List<Toon> getAllNewsSegments(String dateFilter) {
        List<Toon> newsList = new ArrayList<>();
        Firestore db = FirestoreClient.getFirestore();

        try {
            Query query;

            if (dateFilter != null && !dateFilter.isEmpty()) {
                // Filter by specific date
                System.out.println("🔎 Filtering for date: " + dateFilter);
                query = db.collection(COLLECTION_NAME).whereEqualTo("publishedDate", dateFilter);
            } else {
                // Default: Sort by Newest
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
    public List<Toon> searchNewsByKeywords(String keywordString) {
        if (keywordString == null || keywordString.isEmpty()) return new ArrayList<>();

        // 1. Fetch recent news (e.g., last 50 items) to search against
        List<Toon> recentNews = getAllNewsSegments(null);

        String[] keywords = keywordString.toLowerCase().split("\\s+"); // Split by spaces

        return recentNews.stream()
                .filter(toon -> {
                    String content = (toon.getTitle() + " " + toon.getDescription() + " " + toon.getTopic()).toLowerCase();
                    // Match IF content contains ANY of the keywords
                    for (String key : keywords) {
                        if (content.contains(key)) return true;
                    }
                    return false;
                })
                .limit(3) // Limit to top 3 matches to save tokens
                .collect(Collectors.toList());
    }
}
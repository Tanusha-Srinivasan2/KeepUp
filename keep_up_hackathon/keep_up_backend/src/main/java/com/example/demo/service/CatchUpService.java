package com.example.demo.service;

import com.example.demo.model.Toon;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.Query;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.*;
import java.util.concurrent.ExecutionException;

@Service
public class CatchUpService {

    private final Firestore db;
    private final NewsIndexingService newsIndexingService;
    private final VertexAiService vertexAiService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public CatchUpService(Firestore db, NewsIndexingService newsIndexingService, VertexAiService vertexAiService) {
        this.db = db;
        this.newsIndexingService = newsIndexingService;
        this.vertexAiService = vertexAiService;
    }

    public List<Map<String, Object>> getWeeklyCatchUp(String region) throws Exception {

        // 1. BACKFILL: Ensure summaries exist for the last 3 days
        // (So your list isn't empty for the demo)
        for (int i = 0; i < 3; i++) {
            String targetDate = LocalDate.now().minusDays(i).toString();
            ensureSummaryExistsForDate(targetDate, region);
        }

        // 2. FETCH: Get all summaries from DB (Sorted Newest First)
        List<QueryDocumentSnapshot> docs = db.collection("daily_catchup")
                .orderBy("date", Query.Direction.DESCENDING)
                .limit(7) // Show up to 7 days
                .get().get().getDocuments();

        // 3. BUILD RESPONSE
        List<Map<String, Object>> responseList = new ArrayList<>();

        for (QueryDocumentSnapshot doc : docs) {
            Map<String, Object> dayMap = new HashMap<>();
            dayMap.put("date", doc.getString("date"));

            // Parse stored JSON string back to Object
            String jsonContent = doc.getString("jsonContent");
            if (jsonContent != null && !jsonContent.equals("[]")) {
                Object summaryObj = objectMapper.readValue(jsonContent, List.class);
                dayMap.put("summary", summaryObj);
                responseList.add(dayMap);
            }
        }

        return responseList;
    }

    // Helper: Checks if summary exists for a specific date; if not, generates it.
    private void ensureSummaryExistsForDate(String date, String region) throws ExecutionException, InterruptedException {
        String docId = "summary_" + date;

        // A. Check Cache
        if (db.collection("daily_catchup").document(docId).get().get().exists()) {
            return; // Already exists, skip.
        }

        System.out.println("⚡ Attempting to generate Summary for: " + date);

        // B. Fetch News STRICTLY for this date
        List<Toon> dailyNews = newsIndexingService.getAllNewsSegments(date);

        // ❌ REMOVED FALLBACK: If no news for this date, we do NOT fetch generic news.
        if (dailyNews.isEmpty()) {
            System.out.println("⚠️ No news found for " + date + ". Skipping summary.");
            return;
        }

        // C. Prepare AI Context
        StringBuilder contextBuilder = new StringBuilder();
        contextBuilder.append("DATE: ").append(date).append("\n"); // Tell AI the date

        for (Toon t : dailyNews) {
            contextBuilder.append(String.format("- %s: %s\n", t.getTitle(), t.getDescription()));
        }

        // D. Generate with AI
        String generatedJson = vertexAiService.generateCatchUpContent(contextBuilder.toString());

        // E. Save to DB
        if (generatedJson != null && generatedJson.length() > 10) {
            Map<String, Object> data = new HashMap<>();
            data.put("date", date);
            data.put("region", region);
            data.put("jsonContent", generatedJson);
            data.put("createdAt", System.currentTimeMillis());

            db.collection("daily_catchup").document(docId).set(data);
            System.out.println("💾 Saved summary for " + date);
        }
    }
}
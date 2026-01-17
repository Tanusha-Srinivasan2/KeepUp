package com.example.demo.service;

import com.example.demo.model.Toon;
import com.example.demo.repository.ToonRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.Query;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import com.google.firebase.cloud.FirestoreClient;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.*;
import java.util.concurrent.ExecutionException;

@Service
public class CatchUpService {

    private final ToonRepository toonRepository;
    private final VertexAiService vertexAiService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public CatchUpService(ToonRepository toonRepository, VertexAiService vertexAiService) {
        this.toonRepository = toonRepository;
        this.vertexAiService = vertexAiService;
    }

    public List<Map<String, Object>> getWeeklyCatchUp(String region) throws Exception {
        Firestore db = FirestoreClient.getFirestore();

        // 1. BACKFILL: Ensure summaries exist for last 3 days
        for (int i = 0; i < 3; i++) {
            String targetDate = LocalDate.now().minusDays(i).toString();
            ensureSummaryExistsForDate(db, targetDate, region);
        }

        // 2. FETCH: Get summaries sorted by date desc
        List<QueryDocumentSnapshot> docs = db.collection("daily_catchup")
                .orderBy("date", Query.Direction.DESCENDING)
                .limit(7)
                .get().get().getDocuments();

        // 3. BUILD RESPONSE
        List<Map<String, Object>> responseList = new ArrayList<>();

        for (QueryDocumentSnapshot doc : docs) {
            Map<String, Object> dayMap = new HashMap<>();
            dayMap.put("date", doc.getString("date"));

            String jsonContent = doc.getString("jsonContent");
            // Only add if content is valid
            if (jsonContent != null && !jsonContent.equals("[]")) {
                try {
                    Object summaryObj = objectMapper.readValue(jsonContent, List.class);
                    dayMap.put("summary", summaryObj);
                    responseList.add(dayMap);
                } catch (Exception e) {
                    System.err.println("Skipping invalid JSON for date: " + doc.getString("date"));
                }
            }
        }
        return responseList;
    }

    private void ensureSummaryExistsForDate(Firestore db, String date, String region) throws ExecutionException, InterruptedException {
        String docId = "summary_" + date;

        // Check if summary already exists to avoid re-generating (saving money)
        if (db.collection("daily_catchup").document(docId).get().get().exists()) {
            return;
        }

        System.out.println("⚡ Generating CatchUp Summary for: " + date);

        // ✅ FIX: Convert Reactive Flux to Blocking List
        List<Toon> dailyNews = toonRepository.findByPublishedDate(date).collectList().block();

        if (dailyNews == null || dailyNews.isEmpty()) {
            System.out.println("⚠️ No news found for " + date + ". Skipping summary generation.");
            return;
        }

        // 2. Build Context for the AI
        StringBuilder contextBuilder = new StringBuilder();
        contextBuilder.append("EVENTS FOR DATE: ").append(date).append("\n");
        contextBuilder.append("INSTRUCTIONS: Summarize ONLY these specific events into a daily recap.\n");

        for (Toon t : dailyNews) {
            contextBuilder.append(String.format("- %s: %s\n", t.getTitle(), t.getDescription()));
        }

        // 3. Generate Summary
        String generatedJson = vertexAiService.generateCatchUpContent(contextBuilder.toString());

        // 4. Save to Database
        if (generatedJson != null && generatedJson.length() > 10) {
            Map<String, Object> data = new HashMap<>();
            data.put("date", date);
            data.put("region", region);
            data.put("jsonContent", generatedJson);
            data.put("createdAt", System.currentTimeMillis());

            db.collection("daily_catchup").document(docId).set(data);
            System.out.println("💾 Saved CatchUp summary for " + date);
        }
    }
}
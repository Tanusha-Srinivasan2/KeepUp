package com.example.demo.service;

import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.DocumentSnapshot;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutionException;

@Service
public class CatchUpService {

    private final Firestore db;
    private final VertexAiService vertexAiService;

    public CatchUpService(Firestore db, VertexAiService vertexAiService) {
        this.db = db;
        this.vertexAiService = vertexAiService;
    }

    public String getDailyCatchUp(String region) throws ExecutionException, InterruptedException {
        // 1. Generate a unique ID for today (e.g., "summary_US_2025-12-28")
        String todayDate = LocalDate.now().toString();
        String docId = "summary_" + region + "_" + todayDate;

        // 2. Check if we already have it in Firestore
        DocumentSnapshot doc = db.collection("daily_catchup").document(docId).get().get();

        if (doc.exists()) {
            System.out.println("✅ Found cached summary for " + todayDate);
            // Return the stored JSON string directly
            return doc.getString("jsonContent");
        }

        // 3. If NOT found, Generate it using AI
        System.out.println("⚡ Generating new summary for " + todayDate);
        String newJsonContent = vertexAiService.generateCatchUpContent(region);

        // 4. Save it to Firestore for next time
        Map<String, Object> data = new HashMap<>();
        data.put("date", todayDate);
        data.put("region", region);
        data.put("jsonContent", newJsonContent);
        data.put("createdAt", System.currentTimeMillis());

        db.collection("daily_catchup").document(docId).set(data);

        return newJsonContent;
    }
}
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

    // Remove VertexAiService from here since the Controller now handles generation
    public CatchUpService(Firestore db) {
        this.db = db;
    }

    // 1. READ CACHE: Check if we have a summary for today
    public String getTodaySummary() throws ExecutionException, InterruptedException {
        String todayDate = LocalDate.now().toString(); // e.g., "2025-12-31"
        String docId = "summary_" + todayDate;

        // Check Firestore
        DocumentSnapshot doc = db.collection("daily_catchup").document(docId).get().get();

        if (doc.exists()) {
            System.out.println("✅ Found cached CatchUp summary for " + todayDate);
            return doc.getString("jsonContent");
        }

        // Return null if nothing is found (tells Controller to generate new one)
        return null;
    }

    // 2. WRITE CACHE: Save the new AI summary to Firestore
    public void saveDailyCatchUp(String jsonContent) {
        String todayDate = LocalDate.now().toString();
        String docId = "summary_" + todayDate;

        Map<String, Object> data = new HashMap<>();
        data.put("date", todayDate);
        data.put("jsonContent", jsonContent);
        data.put("createdAt", System.currentTimeMillis());

        // Save to "daily_catchup" collection
        db.collection("daily_catchup").document(docId).set(data);
        System.out.println("💾 CatchUp summary saved to Firestore: " + docId);
    }
}
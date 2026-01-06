package com.example.demo.service;

import com.fasterxml.jackson.databind.ObjectMapper; // Standard Spring Boot JSON parser
import com.google.cloud.firestore.Firestore;
import org.springframework.stereotype.Service;
import java.util.*;
import java.util.concurrent.ExecutionException;

@Service
public class QuizService {

    private final Firestore db;
    private final ObjectMapper objectMapper = new ObjectMapper(); // Logic to parse JSON string to Map

    public QuizService(Firestore db) {
        this.db = db;
    }

    // --- MAIN DAILY QUIZ (Existing) ---
    public void saveDailyQuiz(String quizJson) {
        try {
            db.collection("daily_quizzes").document("latest_quiz")
                    .set(Map.of("jsonContent", quizJson));
        } catch (Exception e) { e.printStackTrace(); }
    }

    public String getDailyQuiz() throws ExecutionException, InterruptedException {
        var doc = db.collection("daily_quizzes").document("latest_quiz").get().get();
        return doc.exists() ? doc.getString("jsonContent") : "[]";
    }

    // --- ✅ NEW: CATEGORY QUIZ LOGIC ---

    // 1. SPLIT & SAVE: Takes the big JSON, splits it by category, saves separately
    public void saveCategoryQuizzes(String jsonResponse, String date) {
        try {
            // Convert String JSON -> Java Map
            Map<String, Object> allQuizzes = objectMapper.readValue(jsonResponse, Map.class);

            // Loop through "Technology", "Sports", etc.
            for (String category : allQuizzes.keySet()) {
                String docId = date + "_" + category; // ID: "2026-01-06_Technology"

                Map<String, Object> quizData = new HashMap<>();
                quizData.put("date", date);
                quizData.put("category", category);
                quizData.put("questions", allQuizzes.get(category)); // The list of 3 questions

                // Save to new collection
                db.collection("category_quizzes").document(docId).set(quizData);
                System.out.println("✅ Saved Quiz for: " + category);
            }
        } catch (Exception e) {
            System.err.println("Failed to parse category quizzes: " + e.getMessage());
        }
    }

    // 2. RETRIEVE: Fetch a specific quiz (e.g., when user clicks "Attempt Quiz" on Sports card)
    public List<Map<String, Object>> getQuizByCategory(String date, String category) throws ExecutionException, InterruptedException {
        String docId = date + "_" + category;
        var doc = db.collection("category_quizzes").document(docId).get().get();

        if (doc.exists()) {
            return (List<Map<String, Object>>) doc.get("questions");
        }
        return Collections.emptyList(); // Return empty if not found
    }
}
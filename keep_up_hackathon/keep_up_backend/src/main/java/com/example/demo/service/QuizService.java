package com.example.demo.service;

import com.google.cloud.firestore.Firestore;
import org.springframework.stereotype.Service;
import java.util.concurrent.ExecutionException; // <--- FIX 1: Added Import
import java.util.List;
import java.util.Map;

@Service
public class QuizService {

    private final Firestore db;

    public QuizService(Firestore db) {
        this.db = db;
    }

    // Save the quiz to Firestore
    public void saveDailyQuiz(String quizJson) {
        try {
            // We save it as a simple map: { "jsonContent": "..." }
            // Using a timestamp ID or "latest" to overwrite helps retrieval
            db.collection("daily_quizzes")
                    .document("latest_quiz")
                    .set(Map.of("jsonContent", quizJson));

            System.out.println("Quiz Saved!");
        } catch (Exception e) {
            System.err.println("Error saving quiz: " + e.getMessage());
        }
    }

    // Fetch the most recent quiz
    // FIX 2: Added "throws" so the controller handles errors
    public String getDailyQuiz() throws ExecutionException, InterruptedException {
        var doc = db.collection("daily_quizzes").document("latest_quiz").get().get();

        if (doc.exists()) {
            return doc.getString("jsonContent");
        }
        return "[]"; // Return empty list if no quiz found
    }
}
package com.example.demo.service;

import com.google.cloud.firestore.Firestore;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import org.springframework.stereotype.Service;

import java.time.LocalDate; // Import this!
import java.util.List;
import java.util.Map;

@Service
public class QuizService {

    private final Firestore firestore;
    private final Gson gson = new Gson();

    public QuizService(Firestore firestore) {
        this.firestore = firestore;
    }

    public void saveDailyQuiz(String quizJson) {
        // 1. Clean JSON
        String cleanJson = quizJson.replace("```json", "").replace("```", "").trim();

        // 2. Parse JSON
        List<Map<String, Object>> questions = gson.fromJson(cleanJson, new TypeToken<List<Map<String, Object>>>(){}.getType());

        // 3. CHANGE: Use Today's Date as the ID (e.g., "2025-12-27")
        String todayId = LocalDate.now().toString();

        // Optional: Print it so you can see it in logs
        System.out.println("📅 Saving Quiz for Date: " + todayId);

        for (Map<String, Object> question : questions) {
            firestore.collection("daily_challenges")
                    .document(todayId) // <--- NOW IT IS EASY TO FIND!
                    .collection("questions")
                    .add(question);
        }
    }
}
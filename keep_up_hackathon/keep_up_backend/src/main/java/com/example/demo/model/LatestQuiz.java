package com.example.demo.model;

import com.google.cloud.spring.data.firestore.Document;
import com.google.cloud.firestore.annotation.DocumentId;

@Document(collectionName = "daily_quizzes")
public class LatestQuiz {

    @DocumentId
    private String id; // This will be "latest_quiz"
    private String jsonContent; // Stores the raw JSON string

    public LatestQuiz() {}

    public LatestQuiz(String id, String jsonContent) {
        this.id = id;
        this.jsonContent = jsonContent;
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getJsonContent() { return jsonContent; }
    public void setJsonContent(String jsonContent) { this.jsonContent = jsonContent; }
}
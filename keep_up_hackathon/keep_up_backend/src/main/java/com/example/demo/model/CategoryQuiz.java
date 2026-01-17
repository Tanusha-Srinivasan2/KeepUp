package com.example.demo.model;

import com.google.cloud.spring.data.firestore.Document;
import com.google.cloud.firestore.annotation.DocumentId;
import java.util.List;

@Document(collectionName = "category_quizzes")
public class CategoryQuiz {

    @DocumentId
    private String id; // Format: "2026-01-16_Technology"
    private String date;
    private String category;
    private List<QuizQuestion> questions; // Reusing your existing class as an item

    public CategoryQuiz() {}

    public CategoryQuiz(String id, String date, String category, List<QuizQuestion> questions) {
        this.id = id;
        this.date = date;
        this.category = category;
        this.questions = questions;
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getDate() { return date; }
    public void setDate(String date) { this.date = date; }
    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }
    public List<QuizQuestion> getQuestions() { return questions; }
    public void setQuestions(List<QuizQuestion> questions) { this.questions = questions; }
}
package com.example.demo.model;

import com.google.cloud.spring.data.firestore.Document;
import com.google.cloud.firestore.annotation.DocumentId;
import java.util.List;

// ✅ FORCE THIS TO BE "category_quizzes"
@Document(collectionName = "category_quizzes")
public class CategoryQuizQuestion {

    @DocumentId
    private String id;
    private String date;
    private String category; // e.g., "Technology", "Sports"

    private String topic;
    private String question;
    private List<String> options;
    private int correctIndex;
    private String explanation;

    public CategoryQuizQuestion() {}

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getDate() { return date; }
    public void setDate(String date) { this.date = date; }
    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }
    public String getTopic() { return topic; }
    public void setTopic(String topic) { this.topic = topic; }
    public String getQuestion() { return question; }
    public void setQuestion(String question) { this.question = question; }
    public List<String> getOptions() { return options; }
    public void setOptions(List<String> options) { this.options = options; }
    public int getCorrectIndex() { return correctIndex; }
    public void setCorrectIndex(int correctIndex) { this.correctIndex = correctIndex; }
    public String getExplanation() { return explanation; }
    public void setExplanation(String explanation) { this.explanation = explanation; }
}
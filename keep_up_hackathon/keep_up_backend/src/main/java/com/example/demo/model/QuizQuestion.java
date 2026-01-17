package com.example.demo.model;

import java.util.List;

// ❌ NO @Document annotation here!
public class QuizQuestion {
    private String topic;
    private String question;
    private List<String> options;
    private int correctIndex;
    private String explanation;

    public QuizQuestion() {}

    // Getters and Setters
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
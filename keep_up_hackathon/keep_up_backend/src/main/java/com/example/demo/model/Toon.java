package com.example.demo.model;

import java.util.List;

// This class represents ONE line of news, not the whole story.
public class ToonSegment {
    private String id;           // Unique ID (e.g., "NEWS-01-LINE-5")
    private String topic;        // e.g., "Technology"
    private String contentLine;  // The actual sentence: "SpaceX launch failed."
    private List<String> keywords; // ["SpaceX", "Rocket", "Fail"]

    // Empty constructor is needed for JSON/Firestore tools
    public ToonSegment() {}

    public ToonSegment(String id, String topic, String contentLine, List<String> keywords) {
        this.id = id;
        this.topic = topic;
        this.contentLine = contentLine;
        this.keywords = keywords;
    }

    // This creates the "Cheat Sheet" string for the AI
    public String toToonString() {
        return String.format("[%s | %s]: %s", id, topic, contentLine);
    }

    // Standard Getters and Setters (Use IntelliJ: Right Click -> Generate -> Getters and Setters)
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getTopic() { return topic; }
    public void setTopic(String topic) { this.topic = topic; }
    public String getContentLine() { return contentLine; }
    public void setContentLine(String contentLine) { this.contentLine = contentLine; }
    public List<String> getKeywords() { return keywords; }
    public void setKeywords(List<String> keywords) { this.keywords = keywords; }
}
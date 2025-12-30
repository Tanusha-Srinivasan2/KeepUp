package com.example.demo.model;

// 1. REMOVED the import for DocumentId
// import com.google.cloud.firestore.annotation.DocumentId;

import java.util.List;

public class Toon {

    // 2. REMOVED the @DocumentId annotation
    // This allows the "id" field to be treated like normal data without crashing
    private String id;

    // --- NEW FIELDS FOR FLUTTER CARDS ---
    private String title;        // "NASA Confirms Ocean"
    private String description;  // "We are now closer than ever..."
    private String imageUrl;     // URL to the image
    private String time;         // "2h ago"

    // --- EXISTING FIELDS ---
    private String topic;        // "Science"
    private List<String> keywords; // ["NASA", "Space"]
    private String contentLine; // Keeping this for backward compatibility

    public Toon() {} // Required for Firestore

    public Toon(String title, String description, String imageUrl, String time, String topic, List<String> keywords) {
        this.title = title;
        this.description = description;
        this.imageUrl = imageUrl;
        this.time = time;
        this.topic = topic;
        this.keywords = keywords;
    }

    // --- GETTERS AND SETTERS ---
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getImageUrl() { return imageUrl; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }

    public String getTime() { return time; }
    public void setTime(String time) { this.time = time; }

    public String getTopic() { return topic; }
    public void setTopic(String topic) { this.topic = topic; }

    public List<String> getKeywords() { return keywords; }
    public void setKeywords(List<String> keywords) { this.keywords = keywords; }

    public String getContentLine() { return contentLine; }
    public void setContentLine(String contentLine) { this.contentLine = contentLine; }

    // Helper for Chat Context (Important for ChatBot)
    public String toToonString() {
        return String.format("[%s | %s]: %s", topic, title != null ? title : "News", description != null ? description : "No details");
    }
}
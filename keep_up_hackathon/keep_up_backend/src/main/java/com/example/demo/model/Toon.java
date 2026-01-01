package com.example.demo.model;

import java.util.List;

public class Toon {

    private String id;

    // --- NEW FIELDS FOR SORTING & FILTERING ---
    private long timestamp;       // e.g., 1704094000000 (For sorting newest first)
    private String publishedDate; // e.g., "2025-12-30" (For calendar filtering)

    // --- FLUTTER CARD FIELDS ---
    private String title;
    private String description;
    private String imageUrl;
    private String time;

    // --- EXISTING FIELDS ---
    private String topic;
    private List<String> keywords;
    private String contentLine;

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

    // ✅ New Getters/Setters for Date Logic
    public long getTimestamp() { return timestamp; }
    public void setTimestamp(long timestamp) { this.timestamp = timestamp; }

    public String getPublishedDate() { return publishedDate; }
    public void setPublishedDate(String publishedDate) { this.publishedDate = publishedDate; }

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

    public String toToonString() {
        return String.format("[%s | %s]: %s", topic, title != null ? title : "News", description != null ? description : "No details");
    }
}
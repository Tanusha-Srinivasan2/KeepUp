package com.example.demo.model;

import com.google.cloud.spring.data.firestore.Document;
import com.google.cloud.firestore.annotation.DocumentId;
import java.util.List;

// ✅ FORCE THIS TO BE "toon_index"
@Document(collectionName = "toon_index")
public class Toon {

    @DocumentId
    private String id;

    private String topic;
    private String title;
    private String description;
    private String imageUrl;
    private String time;
    private List<String> keywords;
    private String sourceUrl;
    private String publishedDate;
    private long timestamp;

    public Toon() {} // Required for Firestore

    // --- Getters and Setters ---
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getTopic() { return topic; }
    public void setTopic(String topic) { this.topic = topic; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public String getImageUrl() { return imageUrl; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }
    public String getTime() { return time; }
    public void setTime(String time) { this.time = time; }
    public List<String> getKeywords() { return keywords; }
    public void setKeywords(List<String> keywords) { this.keywords = keywords; }
    public String getSourceUrl() { return sourceUrl; }
    public void setSourceUrl(String sourceUrl) { this.sourceUrl = sourceUrl; }
    public String getPublishedDate() { return publishedDate; }
    public void setPublishedDate(String publishedDate) { this.publishedDate = publishedDate; }
    public long getTimestamp() { return timestamp; }
    public void setTimestamp(long timestamp) { this.timestamp = timestamp; }
}
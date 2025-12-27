package com.example.demo.model;
import com.google.cloud.Timestamp;
import java.util.List;

public class NewsSummary {
    private String id;           // usually the date, e.g., "2025-10-27-US"
    private String region;       // e.g., "US", "India"
    private Timestamp createdAt; // When this was generated
    private List<ToonSegment> segments; // The list of structured news items

    // Empty constructor for Firestore
    public NewsSummary() {}

    public NewsSummary(String id, String region, List<ToonSegment> segments) {
        this.id = id;
        this.region = region;
        this.segments = segments;
        this.createdAt = Timestamp.now();
    }

    // Getters and Setters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getRegion() { return region; }
    public void setRegion(String region) { this.region = region; }

    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }

    public List<ToonSegment> getSegments() { return segments; }
    public void setSegments(List<ToonSegment> segments) { this.segments = segments; }
}
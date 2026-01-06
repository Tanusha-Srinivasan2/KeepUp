package com.example.demo.model;

import java.util.HashMap;
import java.util.Map;

public class User {
    private String userId;
    private String username;
    private int xp;
    private String league; // "Bronze", "Silver", "Gold"
    private String cohortId;

    // ✅ NEW: Tracks when they last earned points for EACH category
    // Key = Category Name (e.g., "Daily", "Technology"), Value = Date (e.g., "2026-01-06")
    private Map<String, String> lastPlayed;

    public User() {} // Required for Firestore

    public User(String userId, String username) {
        this.userId = userId;
        this.username = username;
        this.xp = 0;
        this.league = "Bronze";
        this.lastPlayed = new HashMap<>(); // Initialize empty map
    }

    // Getters and Setters
    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public int getXp() { return xp; }
    public void setXp(int xp) { this.xp = xp; }

    public String getLeague() { return league; }
    public void setLeague(String league) { this.league = league; }

    public String getCohortId() { return cohortId; }
    public void setCohortId(String cohortId) { this.cohortId = cohortId; }

    // ✅ Getter/Setter for Map
    public Map<String, String> getLastPlayed() { return lastPlayed; }
    public void setLastPlayed(Map<String, String> lastPlayed) { this.lastPlayed = lastPlayed; }
}
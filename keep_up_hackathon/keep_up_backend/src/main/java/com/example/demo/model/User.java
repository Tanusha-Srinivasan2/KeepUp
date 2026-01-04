package com.example.demo.model;

public class User {
    private String userId;
    private String username;
    private int xp;
    private String league; // "Bronze", "Silver", "Gold"
    private String cohortId;

    // ✅ NEW: Tracks when they last earned points
    private String lastQuizDate;

    public User() {} // Required for Firestore

    public User(String userId, String username) {
        this.userId = userId;
        this.username = username;
        this.xp = 0;
        this.league = "Bronze";
        this.lastQuizDate = ""; // Default empty
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

    // ✅ Getter/Setter for Date
    public String getLastQuizDate() { return lastQuizDate; }
    public void setLastQuizDate(String lastQuizDate) { this.lastQuizDate = lastQuizDate; }
}
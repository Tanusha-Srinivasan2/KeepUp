package com.example.demo.model;

public class User {
    private String userId;
    private String username;
    private int xp;
    private String league; // "Bronze", "Silver", "Gold"

    // Empty constructor is REQUIRED for Firestore to work
    public User() {}

    public User(String userId, String username) {
        this.userId = userId;
        this.username = username;
        this.xp = 0;
        this.league = "Bronze"; // Everyone starts at the bottom
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
    // Inside User.java
    private String cohortId; // e.g., "Bronze-5"

    // Add Getter and Setter
    public String getCohortId() { return cohortId; }
    //public void setCohortId(String cohortId) { this.cohortId = cohortId; }//for later if random cohort simulation needed
}
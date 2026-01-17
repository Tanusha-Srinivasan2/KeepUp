package com.example.demo.model;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class User {
    private String userId;
    private String name;
    private int xp;
    private String league; // "Bronze", "Silver", "Gold"

    // ✅ Streak Tracking
    private int streak;
    private String lastActiveDate;

    // ✅ Cooldown Tracking
    private Map<String, String> lastPlayed;

    // ✅ NEW: Bookmarks List
    // Stores a list of news items (each item is a Map of title, topic, url, etc.)
    private List<Map<String, Object>> bookmarks;

    public User() {} // Required for Firestore

    public User(String userId, String name) {
        this.userId = userId;
        this.name = name;
        this.xp = 0;
        this.league = "Bronze";
        this.streak = 1;
        this.lastPlayed = new HashMap<>();
        this.lastActiveDate = java.time.LocalDate.now().toString();
        this.bookmarks = new ArrayList<>(); // Initialize empty list
    }

    // --- Getters and Setters ---
    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public int getXp() { return xp; }
    public void setXp(int xp) { this.xp = xp; }

    public String getLeague() { return league; }
    public void setLeague(String league) { this.league = league; }

    public int getStreak() { return streak; }
    public void setStreak(int streak) { this.streak = streak; }

    public String getLastActiveDate() { return lastActiveDate; }
    public void setLastActiveDate(String lastActiveDate) { this.lastActiveDate = lastActiveDate; }

    public Map<String, String> getLastPlayed() { return lastPlayed; }
    public void setLastPlayed(Map<String, String> lastPlayed) { this.lastPlayed = lastPlayed; }

    // ✅ New Getter/Setter for Bookmarks
    public List<Map<String, Object>> getBookmarks() {
        if (bookmarks == null) {
            return new ArrayList<>();
        }
        return bookmarks;
    }

    public void setBookmarks(List<Map<String, Object>> bookmarks) {
        this.bookmarks = bookmarks;
    }
}
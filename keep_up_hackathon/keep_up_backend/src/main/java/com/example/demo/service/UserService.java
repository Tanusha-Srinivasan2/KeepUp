package com.example.demo.service;

import com.google.cloud.firestore.*;
import com.google.firebase.cloud.FirestoreClient;
import com.example.demo.model.Toon;
import com.example.demo.model.User;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.*;
import java.util.concurrent.ExecutionException;

@Service
public class UserService {

    private static final String COLLECTION_NAME = "users";

    public String createUser(String userId, String name) {
        try {
            Firestore db = FirestoreClient.getFirestore();
            DocumentReference userRef = db.collection(COLLECTION_NAME).document(userId);

            if (userRef.get().get().exists()) return "User already exists";

            Map<String, Object> user = new HashMap<>();
            user.put("userId", userId);
            user.put("name", name);
            user.put("xp", 100);
            user.put("streak", 1);
            user.put("rank", 999);
            // ✅ Initialize empty map for tracking categories
            user.put("lastPlayed", new HashMap<String, String>());

            userRef.set(user);
            return "User Created";
        } catch (Exception e) {
            e.printStackTrace();
            return "Error";
        }
    }

    public String updateUserName(String userId, String newName) throws ExecutionException, InterruptedException {
        FirestoreClient.getFirestore().collection(COLLECTION_NAME).document(userId).update("name", newName);
        return "Name Updated";
    }

    public Map<String, Object> getUserProfile(String userId) throws ExecutionException, InterruptedException {
        Firestore db = FirestoreClient.getFirestore();
        DocumentSnapshot doc = db.collection(COLLECTION_NAME).document(userId).get().get();

        if (!doc.exists()) {
            createUser(userId, "Reader");
            return getUserProfile(userId);
        }

        Map<String, Object> userData = doc.getData();
        long xp = (long) userData.getOrDefault("xp", 0L);
        userData.put("rank", getRank(xp));
        return userData;
    }

    public User getUserObject(String userId) throws ExecutionException, InterruptedException {
        DocumentSnapshot doc = FirestoreClient.getFirestore().collection(COLLECTION_NAME).document(userId).get().get();
        return doc.exists() ? doc.toObject(User.class) : null;
    }

    // ✅ UPDATED XP LOCK LOGIC (Per Category)
    public String addXp(String userId, int points, String category) throws ExecutionException, InterruptedException {
        Firestore db = FirestoreClient.getFirestore();
        DocumentReference userRef = db.collection(COLLECTION_NAME).document(userId);

        // 1. Fetch current user data
        DocumentSnapshot doc = userRef.get().get();
        if (!doc.exists()) return "User not found";

        String today = LocalDate.now().toString();

        // 2. Get the "lastPlayed" map (handle nulls safely)
        Map<String, String> lastPlayed = (Map<String, String>) doc.get("lastPlayed");
        if (lastPlayed == null) lastPlayed = new HashMap<>();

        // 3. CHECK: Did they play THIS specific category today?
        String lastDateForCategory = lastPlayed.getOrDefault(category, "");

        if (today.equals(lastDateForCategory)) {
            System.out.println("⛔ XP Blocked: " + category + " already played today by " + userId);
            return "Daily limit reached for " + category;
        }

        // 4. SUCCESS: Add points AND lock this specific category
        lastPlayed.put(category, today); // Update the map

        userRef.update("xp", FieldValue.increment(points));
        userRef.update("lastPlayed", lastPlayed); // Save the map back to DB

        return "XP Added";
    }

    // --- Leaderboard & Bookmarks (Standard) ---

    private int getRank(long myXp) throws ExecutionException, InterruptedException {
        AggregateQuerySnapshot snapshot = FirestoreClient.getFirestore().collection(COLLECTION_NAME)
                .whereGreaterThan("xp", myXp).count().get().get();
        return (int) snapshot.getCount() + 1;
    }

    public List<Map<String, Object>> getGlobalLeaderboard() throws ExecutionException, InterruptedException {
        List<QueryDocumentSnapshot> docs = FirestoreClient.getFirestore().collection(COLLECTION_NAME)
                .orderBy("xp", Query.Direction.DESCENDING).limit(10).get().get().getDocuments();

        List<Map<String, Object>> leaderboard = new ArrayList<>();
        int rank = 1;
        for (QueryDocumentSnapshot doc : docs) {
            Map<String, Object> entry = new HashMap<>();
            entry.put("rank", rank++);
            entry.put("name", doc.getString("name"));
            entry.put("xp", doc.getLong("xp"));
            leaderboard.add(entry);
        }
        return leaderboard;
    }

    public String addBookmark(String userId, Toon newsItem) {
        FirestoreClient.getFirestore().collection(COLLECTION_NAME).document(userId)
                .collection("bookmarks").document(newsItem.getId()).set(newsItem);
        return "Saved";
    }

    public String removeBookmark(String userId, String newsId) {
        FirestoreClient.getFirestore().collection(COLLECTION_NAME).document(userId)
                .collection("bookmarks").document(newsId).delete();
        return "Removed";
    }

    public List<Toon> getBookmarks(String userId) throws Exception {
        List<Toon> list = new ArrayList<>();
        List<QueryDocumentSnapshot> docs = FirestoreClient.getFirestore()
                .collection(COLLECTION_NAME).document(userId)
                .collection("bookmarks").get().get().getDocuments();
        for (QueryDocumentSnapshot d : docs) list.add(d.toObject(Toon.class));
        return list;
    }
}
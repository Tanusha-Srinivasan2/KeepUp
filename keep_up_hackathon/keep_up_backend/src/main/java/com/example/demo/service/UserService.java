package com.example.demo.service;

import com.google.cloud.firestore.*;
import com.google.firebase.cloud.FirestoreClient;
import com.example.demo.model.Toon;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.concurrent.ExecutionException;

@Service
public class UserService {

    private static final String COLLECTION_NAME = "users";

    // ✅ 1. CREATE USER (Called when Google Login succeeds)
    public String createUser(String userId, String name) {
        try {
            Firestore db = FirestoreClient.getFirestore();
            DocumentReference userRef = db.collection(COLLECTION_NAME).document(userId);

            // Check if user already exists to avoid overwriting XP
            if (userRef.get().get().exists()) {
                return "User already exists";
            }

            Map<String, Object> user = new HashMap<>();
            user.put("name", name);
            user.put("xp", 100); // 🎁 Sign up bonus!
            user.put("streak", 1);
            user.put("rank", 999);
            user.put("bookmarks", new ArrayList<>());

            userRef.set(user);
            return "User Created";
        } catch (Exception e) {
            e.printStackTrace();
            return "Error";
        }
    }

    // ✅ 2. UPDATE NAME (Called when you click the pencil icon)
    public String updateUserName(String userId, String newName) throws ExecutionException, InterruptedException {
        Firestore db = FirestoreClient.getFirestore();
        db.collection(COLLECTION_NAME).document(userId).update("name", newName);
        return "Name Updated";
    }

    // 3. GET PROFILE (Stats)
    public Map<String, Object> getUserProfile(String userId) throws ExecutionException, InterruptedException {
        Firestore db = FirestoreClient.getFirestore();
        DocumentSnapshot doc = db.collection(COLLECTION_NAME).document(userId).get().get();

        if (!doc.exists()) {
            // Fallback: Create user if missing
            createUser(userId, "Reader");
            return getUserProfile(userId);
        }

        Map<String, Object> userData = doc.getData();
        long xp = (long) userData.getOrDefault("xp", 0L);
        userData.put("rank", getRank(xp)); // Recalculate rank dynamically
        return userData;
    }

    // ... (Keep your existing getGlobalLeaderboard, addXp, and bookmark methods) ...

    // Helper: Calculate Rank
    private int getRank(long myXp) throws ExecutionException, InterruptedException {
        Firestore db = FirestoreClient.getFirestore();
        AggregateQuerySnapshot snapshot = db.collection(COLLECTION_NAME)
                .whereGreaterThan("xp", myXp)
                .count()
                .get().get();
        return (int) snapshot.getCount() + 1;
    }

    // ... Copy your existing addBookmark / removeBookmark / getBookmarks methods here ...
    public String addBookmark(String userId, Toon newsItem) {
        try {
            FirestoreClient.getFirestore().collection(COLLECTION_NAME).document(userId)
                    .collection("bookmarks").document(newsItem.getId()).set(newsItem);
            return "Saved";
        } catch (Exception e) { return "Error"; }
    }

    public String removeBookmark(String userId, String newsId) {
        try {
            FirestoreClient.getFirestore().collection(COLLECTION_NAME).document(userId)
                    .collection("bookmarks").document(newsId).delete();
            return "Removed";
        } catch (Exception e) { return "Error"; }
    }

    public List<Toon> getBookmarks(String userId) throws Exception {
        List<Toon> list = new ArrayList<>();
        List<QueryDocumentSnapshot> docs = FirestoreClient.getFirestore()
                .collection(COLLECTION_NAME).document(userId)
                .collection("bookmarks").get().get().getDocuments();
        for (QueryDocumentSnapshot d : docs) list.add(d.toObject(Toon.class));
        return list;
    }

    public List<Map<String, Object>> getGlobalLeaderboard() throws ExecutionException, InterruptedException {
        Firestore db = FirestoreClient.getFirestore();
        List<QueryDocumentSnapshot> docs = db.collection(COLLECTION_NAME)
                .orderBy("xp", Query.Direction.DESCENDING)
                .limit(10)
                .get().get().getDocuments();

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

    public String addXp(String userId, int points) throws ExecutionException, InterruptedException {
        FirestoreClient.getFirestore().collection(COLLECTION_NAME).document(userId)
                .update("xp", FieldValue.increment(points));
        return "XP Added";
    }
}
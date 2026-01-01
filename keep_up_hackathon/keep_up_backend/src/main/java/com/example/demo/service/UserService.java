package com.example.demo.service;

import com.example.demo.model.User;
import com.example.demo.model.Toon; // Import your Toon/News model
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import com.google.cloud.firestore.Query;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;

@Service
public class UserService {

    private final Firestore firestore;

    public UserService(Firestore firestore) {
        this.firestore = firestore;
    }

    // 1. Create User (When they first open the app)
    public String createUser(String userId, String username) {
        User newUser = new User(userId, username);
        firestore.collection("users").document(userId).set(newUser);
        return "User created: " + username;
    }

    // 2. Add XP (When they win a quiz)
    public String addXp(String userId, int points) throws ExecutionException, InterruptedException {
        var docRef = firestore.collection("users").document(userId);
        User user = docRef.get().get().toObject(User.class);

        if (user != null) {
            int newScore = user.getXp() + points;
            user.setXp(newScore);

            // Promotion Logic
            if (newScore >= 500) user.setLeague("Gold");
            else if (newScore >= 100) user.setLeague("Silver");

            docRef.set(user);
            return "XP Updated! New Score: " + newScore + " (" + user.getLeague() + ")";
        }
        return "User not found!";
    }

    // 3. Get User Info
    public User getUser(String userId) throws ExecutionException, InterruptedException {
        return firestore.collection("users").document(userId).get().get().toObject(User.class);
    }

    // 4. End of Season Promotion Logic
    public String promoteTopPlayers() throws ExecutionException, InterruptedException {
        int promotedToGold = 0;
        int promotedToSilver = 0;

        // PHASE 1: Silver -> Gold
        var silverQuery = firestore.collection("users")
                .whereEqualTo("league", "Silver")
                .orderBy("xp", Query.Direction.DESCENDING)
                .limit(5);

        var silverDocs = silverQuery.get().get().getDocuments();
        for (var doc : silverDocs) {
            User winner = doc.toObject(User.class);
            if (winner != null) {
                winner.setLeague("Gold");
                firestore.collection("users").document(winner.getUserId()).set(winner);
                promotedToGold++;
            }
        }

        // PHASE 2: Bronze -> Silver
        var bronzeQuery = firestore.collection("users")
                .whereEqualTo("league", "Bronze")
                .orderBy("xp", Query.Direction.DESCENDING)
                .limit(10);

        var bronzeDocs = bronzeQuery.get().get().getDocuments();
        for (var doc : bronzeDocs) {
            User winner = doc.toObject(User.class);
            if (winner != null) {
                winner.setLeague("Silver");
                firestore.collection("users").document(winner.getUserId()).set(winner);
                promotedToSilver++;
            }
        }

        return "Season Ended! 🥇 " + promotedToGold + " moved to Gold. 🥈 " + promotedToSilver + " moved to Silver.";
    }

    // 5. Get League Leaderboard
    public List<User> getLeaderboard(String league) throws ExecutionException, InterruptedException {
        var query = firestore.collection("users")
                .whereEqualTo("league", league)
                .orderBy("xp", Query.Direction.DESCENDING)
                .limit(20);

        return query.get().get().toObjects(User.class);
    }

    // 6. Global Leaderboard (For Mobile App)
    public List<Map<String, Object>> getGlobalLeaderboard() throws ExecutionException, InterruptedException {
        List<Map<String, Object>> response = new ArrayList<>();

        var query = firestore.collection("users")
                .orderBy("xp", Query.Direction.DESCENDING)
                .limit(10)
                .get()
                .get();

        for (var doc : query.getDocuments()) {
            User user = doc.toObject(User.class);
            Map<String, Object> map = new HashMap<>();
            map.put("id", user.getUserId());
            map.put("name", user.getUsername());
            map.put("xp", user.getXp());
            response.add(map);
        }
        return response;
    }

    // 7. Init Dummy Data
    public String initDummyData() {
        try {
            createDummy("user_1", "Hacker (You)", 1250, "Gold");
            createDummy("user_2", "Alice", 1400, "Gold");
            createDummy("user_3", "Bob", 800, "Silver");
            createDummy("user_4", "Charlie", 2100, "Gold");
            createDummy("user_5", "Dave", 1100, "Silver");
            return "Leaderboard initialized!";
        } catch (Exception e) {
            return "Error: " + e.getMessage();
        }
    }

    private void createDummy(String id, String name, int xp, String league) {
        User u = new User(id, name);
        u.setXp(xp);
        u.setLeague(league);
        firestore.collection("users").document(id).set(u);
    }

    // 8. Get User Profile with Rank
    public Map<String, Object> getUserProfile(String userId) throws ExecutionException, InterruptedException {
        DocumentSnapshot userDoc = firestore.collection("users").document(userId).get().get();
        if (!userDoc.exists()) return null;

        User user = userDoc.toObject(User.class);

        // Calculate Rank
        var allUsers = getGlobalLeaderboard();
        int rank = 0;
        for (int i = 0; i < allUsers.size(); i++) {
            if (allUsers.get(i).get("id").equals(userId)) {
                rank = i + 1;
                break;
            }
        }

        Map<String, Object> response = new HashMap<>();
        response.put("xp", user.getXp());
        response.put("rank", rank > 0 ? rank : "-");
        response.put("streak", 3);
        response.put("username", user.getUsername());

        return response;
    }

    // ==========================================
    //      NEW BOOKMARK METHODS (Added)
    // ==========================================

    // 9. Add Bookmark
    public String addBookmark(String userId, Toon newsItem) {
        try {
            firestore.collection("users").document(userId)
                    .collection("bookmarks").document(newsItem.getId())
                    .set(newsItem);
            return "Bookmarked!";
        } catch (Exception e) {
            e.printStackTrace();
            return "Error adding bookmark: " + e.getMessage();
        }
    }

    // 10. Remove Bookmark
    public String removeBookmark(String userId, String newsId) {
        try {
            firestore.collection("users").document(userId)
                    .collection("bookmarks").document(newsId)
                    .delete();
            return "Removed!";
        } catch (Exception e) {
            return "Error removing bookmark";
        }
    }

    // 11. Get All Bookmarks
    public List<Toon> getBookmarks(String userId) throws ExecutionException, InterruptedException {
        List<Toon> bookmarks = new ArrayList<>();
        var future = firestore.collection("users").document(userId).collection("bookmarks").get();
        List<QueryDocumentSnapshot> docs = future.get().getDocuments();

        for (QueryDocumentSnapshot doc : docs) {
            bookmarks.add(doc.toObject(Toon.class));
        }
        return bookmarks;
    }
}
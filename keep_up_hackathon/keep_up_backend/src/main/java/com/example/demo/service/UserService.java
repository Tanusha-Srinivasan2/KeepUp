package com.example.demo.service;

import com.example.demo.model.User;
import com.google.cloud.firestore.Firestore;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutionException;
import com.google.cloud.firestore.DocumentSnapshot;  // <--- This fixes your specific error
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.Query;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.ArrayList;
import java.util.Map;
import java.util.HashMap;
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
        // We set the document ID to match the User ID so it's easy to find later
        firestore.collection("users").document(userId).set(newUser);
        return "User created: " + username;
    }

    // 2. Add XP (When they win a quiz)
    public String addXp(String userId, int points) throws ExecutionException, InterruptedException {
        // Find the user
        var docRef = firestore.collection("users").document(userId);
        User user = docRef.get().get().toObject(User.class);

        if (user != null) {
            int newScore = user.getXp() + points;
            user.setXp(newScore);

            // Logic: Promote to Silver at 100 XP, Gold at 500 XP
            if (newScore >= 500) user.setLeague("Gold");
            else if (newScore >= 100) user.setLeague("Silver");

            // Save the updated user back to the database
            docRef.set(user);
            return "XP Updated! New Score: " + newScore + " (" + user.getLeague() + ")";
        }
        return "User not found!";
    }

    // 3. Get User Info (To show on the profile screen)
    public User getUser(String userId) throws ExecutionException, InterruptedException {
        return firestore.collection("users").document(userId).get().get().toObject(User.class);
    }
    // 4. The "End of Season" Promotion Logic
    // 4. The "End of Season" Promotion Logic (Handling ALL Leagues)
    public String promoteTopPlayers() throws ExecutionException, InterruptedException {
        int promotedToGold = 0;
        int promotedToSilver = 0;

        // --- PHASE 1: Promote Silver -> Gold (Run this FIRST) ---
        var silverQuery = firestore.collection("users")
                .whereEqualTo("league", "Silver")
                .orderBy("xp", com.google.cloud.firestore.Query.Direction.DESCENDING)
                .limit(5); // Let's say Top 5 go to Gold

        var silverDocs = silverQuery.get().get().getDocuments();
        for (var doc : silverDocs) {
            User winner = doc.toObject(User.class);
            if (winner != null) {
                winner.setLeague("Gold");
                firestore.collection("users").document(winner.getUserId()).set(winner);
                promotedToGold++;
            }
        }

        // --- PHASE 2: Promote Bronze -> Silver (Run this SECOND) ---
        var bronzeQuery = firestore.collection("users")
                .whereEqualTo("league", "Bronze")
                .orderBy("xp", com.google.cloud.firestore.Query.Direction.DESCENDING)
                .limit(10); // Top 10 go to Silver

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

    // 5. Get Global Leaderboard (Simple Version)
    // Returns the top 20 players in a specific league
    public java.util.List<User> getLeaderboard(String league) throws ExecutionException, InterruptedException {
        var query = firestore.collection("users")
                .whereEqualTo("league", league)
                .orderBy("xp", com.google.cloud.firestore.Query.Direction.DESCENDING)
                .limit(20);

        return query.get().get().toObjects(User.class);
    }
    // --- NEW: ADD THESE METHODS FOR THE FLUTTER APP ---

    // 6. Global Leaderboard (For the Mobile App)
    // We map your "User" object to the exact JSON format the Flutter App expects
    public java.util.List<java.util.Map<String, Object>> getGlobalLeaderboard() throws ExecutionException, InterruptedException {
        java.util.List<java.util.Map<String, Object>> response = new java.util.ArrayList<>();

        // Get top 10 users regardless of league
        var query = firestore.collection("users")
                .orderBy("xp", com.google.cloud.firestore.Query.Direction.DESCENDING)
                .limit(10)
                .get()
                .get();

        for (var doc : query.getDocuments()) {
            User user = doc.toObject(User.class);
            java.util.Map<String, Object> map = new java.util.HashMap<>();
            // MAP JAVA FIELDS -> FLUTTER FIELDS
            map.put("id", user.getUserId());     // Java: userId -> Flutter: id
            map.put("name", user.getUsername()); // Java: username -> Flutter: name
            map.put("xp", user.getXp());
            response.add(map);
        }
        return response;
    }

    // 7. Init Dummy Data (To populate the list instantly)
    public String initDummyData() {
        try {
            // Using your existing createUser/addLogic would be cleaner,
            // but let's write directly to DB for speed.
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
    // 8. Get User Profile with Dynamic Rank & Streak
    public Map<String, Object> getUserProfile(String userId) throws ExecutionException, InterruptedException {
        // A. Get the specific user
        DocumentSnapshot userDoc = firestore.collection("users").document(userId).get().get();
        if (!userDoc.exists()) return null;

        User user = userDoc.toObject(User.class);

        // B. Calculate Rank (Expensive but fine for hackathons)
        // We fetch everyone, sort by XP, and find where this user sits.
        var allUsers = getGlobalLeaderboard();
        int rank = 0;

        for (int i = 0; i < allUsers.size(); i++) {
            if (allUsers.get(i).get("id").equals(userId)) {
                rank = i + 1; // Rank is Index + 1
                break;
            }
        }

        // C. Build Response
        Map<String, Object> response = new HashMap<>();
        response.put("xp", user.getXp());
        response.put("rank", rank > 0 ? rank : "-"); // If not found, show "-"
        response.put("streak", 3); // Hardcoded to 3 for now (Logic requires daily tracking)
        response.put("username", user.getUsername());

        return response;
    }
}
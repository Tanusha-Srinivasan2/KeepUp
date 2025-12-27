package com.example.demo.service;

import com.example.demo.model.User;
import com.google.cloud.firestore.Firestore;
import org.springframework.stereotype.Service;

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
}
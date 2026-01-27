package com.example.demo.service;

import com.example.demo.model.User;
import com.example.demo.repository.ToonRepository;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.*;
import com.google.firebase.cloud.FirestoreClient;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.concurrent.ExecutionException;

@Service
public class UserService {

    private final ToonRepository toonRepository;

    public UserService(ToonRepository toonRepository) {
        this.toonRepository = toonRepository;
    }

    // --- 1. GET USER PROFILE (Calculates Rank on the Fly) ---
    public Map<String, Object> getUserProfile(String userId) throws ExecutionException, InterruptedException {
        Firestore db = FirestoreClient.getFirestore();
        DocumentSnapshot userSnap = db.collection("users").document(userId).get().get();

        if (userSnap.exists()) {
            Map<String, Object> userData = userSnap.getData();
            long currentXp = Long.parseLong(userData.getOrDefault("xp", 0).toString());

            // Calculate Rank: Count users with MORE XP than this user
            AggregateQuerySnapshot snapshot = db.collection("users")
                    .whereGreaterThan("xp", currentXp)
                    .count()
                    .get()
                    .get();

            userData.put("rank", snapshot.getCount() + 1);
            return userData;
        } else {
            return Map.of("error", "User not found");
        }
    }

    // --- 2. CREATE USER (only if doesn't exist) ---
    public String createUser(String userId, String name) {
        try {
            Firestore db = FirestoreClient.getFirestore();
            DocumentSnapshot existingUser = db.collection("users").document(userId).get().get();
            
            if (existingUser.exists()) {
                // User already exists - don't overwrite their data!
                return "User already exists: " + name;
            }
            
            // Only create if user doesn't exist
            User newUser = new User(userId, name);
            db.collection("users").document(userId).set(newUser);
            return "User Created: " + name;
        } catch (Exception e) {
            return "Error: " + e.getMessage();
        }
    }

    // --- 3. ADD XP & UPDATE STREAK ---
    public String addXp(String userId, int points, String category) throws ExecutionException, InterruptedException {
        Firestore db = FirestoreClient.getFirestore();
        DocumentReference userRef = db.collection("users").document(userId);
        DocumentSnapshot userSnap = userRef.get().get();

        if (userSnap.exists()) {
            User user = userSnap.toObject(User.class);
            if (user != null) {
                // --- XP & League Logic ---
                int newXp = user.getXp() + points;
                user.setXp(newXp);
                if (newXp > 1000) user.setLeague("Gold");
                else if (newXp > 500) user.setLeague("Silver");
                else user.setLeague("Bronze");

                // --- Streak Logic ---
                LocalDate today = LocalDate.now();
                if (user.getLastActiveDate() != null) {
                    LocalDate lastActive = LocalDate.parse(user.getLastActiveDate());
                    long daysBetween = ChronoUnit.DAYS.between(lastActive, today);

                    if (daysBetween == 1) {
                        user.setStreak(user.getStreak() + 1); // Incremented streak
                    } else if (daysBetween > 1) {
                        user.setStreak(1); // Reset streak if a day was missed
                    }
                }
                user.setLastActiveDate(today.toString());

                // --- Category Cooldown Logic ---
                if (user.getLastPlayed() == null) user.setLastPlayed(new HashMap<>());
                user.getLastPlayed().put(category, today.toString());

                userRef.set(user);
                return "XP and Streak updated. Current Streak: " + user.getStreak();
            }
        }
        return "User not found.";
    }

    // --- 3.5 RESTORE STREAK (Ad Recovery) ---
    public String restoreStreak(String userId) throws ExecutionException, InterruptedException {
        Firestore db = FirestoreClient.getFirestore();
        DocumentReference userRef = db.collection("users").document(userId);
        DocumentSnapshot userSnap = userRef.get().get();

        if (userSnap.exists()) {
            User user = userSnap.toObject(User.class);
            if (user != null) {
                LocalDate today = LocalDate.now();
                LocalDate yesterday = today.minusDays(1);
                
                // Check if streak was actually broken (lastActiveDate is before yesterday)
                if (user.getLastActiveDate() != null) {
                    LocalDate lastActive = LocalDate.parse(user.getLastActiveDate());
                    long daysMissed = ChronoUnit.DAYS.between(lastActive, today);
                    
                    // Only restore if they missed 1-2 days (reasonable grace period)
                    if (daysMissed >= 2 && daysMissed <= 3) {
                        // Restore the streak by setting lastActiveDate to yesterday
                        // This way, when they play today, their streak will increment normally
                        user.setLastActiveDate(yesterday.toString());
                        // Keep their current streak value (don't reset it)
                        userRef.set(user);
                        return "Streak restored! Current streak: " + user.getStreak() + ". Play now to continue!";
                    } else if (daysMissed > 3) {
                        // Too many days missed, but still give them a streak of 1
                        user.setStreak(1);
                        user.setLastActiveDate(yesterday.toString());
                        userRef.set(user);
                        return "Streak reset to 1. Play now to start building again!";
                    } else {
                        return "Streak is not broken! Current streak: " + user.getStreak();
                    }
                } else {
                    // No lastActiveDate, set to yesterday
                    user.setLastActiveDate(yesterday.toString());
                    user.setStreak(1);
                    userRef.set(user);
                    return "Streak initialized! Play now to start your streak.";
                }
            }
        }
        return "User not found.";
    }

    // --- 4. UNLOCK QUIZ (For Ad Reward Retry) ---
    public String unlockQuiz(String userId, String category) throws ExecutionException, InterruptedException {
        Firestore db = FirestoreClient.getFirestore();
        DocumentReference userRef = db.collection("users").document(userId);
        DocumentSnapshot userSnap = userRef.get().get();

        if (userSnap.exists()) {
            User user = userSnap.toObject(User.class);
            if (user != null && user.getLastPlayed() != null) {
                // To allow a retry, we remove the category from the "lastPlayed" map
                user.getLastPlayed().remove(category);
                userRef.set(user);
                return "Category " + category + " unlocked for a bonus try!";
            }
        }
        return "User not found.";
    }

    // --- 5. GLOBAL LEADERBOARD ---
    public List<Map<String, Object>> getGlobalLeaderboard() throws ExecutionException, InterruptedException {
        Firestore db = FirestoreClient.getFirestore();
        Query query = db.collection("users").orderBy("xp", Query.Direction.DESCENDING).limit(20);

        List<Map<String, Object>> leaderboard = new ArrayList<>();
        for (DocumentSnapshot document : query.get().get().getDocuments()) {
            Map<String, Object> entry = new HashMap<>();
            entry.put("name", document.getString("name"));
            entry.put("xp", document.get("xp"));
            entry.put("league", document.getString("league"));
            leaderboard.add(entry);
        }
        return leaderboard;
    }

    // --- 6. BOOKMARK METHODS (Map-based) ---
    public String addBookmark(String userId, Map<String, Object> newsItem) throws ExecutionException, InterruptedException {
        Firestore db = FirestoreClient.getFirestore();
        DocumentReference userRef = db.collection("users").document(userId);
        DocumentSnapshot userSnap = userRef.get().get();

        if (userSnap.exists()) {
            User user = userSnap.toObject(User.class);
            if (user != null) {
                List<Map<String, Object>> bookmarks = user.getBookmarks();
                String newId = (String) newsItem.get("id");
                boolean exists = bookmarks.stream().anyMatch(b -> b.get("id") != null && b.get("id").equals(newId));

                if (!exists) {
                    bookmarks.add(newsItem);
                    userRef.set(user);
                    return "Bookmark Added!";
                }
                return "Already bookmarked.";
            }
        }
        return "User not found.";
    }

    public List<Map<String, Object>> getBookmarks(String userId) throws ExecutionException, InterruptedException {
        Firestore db = FirestoreClient.getFirestore();
        DocumentSnapshot userSnap = db.collection("users").document(userId).get().get();
        if (userSnap.exists()) {
            User user = userSnap.toObject(User.class);
            if (user != null) return user.getBookmarks();
        }
        return Collections.emptyList();
    }

    public String removeBookmark(String userId, String newsId) throws ExecutionException, InterruptedException {
        Firestore db = FirestoreClient.getFirestore();
        DocumentReference userRef = db.collection("users").document(userId);
        DocumentSnapshot userSnap = userRef.get().get();

        if (userSnap.exists()) {
            User user = userSnap.toObject(User.class);
            if (user != null) {
                boolean removed = user.getBookmarks().removeIf(b -> b.get("id") != null && b.get("id").equals(newsId));
                if (removed) {
                    userRef.set(user);
                    return "Bookmark Removed.";
                }
            }
        }
        return "User not found or bookmark doesn't exist.";
    }

    // --- ✅ POLICY COMPLIANCE: DELETE USER ACCOUNT ---
    // Permanently removes all user data from Firestore for GDPR/Google Play compliance
    public String deleteUser(String userId) throws ExecutionException, InterruptedException {
        Firestore db = FirestoreClient.getFirestore();
        DocumentReference userRef = db.collection("users").document(userId);
        DocumentSnapshot userSnap = userRef.get().get();

        if (userSnap.exists()) {
            // Delete the user document
            userRef.delete().get();
            return "User account and all data deleted successfully.";
        }
        return "User not found.";
    }

    // --- ✅ WEB DELETION REQUEST (Email-based) ---
    // For users who want to delete without the app
    public String requestDeletionByEmail(String email) throws ExecutionException, InterruptedException {
        Firestore db = FirestoreClient.getFirestore();
        
        // Search for user by email (userId is the email in this app)
        DocumentSnapshot userSnap = db.collection("users").document(email).get().get();
        
        if (userSnap.exists()) {
            // Delete the user
            db.collection("users").document(email).delete().get();
            return "Account deleted successfully. All your data has been removed.";
        }
        return "No account found with this email address.";
    }
}
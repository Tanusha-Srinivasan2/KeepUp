package com.example.demo.controller;



import com.example.demo.service.UserService;

import org.springframework.web.bind.annotation.*;



import java.util.Collections;

import java.util.List;

import java.util.Map;



@RestController

@RequestMapping("/api/news/user")

@CrossOrigin(origins = "*")

public class UserController {



    private final UserService userService;



    public UserController(UserService userService) {

        this.userService = userService;

    }



// --- EXISTING ENDPOINTS ---



    @GetMapping("/{userId}")

    public Map<String, Object> getUserProfile(@PathVariable String userId) {

        try {

            return userService.getUserProfile(userId);

        } catch (Exception e) {

            e.printStackTrace();

            return Map.of("error", e.getMessage());

        }

    }



    @PostMapping("/create")

    public String createUser(@RequestParam String userId, @RequestParam String name) {

        return userService.createUser(userId, name);

    }



    @PostMapping("/{userId}/xp")

    public String addXp(@PathVariable String userId, @RequestParam int points, @RequestParam String category) {

        try {

            return userService.addXp(userId, points, category);

        } catch (Exception e) {

            return "Error updating XP: " + e.getMessage();

        }

    }



    @GetMapping("/leaderboard")

    public List<Map<String, Object>> getLeaderboard() {

        try {

            return userService.getGlobalLeaderboard();

        } catch (Exception e) {

            e.printStackTrace();

            return Collections.emptyList();

        }

    }



// --- ✅ NEW BOOKMARK ENDPOINTS ---



    @PostMapping("/{userId}/bookmark")

    public String addBookmark(@PathVariable String userId, @RequestBody Map<String, Object> newsItem) {

        try {

            return userService.addBookmark(userId, newsItem);

        } catch (Exception e) {

            return "Error saving bookmark: " + e.getMessage();

        }

    }



    @GetMapping("/{userId}/bookmarks")

    public List<Map<String, Object>> getBookmarks(@PathVariable String userId) {

        try {

            return userService.getBookmarks(userId);

        } catch (Exception e) {

            e.printStackTrace();

            return Collections.emptyList();

        }

    }



    @DeleteMapping("/{userId}/bookmark/{newsId}")

    public String removeBookmark(@PathVariable String userId, @PathVariable String newsId) {

        try {

            return userService.removeBookmark(userId, newsId);

        } catch (Exception e) {

            return "Error removing bookmark: " + e.getMessage();

        }

    }

    @PostMapping("/{userId}/unlock-quiz")

    public String unlockQuiz(@PathVariable String userId, @RequestParam String category) {

        try {

            return userService.unlockQuiz(userId, category);

        } catch (Exception e) {

            return "Error unlocking: " + e.getMessage();

        }

    }

}
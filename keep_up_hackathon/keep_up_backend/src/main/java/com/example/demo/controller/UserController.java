package com.example.demo.controller;

import com.example.demo.model.User;
import com.example.demo.service.UserService;
import org.springframework.web.bind.annotation.*;

import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    // TEST URL: http://localhost:8080/api/users/create?id=user_001&name=Tanusha
    @GetMapping("/create")
    public String createUser(@RequestParam String id, @RequestParam String name) {
        return userService.createUser(id, name);
    }

    // TEST URL: http://localhost:8080/api/users/add-xp?id=user_001&points=50
    @GetMapping("/add-xp")
    public String addXp(@RequestParam String id, @RequestParam int points) throws ExecutionException, InterruptedException {
        return userService.addXp(id, points);
    }

    // TEST URL: http://localhost:8080/api/users/get?id=user_001
    @GetMapping("/get")
    public User getUser(@RequestParam String id) throws ExecutionException, InterruptedException {
        return userService.getUser(id);
    }
    // TRIGGER URL: http://localhost:8080/api/users/promote-season
    @GetMapping("/promote-season")
    public String triggerSeasonEnd() throws ExecutionException, InterruptedException {
        return userService.promoteTopPlayers();
    }

    // URL: http://localhost:8080/api/users/leaderboard?league=Bronze
    @GetMapping("/leaderboard")
    public java.util.List<User> getLeaderboard(@RequestParam String league) throws ExecutionException, InterruptedException {
        return userService.getLeaderboard(league);
    }
}
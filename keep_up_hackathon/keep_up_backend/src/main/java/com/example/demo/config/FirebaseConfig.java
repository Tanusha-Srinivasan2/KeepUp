package com.example.demo.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import org.springframework.context.annotation.Configuration;

import javax.annotation.PostConstruct;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;

@Configuration
public class FirebaseConfig {

    @PostConstruct
    public void initialize() {
        try {
            if (!FirebaseApp.getApps().isEmpty()) {
                System.out.println("🔥 Firebase is already initialized!");
                return;
            }

            // 1. Debug the File Path
            String filePath = "secrets/service-account.json"; // Make sure this matches your folder
            File file = new File(filePath);

            System.out.println("🔍 Looking for key at: " + file.getAbsolutePath());

            if (!file.exists()) {
                throw new RuntimeException("❌ FATAL: Could not find service-account.json at " + file.getAbsolutePath());
            }

            // 2. Initialize
            FileInputStream serviceAccount = new FileInputStream(file);
            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                    .build();

            FirebaseApp.initializeApp(options);
            System.out.println("🔥 Firebase Initialized Successfully!");

        } catch (IOException e) {
            throw new RuntimeException("❌ FATAL: Failed to read Firebase key", e);
        }
    }
}
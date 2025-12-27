package com.example.demo.service;

import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.SetOptions;
import com.example.demo.model.NewsSummary;
import com.example.demo.model.ToonSegment;
import org.springframework.stereotype.Service;

import java.util.concurrent.ExecutionException;

@Service
public class FirestoreService {

    private final Firestore firestore;

    // Spring Boot automatically connects to Google Cloud and injects this
    public FirestoreService(Firestore firestore) {
        this.firestore = firestore;
    }

    // JOB 1: Save the specific line (For Vector Search/Context)
    // Called by NewsIndexingService
    public void saveToonSegment(ToonSegment segment) {
        try {
            // "toon_index" is the collection where the 'Brain' looks for answers
            firestore.collection("toon_index")
                    .document(segment.getId())
                    .set(segment, SetOptions.merge());

        } catch (Exception e) {
            System.err.println("Failed to save segment: " + segment.getId());
            e.printStackTrace();
        }
    }

    // JOB 2: Save the Daily Edition (For the Phone Screen)
    // You can call this from NewsController if you want to create a daily summary
    public void saveDailySummary(NewsSummary summary) {
        try {
            // "daily_news" is the collection the App loads when it opens
            firestore.collection("daily_news")
                    .document(summary.getId())
                    .set(summary, SetOptions.merge())
                    .get(); // .get() forces it to wait until finished

            System.out.println("Saved Daily Summary: " + summary.getId());

        } catch (InterruptedException | ExecutionException e) {
            System.err.println("Error saving daily summary");
            e.printStackTrace();
        }
    }
}

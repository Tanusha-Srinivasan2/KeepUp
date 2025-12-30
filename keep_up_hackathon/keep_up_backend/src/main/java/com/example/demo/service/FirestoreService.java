package com.example.demo.service;

import com.example.demo.model.Toon;
import com.google.cloud.firestore.Firestore;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.concurrent.ExecutionException;

@Service
public class FirestoreService {

    private final Firestore db;

    public FirestoreService(Firestore db) {
        this.db = db;
    }

    // METHOD 1: Save a single news segment (Fixes your error!)
    public void saveToonSegment(Toon segment) {
        try {
            // NOTE: Using "toon_index" to match your database screenshot
            db.collection("toon_index")
                    .document(segment.getId())
                    .set(segment);
            System.out.println("Saved segment: " + segment.getId());
        } catch (Exception e) {
            System.err.println("Error saving to Firestore: " + e.getMessage());
        }
    }

    // METHOD 2: Get all segments (For the Chatbot)
    public List<Toon> getAllToonSegments() {
        try {
            var query = db.collection("toon_index").get();
            return query.get().toObjects(Toon.class);
        } catch (Exception e) {
            e.printStackTrace();
            return List.of();
        }
    }
}
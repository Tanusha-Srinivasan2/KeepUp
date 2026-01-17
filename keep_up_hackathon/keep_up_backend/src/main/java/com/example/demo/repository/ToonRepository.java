package com.example.demo.repository;

import com.example.demo.model.Toon;
import com.google.cloud.spring.data.firestore.FirestoreReactiveRepository;
import org.springframework.stereotype.Repository;
import reactor.core.publisher.Flux;

@Repository
public interface ToonRepository extends FirestoreReactiveRepository<Toon> {

    // Finds all news articles for a specific date (e.g., "2025-01-17")
    Flux<Toon> findByPublishedDate(String publishedDate);
}
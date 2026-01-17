package com.example.demo.repository;

import com.example.demo.model.CategoryQuiz;
import com.google.cloud.spring.data.firestore.FirestoreReactiveRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface CategoryQuizRepository extends FirestoreReactiveRepository<CategoryQuiz> {
    // No custom methods needed, we find by ID
}
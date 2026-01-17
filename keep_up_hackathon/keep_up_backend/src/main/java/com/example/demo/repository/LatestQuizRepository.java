package com.example.demo.repository;

import com.example.demo.model.LatestQuiz;
import com.google.cloud.spring.data.firestore.FirestoreReactiveRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface LatestQuizRepository extends FirestoreReactiveRepository<LatestQuiz> {
}
package com.example.demo.repository;

import com.example.demo.model.Report;
import com.google.cloud.spring.data.firestore.FirestoreReactiveRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ReportRepository extends FirestoreReactiveRepository<Report> {
    // No extra code needed; standard CRUD operations (save, findById, etc.) are inherited automatically.
}
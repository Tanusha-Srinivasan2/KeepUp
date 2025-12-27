package com.example.demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class KeepUpApplication {

	public static void main(String[] args) {
		// --- THE ULTIMATE OVERRIDE ---
		// We force these settings into memory before Spring Boot starts.
		// This makes them visible to Chat, Embeddings, and everything else.
		System.setProperty("spring.ai.vertex.ai.project-id", "keep-up-hackathon");
		System.setProperty("spring.ai.vertex.ai.location", "us-central1");

		// (Optional) If it complains about credentials later, we can set this too:
		// System.setProperty("spring.cloud.gcp.credentials.location", "file:secrets/service-account.json");

		SpringApplication.run(KeepUpApplication.class, args);
	}
}
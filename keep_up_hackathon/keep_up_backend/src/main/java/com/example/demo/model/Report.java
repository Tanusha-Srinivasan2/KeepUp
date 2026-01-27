package com.example.demo.model;

import com.google.cloud.firestore.annotation.DocumentId;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class Report {
    @DocumentId
    private String id;
    private String userId;        // Who reported it
    private String contentId;     // ID of the News Card (or "chat_msg" for chat)
    private String reportedText;  // The actual text they flagged
    private String reason;        // "Inappropriate", "Not true", etc.
    private long timestamp;
}
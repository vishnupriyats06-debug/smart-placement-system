package com.placement;

import java.sql.Timestamp;

public class QuizAttempt {
    private int id;
    private int userId;
    private String section;
    private int totalQuestions;
    private int attemptedCount;
    private int correctCount;
    private int incorrectCount;
    private int score;
    private double accuracy;
    private int totalTimeSeconds;
    private double avgResponseTime;
    private boolean isSubmitted;
    private Timestamp startedAt;
    private Timestamp submittedAt;

    public QuizAttempt() {}

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public int getUserId() { return userId; }
    public void setUserId(int userId) { this.userId = userId; }

    public String getSection() { return section; }
    public void setSection(String section) { this.section = section; }

    public int getTotalQuestions() { return totalQuestions; }
    public void setTotalQuestions(int totalQuestions) { this.totalQuestions = totalQuestions; }

    public int getAttemptedCount() { return attemptedCount; }
    public void setAttemptedCount(int attemptedCount) { this.attemptedCount = attemptedCount; }

    public int getCorrectCount() { return correctCount; }
    public void setCorrectCount(int correctCount) { this.correctCount = correctCount; }

    public int getIncorrectCount() { return incorrectCount; }
    public void setIncorrectCount(int incorrectCount) { this.incorrectCount = incorrectCount; }

    public int getScore() { return score; }
    public void setScore(int score) { this.score = score; }

    public double getAccuracy() { return accuracy; }
    public void setAccuracy(double accuracy) { this.accuracy = accuracy; }

    public int getTotalTimeSeconds() { return totalTimeSeconds; }
    public void setTotalTimeSeconds(int totalTimeSeconds) { this.totalTimeSeconds = totalTimeSeconds; }

    public double getAvgResponseTime() { return avgResponseTime; }
    public void setAvgResponseTime(double avgResponseTime) { this.avgResponseTime = avgResponseTime; }

    public boolean isSubmitted() { return isSubmitted; }
    public void setSubmitted(boolean submitted) { isSubmitted = submitted; }

    public Timestamp getStartedAt() { return startedAt; }
    public void setStartedAt(Timestamp startedAt) { this.startedAt = startedAt; }

    public Timestamp getSubmittedAt() { return submittedAt; }
    public void setSubmittedAt(Timestamp submittedAt) { this.submittedAt = submittedAt; }
}

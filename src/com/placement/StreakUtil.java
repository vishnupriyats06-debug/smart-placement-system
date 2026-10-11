package com.placement;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;

public class StreakUtil {

    public static class StreakData {
        public int currentStreak;
        public int longestStreak;
        public LocalDate lastPracticeDate;

        public StreakData(int currentStreak, int longestStreak, LocalDate lastPracticeDate) {
            this.currentStreak = currentStreak;
            this.longestStreak = longestStreak;
            this.lastPracticeDate = lastPracticeDate;
        }
    }

    public static StreakData getStreak(int userId) {
        String sql = "SELECT current_streak, longest_streak, last_practice_date FROM user_streaks WHERE user_id = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Date lastDate = rs.getDate("last_practice_date");
                    LocalDate ld = (lastDate != null) ? lastDate.toLocalDate() : null;
                    return new StreakData(rs.getInt("current_streak"), rs.getInt("longest_streak"), ld);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return new StreakData(0, 0, null);
    }

    public static StreakData updateStreakOnQuizCompletion(int userId) {
        LocalDate today = LocalDate.now();
        StreakData current = getStreak(userId);

        int newCurrentStreak = current.currentStreak;
        int newLongestStreak = current.longestStreak;

        if (current.lastPracticeDate == null) {
            // First time practicing
            newCurrentStreak = 1;
        } else if (current.lastPracticeDate.equals(today)) {
            // Practicing again on the same day: streak does not increment again
            newCurrentStreak = Math.max(1, current.currentStreak);
        } else if (current.lastPracticeDate.plusDays(1).equals(today)) {
            // Practiced yesterday: streak increases
            newCurrentStreak = current.currentStreak + 1;
        } else {
            // Skipped a day or more: streak resets to 1
            newCurrentStreak = 1;
        }

        newLongestStreak = Math.max(newLongestStreak, newCurrentStreak);

        String upsertSql = "INSERT INTO user_streaks (user_id, current_streak, longest_streak, last_practice_date) " +
                           "VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE " +
                           "current_streak = VALUES(current_streak), " +
                           "longest_streak = VALUES(longest_streak), " +
                           "last_practice_date = VALUES(last_practice_date)";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(upsertSql)) {
            ps.setInt(1, userId);
            ps.setInt(2, newCurrentStreak);
            ps.setInt(3, newLongestStreak);
            ps.setDate(4, Date.valueOf(today));
            ps.executeUpdate();
        } catch (SQLException e) {
            e.printStackTrace();
        }

        return new StreakData(newCurrentStreak, newLongestStreak, today);
    }
}

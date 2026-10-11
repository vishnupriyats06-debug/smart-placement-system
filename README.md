# Smart Placement System

A complete, production-ready web application designed to help students prepare for campus placement aptitude exams through interactive practice, fair question rotation, performance tracking, daily streaks, and avatar customization.

---

## 1. Technology Stack

- **Frontend:** HTML5, CSS3 (Vanilla Glassmorphic Design System), JavaScript (ES6+)
- **Backend:** JSP (JavaServer Pages) with JavaBeans and Utility Classes
- **Database:** MySQL (Relational schema with JDBC Prepared Statements)
- **Application Server:** Apache Tomcat 8.x / 9.x / 10.x (XAMPP Tomcat ready)

---

## 2. Directory Structure

```
SmartPlacementSystem/
├── sql/
│   └── database_setup.sql          # Complete MySQL schema + 300+ verified MCQs
├── src/com/placement/              # Java Backend Sources
│   ├── DBUtil.java                 # JDBC connection manager & auto DB bootstrapper
│   ├── PasswordUtil.java           # SHA-256 salted password hashing
│   ├── StreakUtil.java             # Calendar-based daily streak calculation
│   ├── Question.java               # Question model bean
│   ├── QuizAttempt.java            # Quiz attempt model bean
│   └── User.java                   # User entity bean
├── WebContent/                     # Web Application Root
│   ├── index.jsp                   # Smart routing based on session state
│   ├── login.jsp                   # Student sign-in page
│   ├── register.jsp                # Student registration page
│   ├── forgot-password.jsp         # Secure password reset page
│   ├── dashboard.jsp               # Main student dashboard & live analytics
│   ├── quiz.jsp                    # 15-question active quiz test with state preservation
│   ├── quiz-result.jsp             # Assessment score, accuracy, and solution review
│   ├── progress.jsp                # Comprehensive progress tracking & domain mastery
│   ├── profile.jsp                 # Student profile & 20-avatar selector
│   ├── logout.jsp                  # Secure session termination
│   ├── actions/                    # Backend JSP Action Handlers
│   │   ├── auth-login.jsp          # Credentials verification & session creation
│   │   ├── auth-register.jsp       # User insertion with hashed password
│   │   ├── auth-forgot.jsp         # Password reset update processor
│   │   ├── quiz-start.jsp          # 15-question rotation & attempt initialisation
│   │   ├── quiz-submit.jsp         # Server-side evaluation & score calculation
│   │   └── update-avatar.jsp       # Avatar persistence in MySQL
│   ├── css/
│   │   ├── style.css               # Main theme, responsive tokens, glassmorphism
│   │   └── quiz.css                # Quiz palette, timer, and result cards
│   ├── js/
│   │   ├── main.js                 # Alerts, toasts, and UI interactions
│   │   ├── quiz.js                 # Countdown timer, palette navigator, anti-reset
│   │   └── progress.js             # Visual progress bar & chart animations
│   ├── images/avatars/             # 20 Distinct Predefined Avatars
│   │   ├── female/                 # avatar01.svg .. avatar10.svg (10 female avatars)
│   │   └── male/                   # avatar11.svg .. avatar20.svg (10 male avatars)
│   └── WEB-INF/
│       ├── web.xml                 # Web descriptor & session timeout
│       ├── lib/
│       │   └── mysql-connector-j-9.7.0.jar # MySQL JDBC Driver
│       └── classes/com/placement/  # Compiled Java bytecode
└── SmartPlacementSystem.war        # Pre-packaged production deployable WAR
```

---

## 3. Database Setup (MySQL via XAMPP)

1. Open **XAMPP Control Panel** and start **MySQL**.
2. Open your browser and navigate to **phpMyAdmin** at `http://localhost/phpmyadmin/` (or use MySQL CLI).
3. Click on the **Import** tab.
4. Choose the file:
   ```
   SmartPlacementSystem/sql/database_setup.sql
   ```
5. Click **Go** (or **Import**).
   - This creates the database `smart_placement_db`.
   - Sets up all 6 relational tables (`users`, `questions`, `quiz_attempts`, `quiz_responses`, `user_question_history`, `user_streaks`).
   - Populates all **300 verified multiple-choice questions** (100 Quantitative Aptitude, 100 Logical Reasoning, 100 Verbal Ability).

*Default MySQL connection credentials used in `DBUtil.java`:*
- Host: `localhost:3306`
- User: `root`
- Password: `""` (empty, standard for XAMPP)
- Database: `smart_placement_db`

---

## 4. How to Run Locally

### Option A: Via XAMPP Tomcat
1. Copy either `SmartPlacementSystem.war` or the `WebContent` folder to your Tomcat `webapps` folder:
   ```
   C:\xampp\tomcat\webapps\SmartPlacementSystem
   ```
2. In **XAMPP Control Panel**, start **Tomcat** (or run `C:\xampp\tomcat\bin\startup.bat`).
3. Open your browser and visit:
   ```
   http://localhost:8080/SmartPlacementSystem/
   ```

### Option B: Via Eclipse / IntelliJ IDEA
1. Open Eclipse IDE / IntelliJ IDEA.
2. Select **File -> Import -> Existing Projects into Workspace** (or Open Web Project).
3. Add Apache Tomcat Server to your IDE Server Runtime.
4. Right-click the project -> **Run As -> Run on Server**.
5. The application will launch at `http://localhost:8080/SmartPlacementSystem/`.

---

## 5. Application Features & Architecture

### 1. User Authentication & Security
- **Registration (`register.jsp`):** Validates username and email uniqueness in MySQL. Passwords are encrypted using SHA-256 with cryptographic salt before being saved in MySQL.
- **Login (`login.jsp`):** Authenticates stored hash, creates user session (`userId`, `username`, `email`, `avatar`), and guards protected pages from unauthorized access.
- **Forgot Password (`forgot-password.jsp`):** Verifies username existence in the database, confirms matching passwords, hashes the new password, and updates the database record.
- **Logout (`logout.jsp`):** Invalidates session and sets `Cache-Control: no-cache, no-store, must-revalidate` headers to prevent browser back-button caching.

### 2. Live Dashboard (`dashboard.jsp`)
- Displays statistics calculated directly from MySQL:
  - Total Questions Attempted
  - Overall Accuracy % (`(Total Correct / Total Attempted) * 100`)
  - Average Response Time per question
  - Longest Practice Streak & Current Streak
  - Section-wise Attempt Cards
  - Recent Practice Activity Log

### 3. Question Bank & Fair Rotation Engine
- **300+ Verified Questions in MySQL:**
  - **Quantitative Aptitude (100):** Percentages, Profit & Loss, Ratios, Averages, Time & Work, Speed & Distance, SI & CI, Number Systems, Probability, Permutations & Combinations.
  - **Logical Reasoning (100):** Series, Coding-Decoding, Blood Relations, Direction Sense, Analogies, Syllogisms, Seating Arrangements, Puzzles, Classification, Logical Sequences.
  - **Verbal Ability (100):** Synonyms/Antonyms, Grammar, Sentence Correction, Fill in Blanks, Reading Comprehension, Error Detection, Vocabulary, Sentence Completion, Para Jumbles, Idioms.
- **15-Question Quiz Attempts:** Exactly 15 questions per attempt.
- **Fair Rotation (`quiz-start.jsp`):** Consults `user_question_history` to serve unseen questions first. Once all 100 questions in a section have been taken, the history resets to allow a fresh cycle.

### 4. Page Refresh & State Preservation (`quiz.jsp`)
- Storing the active attempt ID in the session and MySQL ensures that if a student refreshes or reloads the quiz page:
  - The exact same 15 questions and order are preserved.
  - Selected options are restored from storage.
  - The elapsed timer does not reset.
  - Duplicate quiz attempts are strictly prevented.

### 5. Server-Side Answer Evaluation (`quiz-submit.jsp`)
- Answer keys are stored in MySQL and evaluated on the server (never exposed to client-side JavaScript DOM).
- Scores out of 15, accuracy percentages, response times, and per-question correctness are calculated and committed in an atomic database transaction.

### 6. Daily Streak Engine (`StreakUtil.java`)
- Tracks consecutive days of practice based on calendar dates (`LocalDate`):
  - Same day practice: Maintains current streak without duplicate increment.
  - Next consecutive day: Increments streak by 1 and updates longest streak.
  - Missed day: Resets current streak to 1 on the next practice attempt.
  - Persisted in MySQL `user_streaks` table.

### 7. 20 Predefined Avatars (`profile.jsp`)
- 10 Female Avatars (`avatar01.svg` to `avatar10.svg`)
- 10 Male Avatars (`avatar11.svg` to `avatar20.svg`)
- Selecting an avatar persists the choice in MySQL `users` table and immediately updates the dashboard and profile headers.

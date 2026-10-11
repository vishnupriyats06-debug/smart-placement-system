// Quiz Engine - State Preservation, Live Timer, Question Palette & Anti-Reset System

let currentQuestionIndex = 0;
let totalQuestions = 15;
let attemptId = null;
let quizTimerInterval = null;
let remainingSeconds = 900; // 15 minutes default
let questionStartTime = Date.now();
let questionTimeSpent = {}; // qIndex -> seconds

function initQuiz(data) {
    totalQuestions = data.questions.length;
    attemptId = data.attemptId;
    
    // Calculate remaining seconds based on server attempt start time
    const serverStartMs = data.serverStartTime; // epoch ms
    const durationSeconds = data.durationSeconds || 900; // 15 minutes total
    const nowMs = Date.now();
    const elapsedSeconds = Math.max(0, Math.floor((nowMs - serverStartMs) / 1000));
    
    remainingSeconds = Math.max(5, durationSeconds - elapsedSeconds);

    // Load any previously selected answers saved in browser storage for this attempt
    loadSavedAnswers();

    // Start countdown timer
    startTimer();

    // Render initial question
    renderQuestion(0);
    updatePalette();
    updateProgressBar();
}

function startTimer() {
    updateTimerDisplay();
    quizTimerInterval = setInterval(() => {
        remainingSeconds--;
        updateTimerDisplay();

        if (remainingSeconds <= 0) {
            clearInterval(quizTimerInterval);
            showToast("Time is up! Submitting your quiz now...", "warning");
            submitQuiz(true);
        }
    }, 1000);
}

function updateTimerDisplay() {
    const timerEl = document.getElementById('quizTimerDisplay');
    const timerBox = document.getElementById('quizTimerBox');
    if (!timerEl) return;

    const mins = Math.floor(remainingSeconds / 60);
    const secs = remainingSeconds % 60;
    const formatted = `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
    timerEl.textContent = formatted;

    if (timerBox) {
        if (remainingSeconds < 60) {
            timerBox.className = 'quiz-timer-box danger';
        } else if (remainingSeconds < 180) {
            timerBox.className = 'quiz-timer-box warning';
        } else {
            timerBox.className = 'quiz-timer-box';
        }
    }
}

function recordCurrentTimeSpent() {
    const elapsed = Math.round((Date.now() - questionStartTime) / 1000);
    questionTimeSpent[currentQuestionIndex] = (questionTimeSpent[currentQuestionIndex] || 0) + elapsed;
    questionStartTime = Date.now();
}

function renderQuestion(index) {
    recordCurrentTimeSpent();
    currentQuestionIndex = index;

    const cards = document.querySelectorAll('.question-item-card');
    cards.forEach((c, i) => {
        c.style.display = (i === index) ? 'flex' : 'none';
    });

    document.getElementById('currentQuestionLabel').textContent = index + 1;

    // Controls visibility
    const prevBtn = document.getElementById('prevQuestionBtn');
    const nextBtn = document.getElementById('nextQuestionBtn');
    
    if (prevBtn) prevBtn.disabled = (index === 0);
    if (nextBtn) {
        if (index === totalQuestions - 1) {
            nextBtn.textContent = 'Review All';
        } else {
            nextBtn.innerHTML = 'Next Question &rarr;';
        }
    }

    updatePalette();
}

function selectOption(qIndex, optionLetter) {
    const hiddenInput = document.getElementById(`selected_answer_${qIndex}`);
    if (hiddenInput) {
        hiddenInput.value = optionLetter;
    }

    // Update UI highlights
    const container = document.getElementById(`options_group_${qIndex}`);
    if (container) {
        const optionEls = container.querySelectorAll('.option-item');
        optionEls.forEach(el => {
            if (el.getAttribute('data-option') === optionLetter) {
                el.classList.add('selected');
            } else {
                el.classList.remove('selected');
            }
        });
    }

    // Save in sessionStorage so page reload preserves selection immediately
    saveAnswersToStorage();
    updatePalette();
    updateProgressBar();
}

function clearCurrentSelection() {
    const hiddenInput = document.getElementById(`selected_answer_${currentQuestionIndex}`);
    if (hiddenInput) {
        hiddenInput.value = '';
    }
    const container = document.getElementById(`options_group_${currentQuestionIndex}`);
    if (container) {
        const optionEls = container.querySelectorAll('.option-item');
        optionEls.forEach(el => el.classList.remove('selected'));
    }
    saveAnswersToStorage();
    updatePalette();
    updateProgressBar();
}

function prevQuestion() {
    if (currentQuestionIndex > 0) {
        renderQuestion(currentQuestionIndex - 1);
    }
}

function nextQuestion() {
    if (currentQuestionIndex < totalQuestions - 1) {
        renderQuestion(currentQuestionIndex + 1);
    } else {
        openSubmitModal();
    }
}

function jumpToQuestion(index) {
    if (index >= 0 && index < totalQuestions) {
        renderQuestion(index);
    }
}

function updatePalette() {
    const paletteBtns = document.querySelectorAll('.palette-btn');
    paletteBtns.forEach((btn, i) => {
        btn.classList.remove('current', 'answered', 'unanswered');

        const answerInput = document.getElementById(`selected_answer_${i}`);
        const hasAnswer = answerInput && answerInput.value.trim() !== '';

        if (i === currentQuestionIndex) {
            btn.classList.add('current');
        }

        if (hasAnswer) {
            btn.classList.add('answered');
        } else if (i < currentQuestionIndex || btn.dataset.visited === 'true') {
            btn.classList.add('unanswered');
            btn.dataset.visited = 'true';
        }
    });
}

function updateProgressBar() {
    let answeredCount = 0;
    for (let i = 0; i < totalQuestions; i++) {
        const ans = document.getElementById(`selected_answer_${i}`);
        if (ans && ans.value.trim() !== '') {
            answeredCount++;
        }
    }
    const pct = Math.round((answeredCount / totalQuestions) * 100);
    const fillEl = document.getElementById('quizProgressFill');
    const labelEl = document.getElementById('quizProgressLabel');
    if (fillEl) fillEl.style.width = `${pct}%`;
    if (labelEl) labelEl.textContent = `${answeredCount} of ${totalQuestions} Answered (${pct}%)`;
}

function saveAnswersToStorage() {
    if (!attemptId) return;
    const answers = {};
    for (let i = 0; i < totalQuestions; i++) {
        const ans = document.getElementById(`selected_answer_${i}`);
        if (ans && ans.value.trim() !== '') {
            answers[i] = ans.value;
        }
    }
    sessionStorage.setItem(`quiz_attempt_${attemptId}`, JSON.stringify(answers));
}

function loadSavedAnswers() {
    if (!attemptId) return;
    const raw = sessionStorage.getItem(`quiz_attempt_${attemptId}`);
    if (!raw) return;
    try {
        const answers = JSON.parse(raw);
        for (const [qIndex, opt] of Object.entries(answers)) {
            selectOption(parseInt(qIndex), opt);
        }
    } catch (e) {
        console.error("Error restoring answers:", e);
    }
}

function openSubmitModal() {
    recordCurrentTimeSpent();
    let answered = 0;
    for (let i = 0; i < totalQuestions; i++) {
        const ans = document.getElementById(`selected_answer_${i}`);
        if (ans && ans.value.trim() !== '') answered++;
    }
    const unanswered = totalQuestions - answered;

    document.getElementById('modalAnsweredCount').textContent = answered;
    document.getElementById('modalUnansweredCount').textContent = unanswered;

    const modal = document.getElementById('submitConfirmModal');
    if (modal) modal.classList.add('active');
}

function closeSubmitModal() {
    const modal = document.getElementById('submitConfirmModal');
    if (modal) modal.classList.remove('active');
}

function submitQuiz(force = false) {
    recordCurrentTimeSpent();
    clearInterval(quizTimerInterval);

    // Populate response times into hidden inputs
    for (let i = 0; i < totalQuestions; i++) {
        const timeInput = document.getElementById(`response_time_${i}`);
        if (timeInput) {
            timeInput.value = questionTimeSpent[i] || 0;
        }
    }

    // Clean up sessionStorage
    if (attemptId) {
        sessionStorage.removeItem(`quiz_attempt_${attemptId}`);
    }

    const form = document.getElementById('quizSubmissionForm');
    if (form) {
        form.submit();
    }
}

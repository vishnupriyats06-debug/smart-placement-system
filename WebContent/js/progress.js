// Progress tracking visualizations & statistics animations

document.addEventListener('DOMContentLoaded', () => {
    // Animate circular progress bars
    const circularMeters = document.querySelectorAll('.circle-progress');
    circularMeters.forEach(meter => {
        const percent = parseFloat(meter.getAttribute('data-percent') || 0);
        const circle = meter.querySelector('circle.progress');
        if (circle) {
            const radius = circle.r.baseVal.value;
            const circumference = 2 * Math.PI * radius;
            circle.style.strokeDasharray = `${circumference} ${circumference}`;
            const offset = circumference - (percent / 100) * circumference;
            setTimeout(() => {
                circle.style.strokeDashoffset = offset;
            }, 100);
        }
    });

    // Animate horizontal progress bars
    const progressBars = document.querySelectorAll('.progress-fill-bar');
    progressBars.forEach(bar => {
        const targetWidth = bar.getAttribute('data-width') || '0%';
        setTimeout(() => {
            bar.style.width = targetWidth;
        }, 150);
    });
});

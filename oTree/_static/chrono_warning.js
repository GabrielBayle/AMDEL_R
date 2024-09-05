function formatTime(seconds) {
    return (('0' + Math.floor(seconds/60)).slice(-2) + ':' + ('0' + seconds % 60).slice(-2))
}

// chrono avec warning *************************************************************************************************
function start_chrono(area_time, area_warning, countdown_time=120) {
    let current_seconds = 0;
    area_time.innerHTML = formatTime(current_seconds);
    let countdown_interval = setInterval(() => {
        current_seconds += 1;
        area_time.innerHTML = formatTime(current_seconds);
        if (current_seconds === countdown_time)
            start_warning(area_warning);
    }, 1000);
    return countdown_interval
}

function start_warning(area_warning) {
    setInterval(() => {
        area_warning.style.visibility = (area_warning.style.visibility === "hidden" ? "visible" : "hidden");
    }, 1000)
}

// Compte à rebours ****************************************************************************************************
function start_timer(area_time, countdown_time) {
    let current_second = countdown_time;
    area_time.innerHTML = formatTime(current_second);
    let countdown_interval = setInterval(() => {
        current_second -= 1;
        if (current_second === -1) {
            stop_countdown(countdown_interval, area_time);
        } else
            area_time.innerHTML = formatTime(current_second);
    }, 1000);
    return countdown_interval
}

function stop_countdown(countdown_interval, area_time) {
    clearInterval(countdown_interval);œ
    area_time.innerHTML = formatTime(0);
}


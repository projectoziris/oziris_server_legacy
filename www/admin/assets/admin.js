(function () {
    'use strict';

    function p(n) { return (n < 10 ? '0' : '') + n; }

    function tick() {
        var el = document.getElementById('clock');
        if (el) {
            var d = new Date();
            el.textContent = d.getFullYear() + '-' + p(d.getMonth() + 1) + '-' + p(d.getDate()) +
                ' ' + p(d.getHours()) + ':' + p(d.getMinutes()) + ':' + p(d.getSeconds());
        }
    }

    function setStatus(cls, label) {
        var pill = document.getElementById('statuspill');
        var lbl = document.getElementById('statuslabel');
        if (!pill || !lbl) { return; }
        pill.className = 'statuspill ' + (cls === 'busy' ? 'busy' : cls);
        pill.classList.remove('busy');
        if (cls === 'busy') { pill.classList.add('busy'); }
        lbl.textContent = label;
    }

    function pollStatus() {
        var pill = document.getElementById('statuspill');
        if (!pill) { return; }
        if (pill.dataset.busy === '1') { return; }
        pill.dataset.busy = '1';
        setStatus('busy', 'checking…');

        var xhr = new XMLHttpRequest();
        xhr.open('GET', 'status.php?t=' + Date.now(), true);
        xhr.timeout = 8000;
        xhr.onload = function () {
            pill.dataset.busy = '0';
            if (xhr.status !== 200) { setStatus('bad', 'unreachable'); return; }
            try {
                var d = JSON.parse(xhr.responseText);
                if (!d || d.ok !== true) { setStatus('bad', 'unknown'); return; }
                var label;
                if (d.overall === 'ok') {
                    label = 'All services running';
                } else if (d.overall === 'warn') {
                    label = 'High CPU (' + d.cpu + '%)';
                } else {
                    var parts = [];
                    if (d.apache !== 'running') { parts.push('Apache'); }
                    if (d.maria !== 'running') { parts.push('MariaDB'); }
                    label = 'Down: ' + (parts.join(', ') || 'unknown');
                }
                setStatus(d.overall, label);
                var hostip = document.getElementById('hostip');
                // no host ip supplied by endpoint; leave as-is
            } catch (e) {
                pill.dataset.busy = '0';
                setStatus('bad', 'parse error');
            }
        };
        xhr.onerror = function () { pill.dataset.busy = '0'; setStatus('bad', 'unreachable'); };
        xhr.ontimeout = function () { pill.dataset.busy = '0'; setStatus('bad', 'timeout'); };
        xhr.send();
    }

    var refreshBtn = document.getElementById('refreshbtn');
    if (refreshBtn) {
        refreshBtn.addEventListener('click', function () { location.reload(); });
    }

    window.__loadTs = Date.now();
    tick();
    setInterval(tick, 1000);
    pollStatus();
    setInterval(pollStatus, 10000);

    // Strip whitespace-only mono cells (blank ipconfig fields).
    var mones = document.querySelectorAll('.mono');
    for (var i = 0; i < mones.length; i++) {
        if (mones[i].textContent.trim() === '') { mones[i].textContent = '--'; }
    }
})();
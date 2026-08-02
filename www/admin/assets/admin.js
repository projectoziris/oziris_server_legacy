(function () {
    'use strict';

    function tick() {
        var el = document.getElementById('clock');
        if (el) {
            var d = new Date();
            var p = function (n) { return (n < 10 ? '0' : '') + n; };
            el.textContent = d.getFullYear() + '-' + p(d.getMonth() + 1) + '-' + p(d.getDate()) +
                ' ' + p(d.getHours()) + ':' + p(d.getMinutes()) + ':' + p(d.getSeconds());
        }
    }
    tick();
    setInterval(tick, 1000);
})();

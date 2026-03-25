var Menu = (function() {

	var effectCallback, micCallback, trackCallback, startCallback;

	var menu = document.querySelector(".menu");
	var btn = document.querySelector(".menu-button");
	var close = document.querySelector(".menu .close");
	var effects = document.querySelectorAll(".effects li");

	var mic = document.querySelector(".mic");
	var track = document.querySelector(".track");

	var start = document.querySelector(".start");

	var translateX = function(e, v) {
		e.style.transform = 'translateX(' + v + 'px)';
	}

	var onClose = function() {
		btn.style.display = 'block';

		setTimeout(function() {
			btn.style.opacity = 1;
		}, 1);

		menu.style.opacity = 0;
		translateX(menu, -30);
	}

	for(var i = 0; i < effects.length; i++) {
		var e = effects[i];
		e.addEventListener('click', function(event) {
			var et = event.target;
			var index = parseInt(et.getAttribute('data-index'));

			for(var j = 0; j < effects.length; j++) {
				var oe = effects[j];
				if(et == oe) oe.setAttribute('class', 'selected');
				else oe.setAttribute('class', '');

				if(effectCallback) effectCallback(index);
			}
		});
	}

	btn.addEventListener('click', function() {
		btn.style.opacity = 0;
		menu.style.opacity = 1;
		translateX(menu, 0);

		setTimeout(function() {
			btn.style.display = 'none';
		}, 200);
	});

	close.addEventListener('click', onClose);

	mic.addEventListener('click', function() {
		mic.setAttribute('class', 'selected');
		track.setAttribute('class', '');
		if(micCallback) micCallback();
	});

	track.addEventListener('click', function() {
		mic.setAttribute('class', '');
		track.setAttribute('class', 'selected');
		if(trackCallback) trackCallback();
	});

	var m = {};

	m.onEffect = (callback) => {
		effectCallback = callback;
	}

	m.onMic = (callback) => {	
		micCallback = callback;
		
	}

	m.onTrack = (callback) => {
		trackCallback = callback;
	}

	m.onStart = (callback) => {
		startCallback = callback;
	}

	track.setAttribute('class', 'selected');
	effects[0].setAttribute('class', 'selected');
	onClose();

	start.querySelector("button").addEventListener("click", () => {
		start.style.display = "none";
		if(startCallback) startCallback();
	});

	return m;

})();











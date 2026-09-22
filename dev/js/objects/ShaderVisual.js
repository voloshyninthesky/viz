// Full-screen fragment shader visual. The quad is emitted in clip space,
// so the camera has no effect and the post effect chain still applies on top.
var ShaderVisual = function(engine, shaderPath, options) {

    options = options || {};

    var canvas = document.getElementById('gl-canvas');
    var quad = new SQR.PostEffect(shaderPath);
    var u = quad.renderer.u;

    var beat = 0, beatTarget = 0, beatCount = 0;
    var bass = 0, mid = 0, high = 0, level = 0;
    var flow = 0;
    var speed = options.speed || 1;

    var levelsA = [0, 0, 0, 0], levelsB = [0, 0, 0, 0];

    this.onBeat = function() {
        beatTarget = 1;
        beatCount++;
    }

    this.use = function() {
        engine.setClearColor(0, 0, 0, 1);
    }

    this.dispose = function() {
    }

    var smooth = function(current, target) {
        return current + (target - current) * (target > current ? 0.35 : 0.08);
    }

    this.update = function(sound) {
        var l = sound.levelsData;

        for(var i = 0; i < 4; i++) {
            levelsA[i] = smooth(levelsA[i], l[i] || 0);
            levelsB[i] = smooth(levelsB[i], l[i + 4] || 0);
        }

        bass = smooth(bass, ((l[0] || 0) + (l[1] || 0)) * 0.5);
        mid = smooth(mid, ((l[2] || 0) + (l[3] || 0) + (l[4] || 0)) / 3);
        high = smooth(high, ((l[5] || 0) + (l[6] || 0) + (l[7] || 0)) / 3);
        level = smooth(level, sound.level || 0);

        beat += (beatTarget - beat) * 0.3;
        beatTarget *= 0.88;

        // Audio-driven clock: things move faster when the music is louder
        flow += Math.min(SQR.Time.deltaTime, 0.1) * speed * (0.4 + level * 2.5 + beat * 1.5);

        u.uTime = SQR.Time.time;
        u.uFlow = flow;
        u.uBeat = beat;
        u.uBeatCount = beatCount;
        u.uBass = bass;
        u.uMid = mid;
        u.uHigh = high;
        u.uLevel = level;
        u.uLevelsA = levelsA;
        u.uLevelsB = levelsB;
        u.uResolution = [canvas.width, canvas.height];
    }

    this.object = quad;
}

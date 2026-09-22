//#vertex
precision mediump float;
attribute vec2 aVertexPosition;
attribute vec2 aTextureCoord;

varying vec2 vTextureCoord;

void main(void) {
    gl_Position = vec4(aVertexPosition, 0.0, 1.0);
    vTextureCoord = aTextureCoord;
}

//#fragment
#ifdef GL_ES
precision highp float;
#endif

uniform vec2 uResolution;
uniform float uTime;
uniform float uFlow;
uniform float uBeat;
uniform float uBass;
uniform float uMid;
uniform float uHigh;
uniform float uLevel;

varying vec2 vTextureCoord;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void main(void) {
    vec2 p = (vTextureCoord - 0.5) * uResolution / min(uResolution.x, uResolution.y) * 2.0;

    float r = length(p);
    float a = atan(p.y, p.x);

    vec3 col = vec3(0.0);

    // Streaks: polar cells, each with a star travelling outwards.
    // Streak length grows with the beat, giving the "jump to lightspeed" feel.
    for(int layer = 0; layer < 3; layer++) {
        float fl = float(layer);
        float cells = 90.0 + fl * 70.0;
        float cellA = floor(a / 6.28318 * cells);
        float h = hash(vec2(cellA, fl * 7.3));
        float h2 = hash(vec2(cellA + 0.5, fl * 3.1));

        float centerA = (cellA + 0.5) / cells * 6.28318;
        float angDist = abs(a - centerA) * r;

        float speed = 0.3 + h * 0.7;
        float t = fract(h2 + uFlow * speed * (0.25 + fl * 0.1));
        float headR = t * t * 2.2;
        float len = (0.02 + uBeat * 0.5 + uBass * 0.2) * headR;

        float along = smoothstep(headR - len, headR, r) * step(r, headR);
        float width = (0.0015 + headR * 0.003) * (1.0 + uHigh);
        float streak = along * smoothstep(width, 0.0, angDist);

        vec3 tint = mix(vec3(0.5, 0.7, 1.0), vec3(1.0, 0.5, 0.9), h);
        tint = mix(tint, vec3(1.0), uBeat * 0.5);
        col += tint * streak * (0.6 + t * 1.2);
    }

    // Nebula glow swirling around the center
    float swirl = sin(a * 3.0 + r * 6.0 - uFlow * 2.0) * 0.5 + 0.5;
    vec3 neb = mix(vec3(0.15, 0.05, 0.35), vec3(0.0, 0.25, 0.4), swirl);
    col += neb * exp(-r * 1.5) * (0.3 + uMid * 1.2);

    // Bright core that flares on beat
    col += vec3(0.8, 0.9, 1.0) * 0.02 / (r + 0.02) * (0.3 + uBeat * 1.5 + uLevel);

    col = col / (1.0 + col);
    gl_FragColor = vec4(col, 1.0);
}

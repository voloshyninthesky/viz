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
uniform float uBeatCount;
uniform float uBass;
uniform float uMid;
uniform float uHigh;
uniform float uLevel;

varying vec2 vTextureCoord;

vec3 palette(float t) {
    return 0.5 + 0.5 * cos(6.28318 * (vec3(1.0, 1.0, 1.0) * t + vec3(0.0, 0.1, 0.2) + vec3(0.8, 0.9, 0.3)));
}

mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

void main(void) {
    vec2 p = (vTextureCoord - 0.5) * uResolution / min(uResolution.x, uResolution.y) * 2.0;

    // Symmetry cycles through 6, 8, 10, 12 segments on beats
    float segments = 6.0 + mod(floor(uBeatCount / 4.0), 4.0) * 2.0;
    float seg = 6.28318 / segments;

    p *= rot(uFlow * 0.1);
    p *= 0.7 - uBass * 0.2;

    float a = atan(p.y, p.x);
    float r = length(p);
    a = mod(a, seg);
    a = abs(a - seg * 0.5);
    vec2 q = vec2(cos(a), sin(a)) * r;

    // Iterated fold, the classic "fractal glow" pattern
    vec3 col = vec3(0.0);
    vec2 z = q;
    for(float i = 0.0; i < 4.0; i++) {
        z = fract(z * (1.4 + uMid * 0.3)) - 0.5;
        z *= rot(uFlow * 0.05 + i);

        float d = length(z) * exp(-length(q));
        vec3 c = palette(length(q) + i * 0.4 + uFlow * 0.1);

        d = sin(d * 8.0 + uFlow) / 8.0;
        d = abs(d);
        d = pow(0.01 / d, 1.2 + uHigh * 0.4);

        col += c * d;
    }

    // Pulsing ring on the beat
    float ring = abs(r - (0.2 + uBeat * 0.9));
    col += vec3(1.0, 0.8, 0.6) * 0.01 / (ring + 0.01) * uBeat;

    col *= 0.6 + uLevel * 1.2;
    col = col / (1.0 + col);

    gl_FragColor = vec4(col, 1.0);
}

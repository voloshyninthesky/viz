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
uniform vec4 uLevelsA;
uniform vec4 uLevelsB;

varying vec2 vTextureCoord;

float spectrum(float x) {
    float i = clamp(x, 0.0, 1.0) * 7.0;
    float f = fract(i);
    vec4 a = uLevelsA;
    vec4 b = uLevelsB;
    float v0 = i < 1.0 ? a.x : i < 2.0 ? a.y : i < 3.0 ? a.z : i < 4.0 ? a.w : i < 5.0 ? b.x : i < 6.0 ? b.y : i < 7.0 ? b.z : b.w;
    float v1 = i < 1.0 ? a.y : i < 2.0 ? a.z : i < 3.0 ? a.w : i < 4.0 ? b.x : i < 5.0 ? b.y : i < 6.0 ? b.z : b.w;
    return mix(v0, v1, smoothstep(0.0, 1.0, f));
}

vec3 palette(float t) {
    return 0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.33, 0.67)));
}

void main(void) {
    vec2 p = (vTextureCoord - 0.5) * uResolution / min(uResolution.x, uResolution.y) * 2.0;

    // Sway the vanishing point
    p += vec2(sin(uTime * 0.4), cos(uTime * 0.3)) * 0.15;

    float r = length(p);
    float a = atan(p.y, p.x);

    // Tunnel mapping: depth is 1/r
    float depth = 1.6 / (r + 0.001) + uFlow * 3.0;
    float twist = a / 6.28318 + uFlow * 0.05 + sin(depth * 0.3) * 0.1;

    // Rings: each ring's brightness follows the spectrum around the circle
    float ringId = floor(depth);
    float ring = abs(fract(depth) - 0.5);
    float band = spectrum(abs(fract(twist + ringId * 0.13) * 2.0 - 1.0));
    float ringGlow = 0.0015 / (ring * ring + 0.0012) * (0.08 + band * band * 3.0);

    // Longitudinal lines
    float spokes = 12.0;
    float line = abs(fract(twist * spokes) - 0.5);
    float lineGlow = 0.0008 / (line * line + 0.001) * (0.1 + uHigh * 1.2);

    vec3 col = palette(ringId * 0.07 + uTime * 0.05 + uMid * 0.3) * ringGlow;
    col += palette(twist + 0.5) * lineGlow * 0.4;

    // Fog towards the center, flash on beat
    float fog = smoothstep(0.0, 0.6, r);
    col *= fog;
    col += vec3(1.0, 0.6, 0.9) * 0.015 / (r + 0.03) * (0.3 + uBass + uBeat * 1.5);

    col *= 1.0 + uBeat * 0.6;
    col = col / (1.0 + col);

    gl_FragColor = vec4(col, 1.0);
}

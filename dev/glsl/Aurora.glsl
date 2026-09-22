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

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
    float v = 0.0;
    float amp = 0.5;
    for(int i = 0; i < 5; i++) {
        v += noise(p) * amp;
        p = p * 2.03 + vec2(1.7, 9.2);
        amp *= 0.5;
    }
    return v;
}

const float HORIZON = 0.2;

vec3 sky(vec2 uv, float aspect) {
    vec2 p = vec2(uv.x * aspect, uv.y);

    vec3 col = mix(vec3(0.01, 0.02, 0.06), vec3(0.02, 0.05, 0.12), uv.y);

    // Twinkling stars, brighter with high frequencies
    vec2 sg = floor(p * 180.0);
    float star = step(0.996, hash(sg));
    float twinkle = 0.5 + 0.5 * sin(uTime * 3.0 + hash(sg + 3.0) * 40.0);
    col += star * twinkle * (0.4 + uHigh * 1.5) * smoothstep(HORIZON, 0.6, uv.y);

    // Several aurora curtains, each driven by a different frequency band
    vec4 bands = vec4(uLevelsA.y, uLevelsA.w, uLevelsB.y, uLevelsB.w);

    for(int i = 0; i < 4; i++) {
        float fi = float(i);
        float energy = i == 0 ? bands.x : i == 1 ? bands.y : i == 2 ? bands.z : bands.w;

        float warp = fbm(vec2(p.x * 0.8 + fi * 3.1, uFlow * 0.15 + fi));
        float curtainY = 0.45 + fi * 0.08 + (warp - 0.5) * (0.35 + uMid * 0.4);

        float dy = uv.y - curtainY;
        // Sharp bottom edge, long soft tail upwards
        float shape = dy > 0.0 ? exp(-dy * (6.0 - energy * 3.0)) : exp(dy * 60.0);

        // Vertical rays flickering along the curtain
        float rays = fbm(vec2(p.x * 12.0 + warp * 4.0, uFlow * 0.6 + fi * 5.0));
        rays = pow(rays, 2.0) * 2.0;

        vec3 tint = mix(vec3(0.1, 1.0, 0.5), vec3(0.6, 0.2, 1.0), fi / 3.0 + sin(uTime * 0.1 + fi) * 0.2);
        tint = mix(tint, vec3(1.0, 0.3, 0.6), smoothstep(0.1, 0.5, dy) * 0.6);

        col += tint * shape * rays * (0.25 + energy * 1.6 + uBeat * 0.3);
    }

    return col;
}

void main(void) {
    vec2 uv = vTextureCoord;
    float aspect = uResolution.x / uResolution.y;
    vec3 col;

    if(uv.y > HORIZON) {
        col = sky(uv, aspect);
    } else {
        // Rippled reflection on a dark lake, ripples kick with the bass
        float d = HORIZON - uv.y;
        float ripple = sin(d * 300.0 / (d + 0.05) - uTime * 3.0) * noise(vec2(uv.x * 40.0, d * 200.0));
        vec2 ruv = vec2(uv.x + ripple * (0.004 + uBass * 0.01), HORIZON + d * 2.5);
        col = vec3(0.004, 0.008, 0.016) + sky(ruv, aspect) * 0.5 * (1.0 - d / HORIZON * 0.7);
    }

    col *= 1.0 + uBass * 0.5;
    col = col / (1.0 + col * 0.6);

    gl_FragColor = vec4(col, 1.0);
}

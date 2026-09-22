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

float hash(float n) {
    return fract(sin(n) * 43758.5453);
}

void main(void) {
    float aspect = uResolution.x / uResolution.y;
    vec2 uv = vTextureCoord;
    vec2 p = vec2((uv.x - 0.5) * aspect, uv.y - 0.42);

    vec3 col;

    if(p.y > 0.0) {
        // Sky
        col = mix(vec3(0.9, 0.2, 0.45), vec3(0.08, 0.02, 0.2), smoothstep(0.0, 0.5, p.y));

        // Sun with horizontal cuts that scroll down
        vec2 sc = p - vec2(0.0, 0.2);
        float sunR = 0.28 + uBass * 0.04 + uBeat * 0.02;
        float sd = length(sc);
        float sun = smoothstep(sunR, sunR - 0.005, sd);
        float cut = step(0.5, fract(sc.y * 22.0 + uTime * 0.6)) + step(0.0, sc.y + 0.02);
        sun *= clamp(cut, 0.0, 1.0);
        vec3 sunCol = mix(vec3(1.0, 0.15, 0.5), vec3(1.0, 0.9, 0.2), smoothstep(-0.25, 0.25, sc.y));
        col = mix(col, sunCol, sun);
        col += sunCol * 0.04 / (abs(sd - sunR) + 0.04) * (0.3 + uBeat * 0.6);

        // Mountain silhouettes: the ridge is the spectrum mirrored around the center
        float sx = abs(p.x) / (aspect * 0.5);
        float ridge = spectrum(sx) * 0.22 + 0.02
            + (hash(floor(p.x * 60.0)) - 0.5) * 0.01
            + sin(p.x * 13.0) * 0.015;
        if(p.y < ridge) {
            col = vec3(0.05, 0.0, 0.1);
            col += vec3(0.3, 0.9, 1.0) * smoothstep(0.006, 0.0, ridge - p.y) * (0.6 + uHigh);
        }

        // Stars
        vec2 sg = floor(uv * uResolution / 3.0);
        float star = step(0.998, hash(sg.x * 17.0 + sg.y * 113.0)) * smoothstep(0.25, 0.5, p.y);
        col += star * (0.5 + uHigh) * smoothstep(sunR, sunR + 0.03, sd);
    } else {
        // Floor grid in perspective, scrolling with the audio clock
        float z = 0.25 / -p.y;
        float x = p.x * z;

        float gz = abs(fract(z + uFlow * 1.5) - 0.5);
        float gx = abs(fract(x * 4.0) - 0.5);

        // Keep lines ~2px wide on screen regardless of distance
        float px = 1.0 / uResolution.y;
        float fwz = min(z * z * 4.0 * px * 2.0, 0.5);
        float fwx = min(z * 4.0 * px * 2.5, 0.5);
        float grid = smoothstep(fwz, 0.0, gz) + smoothstep(fwx, 0.0, gx);

        vec3 gridCol = mix(vec3(1.0, 0.2, 0.8), vec3(0.2, 0.9, 1.0), uMid);
        float fade = exp(-z * 0.08);

        col = vec3(0.04, 0.0, 0.08);
        col += gridCol * grid * fade * (0.8 + uBeat * 1.5);
        col += vec3(0.9, 0.2, 0.5) * exp(p.y * 20.0) * 0.6;
    }

    col = col / (1.0 + col * 0.3);
    gl_FragColor = vec4(col, 1.0);
}

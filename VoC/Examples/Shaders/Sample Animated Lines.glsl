#version 420

// original https://www.shadertoy.com/view/Nt2SDV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.141592653589793

const float CYCLE = 2.;
const float R = .35;
const float CenterX = .65;
const float PadRight = .15;
const vec3 GreyColor = vec3(.8);

float circle(in vec2 p, in float r, bool solid) {
     float d = length(p) - r;
     return solid ? d : abs(d);
}
float circle(in vec2 p, in float r) {
    return circle(p, r, false);
}

float line(in vec2 p, in vec2 p0, in vec2 p1, bool solid) {
    vec2 pa = p - p0, ba = p1 - p0;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0., 1.);
    float d = length(pa - ba * h);
    return solid ? d : abs(d);
}
float line(in vec2 p, in vec2 p0, in vec2 p1) {
    return line(p, p0, p1, false);
}

float box(in vec2 p, in vec2 b, bool solid) {
    vec2 d = abs(p) - b;
    float s = length(max(d, 0.)) + min(max(d.x, d.y), 0.);
    return solid ? s : abs(s);
}
float box(in vec2 p, in vec2 b) {
    return box(p, b, false);
}

void main(void) {
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / min(resolution.y, resolution.x);
    float fw = length(fwidth(uv));
    float DotSize = fw * 1.5;
    
    float CS = cos(time * CYCLE);
    float SS = sin(time * CYCLE);
    
    float rightArea = step(uv.x, CenterX);
    vec3 col = vec3(0.);
    
    float d = 0.;
    
    float axis = min(line(uv, vec2(-5., 0.), vec2(5., 0.)), line(uv, vec2(CenterX, -5.), vec2(CenterX, 5.)));
    d = axis;
    
    vec2 offset = (vec2(CenterX, 0.) + PadRight + R) * vec2(-1., 1.);
    vec2 circlePos = uv + offset;
    float mainCircle = circle(circlePos, R);
    d = min(mainCircle, d);
    
    vec2 posOnCircle = vec2(CS, SS) * R - offset;
    
    float circleDot = circle(circlePos, DotSize, true);
    float circleDot2 = circle(posOnCircle - uv, DotSize, true);
    d = min(circleDot, d);
    d = min(circleDot2, d);
    
    float pointerLine = line(uv, -offset, posOnCircle);
    d = min(pointerLine, d);
    
    float xLine = line(uv, posOnCircle, vec2(posOnCircle.x, 0.));
    float yLine = line(uv, posOnCircle, vec2(CenterX, posOnCircle.y));
    d = min(xLine, d);
    d = min(yLine, d);
    float xLineDot = circle(uv - vec2(posOnCircle.x, 0.), DotSize, true);
    float yLineDot = circle(uv - vec2(CenterX, posOnCircle.y), DotSize, true);
    d = min(xLineDot, d);
    d = min(yLineDot, d);
    
    col = vec3(smoothstep(-fw, fw, d));
    
    float maskBox = box(uv - vec2(CenterX - 2., .5), vec2(2., .5), true);
    maskBox = min(maskBox, box(uv - vec2(-2., -.5), vec2(4., .5), true));
    vec2 centerPos = uv - vec2(CenterX, 0.);
    float quatCircle1 = circle(centerPos, PadRight);
    float quatCircle2 = circle(centerPos, PadRight + R);
    float quatCircle3 = circle(centerPos, PadRight + R * 2.);
    float qd = max(quatCircle1, -maskBox);
    qd = min(max(quatCircle2, -maskBox), qd);
    qd = min(max(quatCircle3, -maskBox), qd);
    
    col = mix(GreyColor, col, smoothstep(-fw, fw, qd));
    
    float cs01 = CS * .5 + .5;
    float csY = cs01 * R * 2.;
    float animCircle = circle(centerPos, PadRight + csY);
    float qd2 = max(animCircle, -maskBox);
    float yLineDot2 = circle(uv - vec2(CenterX, PadRight + csY), DotSize, true);
    qd2 = min(yLineDot2, qd2);
    
    col *= smoothstep(-fw, fw, qd2);
    
    vec2 wave = vec2(
        sin((uv.x - CenterX) / R + time * CYCLE) * R,
        cos((uv.x - CenterX) / R + time * CYCLE) * R
    );
    vec2 dWave = wave.yx / R;
    vec2 baseY = vec2(uv.y + R + PadRight, uv.y - R - PadRight);
    // https://www.iquilezles.org/www/articles/distance/distance.htm
    vec2 waveLines = 1. - smoothstep(fw, -fw, abs(wave - baseY) / sqrt(1. + dWave * dWave)) * rightArea;
    vec3 waveColor = vec3(waveLines.x * waveLines.y);
    
    col *= waveColor;
    
    float maskBar = box(vec2(-5., uv.y - PadRight - R), vec2(5. + CenterX, R), true);
    maskBar = min(maskBar, box(vec2(-5., uv.y + PadRight + R), vec2(5. + CenterX, R), true));
    maskBar = min(maskBar, box(vec2(uv.x - CenterX * 2., uv.y), vec2(CenterX, PadRight), true));
    float timeCycle = time * CYCLE * R;
    float gridMoveTime = rightArea * timeCycle;
    vec2 grid = 1. - smoothstep(fw, 0., vec2(
            mod(uv.x - CenterX - PadRight * (1. - rightArea) + gridMoveTime, mix(R, R * PI * .5, rightArea)),
            mod(abs(uv.y) - PadRight, R)
        )
    ) * smoothstep(fw, -fw, maskBar) * smoothstep(fw, -fw, maskBox);
    
    col *= mix(GreyColor, col, grid.x * grid.y);
    
    glFragColor = vec4(col, 1.);
}

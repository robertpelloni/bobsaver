#version 420

// original https://neort.io/art/bpd8gb43p9f4nmb8bf5g

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

float random (vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

float getTime(float t){
    t *= 1.2;
    return t;
    return floor(t) + smoothstep(0.1,0.9,fract(t));
    return floor(t) + (1. - (1. - fract(t)) * (1. - fract(t)));
}
float waveX(float t){
    float result = 0.;
    float A = 1.0;
    float T = 1.0;
    for(int i = 0; i < 6; i++){
        result += A * sin(t * T);
        A /= 2.;
        T *= 2.;
    }
    return result;
}
float waveY(float t){
    float result = 0.;
    float A = 1.0;
    float T = 1.0;
    for(int i = 0; i < 6; i++){
        result += A * cos(t * T);
        A /= 2.;
        T *= 2.;
    }
    return result;
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy) / min(resolution.x, resolution.y);
    vec2 uv2 = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    vec2 uvBB = (gl_FragCoord.xy) /resolution;
    vec2 vel = vec2(0.04,0.01);
    uv = uv;
    uv += vel*time + vec2(waveX(time * 0.1),waveY(time * 0.1))* 0.1;
    float cellCount = 3.0;
    vec2 grid = ceil(uv * cellCount) / cellCount;
    vec2 st = fract(uv * cellCount);
    vec3 col = vec3(253./255.,255./255.,251./255.);
    float frameRad = 0.5;
    float at = atan((st - 0.5).y/(st - 0.5).x);
    float randRad = random(vec2(floor(at * 10.) + grid + floor(time * 5.0)));
    col = abs(abs(length(st - 0.5) - frameRad) - 0.05) - 0.0025 > 0. * 1. ? col : vec3(1./255.,22./255.,39./255.);
    float a = random(grid) * 0.9 + 0.1;
    float b = random(vec2(grid.y,grid.x)) * 0.9 + 0.1;
    float c = random(vec2(1./grid.y,1./grid.x)) * 0.9 + 0.1;
    float d = random(vec2(1./grid.x,1./grid.y)) * 0.9 + 0.1;
    float e = random(2.0 * grid) * 0.8 + 0.2;
    float f = random(vec2(2.0 * grid.y,2.0 * grid.x)) * 0.8 + 0.2;
    float g = random(vec2(2./grid.y,2./grid.x)) * 0.8 + 0.2;
    float h = random(vec2(2./grid.x,2./grid.y)) * 0.8 + 0.2;
    float t1 = (time);
    vec2 posA = vec2(a*cos(c * t1),b*sin(d * t1)) * 0.25;
    vec2 posB = vec2(d*cos(c * t1),b*sin(a * t1)) * 0.25;
    float distA = 2.0;
    float distB = 2.0;
    for(float j = 0.; j < 2.5; j += 0.02){
        float size = fract(j * 2.5) > 0.05 ? 0.02 : 0.0;
        vec2 posA = vec2(a*cos(c * getTime(t1 -j)),b*sin(d * getTime(t1 -j))) * 0.2;
        posA += vec2(e*cos(f * getTime(t1 -j) * 3.0),g*sin(h * getTime(t1 -j) * 3.0)) * 0.15;
        posA += vec2(c*cos(e * getTime(t1 -j) * 5.0),f*sin(d * getTime(t1 -j) * 5.0)) * 0.075;
        vec2 posB = vec2(d*cos(c * getTime(t1 -j)),b*sin(a * getTime(t1 -j))) * 0.2;
        posB += vec2(h*cos(g * getTime(t1 -j) * 3.0),f*sin(e * getTime(t1 -j) * 3.0)) * 0.15;
        posB += vec2(e*cos(c * getTime(t1 -j) * 5.0),d*sin(f * getTime(t1 -j) * 5.0)) * 0.075;
        distA = min(length(st - posA - 0.5) + size,distA);
        distB = min(length(st - posB - 0.5) + size,distB);
    }
    vec3 colA = vec3(46./255.,196./255.,182./255.);
    vec3 colB = vec3(231./255.,29./255.,54./255.);
    col = distA < 0.03 ? colA : col;
    col = distB < 0.03 ? colB : col;
    //uv2.x += uv2.y * 0.2 + floor(uv2.y * 3.0);
    //uv2.y += uv2.x * 0.2 + floor(uv2.x * 3.0);
    float rx = random(vec2(floor(uv2.x * 5.0),floor(time *5.0))) - 0.5;
    float ry = random(vec2(floor(time * 7.0),floor(uv2.y * 5.0))) - 0.5;
    //col = rx * ry < 0. ? col: 1. - col;
    //col = 1. - col;
    uv2 += vec2(waveX(time * 0.15),waveY(time * 0.15))* 0.4;
    float range = waveX(time * 0.15);
    col *= 1. - ((uv2.x) * (uv2.x) + (uv2.y) * (uv2.y)) * 0.15 * (0.75 + 0.3 * range);
    col = mix(col, texture2D(backbuffer,uvBB).xyz,0.5);
    //col -= random(st) * 0.2;
    glFragColor = vec4(col, 1.0);
}

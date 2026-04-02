#version 420

// original https://www.shadertoy.com/view/3sXXD4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14
#define RGB(r, g, b, a) vec4(vec3(float(r)/255., float(g)/255., float(b)/255.), a)
#define NO_DISTANCE 10000.

// NOISE IMPL FROM: https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83#perlin-noise

float rand(vec2 c){
    return fract(sin(dot(c.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float noise(vec2 p, float freq ){
    float unit = resolution.x/freq;
    vec2 ij = floor(p/unit);
    vec2 xy = 0.5*(1.-cos(PI*mod(p,unit)/unit));
    float a = rand((ij+vec2(0.,0.)));
    float b = rand((ij+vec2(1.,0.)));
    float c = rand((ij+vec2(0.,1.)));
    float d = rand((ij+vec2(1.,1.)));
    float x1 = mix(a, b, xy.x);
    float x2 = mix(c, d, xy.x);
    return mix(x1, x2, xy.y);
}

float pNoise(vec2 p, int res, float scale, float lacunarity){
    float persistance = .5;
    float n = 0.;
    float normK = 0.;
    float f = scale;
    float amp = 1.;
    int iCount = 0;
    for (int i = 0; i<50; i++){
        n+=amp*noise(p + time, f);
        f*=lacunarity;
        normK+=amp;
        amp*=persistance;
        if (iCount == res) break;
        iCount++;
    }
    float nf = n/normK;
    return nf*nf*nf*nf*3.0;
}

float noiseTextureScalar(vec2 p, float distortion, float scale, int detail, float lower) {
    float distortionTheta = pNoise(p, detail, scale, 2.) * 2. * PI;
    vec2 distortionOffset = distortion*vec2(cos(distortionTheta), sin(distortionTheta));
    return abs(pNoise(p + distortionOffset, detail, scale, 2.));
}

vec4 noiseTexture(vec2 p, float distortion, float scale, int detail, float lower) {
    return vec4(
        noiseTextureScalar(p+10000., distortion, scale, detail, lower),
        noiseTextureScalar(p+20000., distortion, scale, detail, lower),
        noiseTextureScalar(p, distortion, scale, detail, lower),
        1.0
    );
}

// 4th param should be point on ramp
#define RAMP_STEPS 6
vec3 colorRamp(float p, vec4 steps[RAMP_STEPS]) {
    /*float sum = 0;
    for (int i = 0; i < RAMP_STEPS; ++i) {
        sum += 1.0 - abs(steps[i].w - p);
    }
    vec3 color = vec3(0.);
    for (int i = 0; i < RAMP_STEPS; ++i) {
        color += steps[i].xyz * (1.0 - abs(steps[i].w - p))/sum;
    }*/
    vec3 color = mix(steps[0].xyz, steps[1].xyz, smoothstep(steps[0].w, steps[1].w, p));
    color = mix(color, steps[2].xyz, smoothstep(steps[1].w, steps[2].w, p));
    color = mix(color, steps[3].xyz, smoothstep(steps[2].w, steps[3].w, p));
    color = mix(color, steps[4].xyz, smoothstep(steps[3].w, steps[4].w, p));
    return color;
}

vec4 christmasNoise(vec2 p) {
    vec4 c1 = RGB(23, 39, 44, 1.0);
    vec4 c2 = RGB(27, 85, 82, 1.0);
    vec4 c3 = RGB(111, 177, 128, 1.0);
    vec4 c4 = RGB(231, 204, 129, 1.0);
    vec4 c5 = RGB(228, 98, 65, 1.0);

    vec4 rampColors[RAMP_STEPS];
    
    rampColors[0] = RGB(140, 70, 12, 0.1);
    rampColors[1] = RGB(100, 0, 0, 0.0);
    rampColors[2] = RGB(198, 73, 69, 0.2);
    rampColors[3] = RGB(231, 204, 129, 0.7);
    rampColors[4] = RGB(180, 60, 65, 1.0);
    rampColors[5] = RGB(0, 0, 0, 2.0);
  

    vec4 n1 = noiseTexture(p, 0., 0.1 + 0.0001*time, 16, 0.0);
    
    vec2 samplePoint = n1.xy*resolution.xy;
    
    vec4 n2 = noiseTexture(samplePoint, 10., 8., 16, 0.0);
    
    vec4 n3 = noiseTexture(n2.xy*resolution.xy, 3., 4., 16, 0.0);

    //glFragColor = mix(orangeLayer, blueLayer, abs(sin(time/100.)));
    return vec4(colorRamp(n3.x, rampColors), 1.0);//mix(orangeLayer, blueLayer, abs(sin(time/100.)));//vec4(orangeLayer.x, blueLayer.z, greenLayer.y, 1.0);
}

struct Candidate {
    vec4 color;
    float distance;
};

bool candidate_passes(Candidate candidate, vec4 color, vec4 us, float dir) {
    if (candidate.distance == NO_DISTANCE) {
        return true;
    }
    float delta = candidate.distance - length(us - color);
    return delta * dir > 0.;
}

vec4 layer1(vec2 pos) {
    return christmasNoise(pos*resolution.xy);
}

Candidate consider(vec2 pos, Candidate candidate, vec4 us, float dir) {
    vec4 color = layer1(pos);
    if (candidate_passes(candidate, color, us, dir)) {
        candidate.color = color;
        candidate.distance = length(color - us);
    }
    return candidate;
}

vec4 closest_neighbor(vec2 pos, float distance, float dir) {
    vec2 unit = vec2(1.0 / resolution.x, 1.0 / resolution.y) * distance;
    vec4 us = layer1(pos);

    Candidate candidate;
    candidate.color = us;
    candidate.distance = NO_DISTANCE;

    candidate = consider(pos - unit, candidate, us, dir);
    candidate = consider(pos + unit, candidate, us, dir);

    candidate = consider(pos + vec2(unit[0], 0), candidate, us, dir);
    candidate = consider(pos + vec2(0, unit[1]), candidate, us, dir);

    candidate = consider(pos - vec2(unit[0], 0), candidate, us, dir);
    candidate = consider(pos - vec2(0, unit[1]), candidate, us, dir);

    candidate = consider(pos + vec2(-unit[0], unit[1]), candidate, us, dir);
    candidate = consider(pos + vec2(unit[0], -unit[1]), candidate, us, dir);

    return candidate.color;
}

vec4 closest_neighbor_n(vec2 pos, float start, float step, int n, float dir) {
    vec4 us = layer1(pos);
    Candidate candidate;
    candidate.color = us;
    candidate.distance = NO_DISTANCE;

    for (int i = 0; i < n; i++) {
        float distance = float(i + 1) * step + sign(step) * start;
        vec4 color = closest_neighbor(pos, distance, dir);
        if (candidate_passes(candidate, color, us, dir)) {
            candidate.color = color;
            candidate.distance = length(color - us);
        }
    }

    return candidate.color;
}
vec4 layer3(vec2 uv) {
    float start = 0.05;
    float step = 0.0000005;
    int steps = 5;
    return closest_neighbor_n(uv, resolution.x * start, resolution.x * step, steps, -1.);
}

vec2 domainWarp() {
    float scale = abs(pNoise(gl_FragCoord.xy, 3, 4., 2.))*1000.;
    vec2 off = vec2(pNoise(gl_FragCoord.xy, 3, 4., 2.) * scale, pNoise(-1.0 * gl_FragCoord.xy, 3, 4., 2.)*scale);
    return gl_FragCoord.xy + off;
}

void main(void)
{
    glFragColor = layer1(gl_FragCoord.xy/resolution.xy);
}

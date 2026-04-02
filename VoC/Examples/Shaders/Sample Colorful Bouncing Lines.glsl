#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/wd3GWB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define time time
#define resolution resolution

float drawPoint(vec2 uv, vec2 p, float size) {
    float d = length(uv - p);
    return smoothstep(size, size * 0.75, d);
}

float drawGrid(vec2 uv) {
    float gridX = smoothstep(.004, .002, abs(uv.x));
    float gridY = smoothstep(.004, .002, abs(uv.y));
    return gridX + gridY;
}

float DistToLine(vec2 p, vec2 l0, vec2 l1) {
    float lineLength = length(l1 - l0);
    lineLength *= lineLength;

    vec2 v = l1 - l0;
    vec2 x = p - l0;
    
    float vx = dot(x, v);
    vec2 lp = v * clamp(vx / lineLength, 0., 1.) + l0;
    return length(p - lp);
}

float rand(float seed) {
    return fract(sin(sin(seed * 9123.35) * 1276.73) * 5422.92);
}

float rand(vec2 seed) {
    float n = rand(seed.x);
    return fract(sin(sin(seed.y * 725.35 + n * 1234.92) * 8538.74) * 422.43);
}

vec2 randomPoint(float seed) {
    float aspect = resolution.x / resolution.y;
    float x = rand(seed / 1000.);
    float y = rand(seed / 1000. * 124.41);
    
    vec2 xy = vec2(x, y);
    
    xy -= .5;
    xy.x *= aspect;
    xy *= 2.;
    return xy;
}

vec3 randomColor(vec2 seed) {
    float aspect = resolution.x / resolution.y;
    float x = rand(seed.x / 1000.);
    float y = rand(seed.y + x / 1000. * 2235.71);
    float z = rand((seed.x + seed.y) * y / 1000. * 634.71);
    return vec3(x, y, z);
}

float drawLine(vec2 uv, vec2 l0, vec2 l1, float multiplier) {
    
    l1 = l0 + (l1 - l0) * clamp(multiplier * multiplier, 0., 1.);
    
    float d = DistToLine(uv, l0, l1);
    float mask = 0.;
    if (d < .2) {
        mask = smoothstep(.03, .02, d);
    }
    
    return mask;
}

float drawLine(vec2 uv, vec2 l0, vec2 l1) {
    return drawLine(uv, l0, l1, 1.);
}

vec4 animateLine(vec2 uv, float t0, float t1) {
    float mask = 0.;
    float t = time;
    
    if (int(t0) % 2 != 0) {
        t += .5;
    }
    
    float tt = fract(t);
    
    vec2 p0 = randomPoint(t0);
    vec2 p1 = randomPoint(t1);
    
    vec3 rCol = randomColor(p0 + t0);
    
    if (tt < 0.5) {
        mask += drawLine(uv, p0, p1, tt * 2.);
    } else {
        mask += drawLine(uv, p1, p0, 1. - ((tt - .5) * 2.));
    }
    
    return vec4(rCol * mix(0., 1., mask), mask);
}

void main(void) {
    vec2 uv = vec2(0);

    uv = gl_FragCoord.xy / resolution.xy;
    uv -= .5;
    uv.x *= resolution.x / resolution.y;
    uv *= 2.;
    
    float mask = 0.;
    
    vec4 col = vec4(0.);
    
    float t0 = floor(time);
    float t1 = t0 + 1.;
    float t2 = t0 + 2.;
    
    for (float i = 0.; i < 10.; i += 1.) {
        float ti0 = t0 + i * 1.;
        float ti1 = ti0 + 1.;
        col = mix(animateLine(uv, ti0, ti1), col, col.a);    
    }
    
    // mask += drawGrid();
    // mask = rand(uv);// * 10.;
    
    glFragColor = vec4(col.xyz, 1.);
}

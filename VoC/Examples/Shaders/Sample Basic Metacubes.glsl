#version 420

// original https://www.shadertoy.com/view/ml2fzK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define ASPECT 16.0/9.0

vec2 rotate2d(vec2 v, float a) {
    return vec2(cos(a) * v.x - sin(a) * v.y, sin(a) * v.x + cos(a) * v.y); 
}

vec3 rotate3d(vec3 v, vec3 angles) {
    v = vec3(v.x, rotate2d(v.yz, angles.x));
    vec2 rxz = rotate2d(v.xz, angles.y);
    v = vec3(rxz.x, v.y, rxz.y);
    v = vec3(rotate2d(v.xy, angles.z), v.z);
    return v;
}

float smin(float a, float b, float k)
{
    float h = max(k-abs(a-b), 0.0) / k;
    return min(a, b) - h*h*k*(1.0/4.0);
}

float ballSdf(in vec3 center, in float radius, in vec3 pos) {
    return length(pos - center) - radius;
}

float cubeSdf(in vec3 center, in float radius, in vec3 rot, in vec3 pos) {
    vec3 disp = pos - center;
    disp = rotate3d(disp, rot);
    vec3 d = abs(disp) - vec3(radius);
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float softcubeSdf(in vec3 center, in float radius, in vec3 rot, in float soft, in vec3 pos) {
    vec3 disp = pos - center;
    disp = rotate3d(disp, rot);
    vec3 d = abs(disp) - vec3(radius - soft);
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0)) - soft;
}

float shapeSdf(in vec3 center, in float radius, in vec3 rot, in vec3 pos) {
    //return smin(ballSdf(center, radius * 1.6, pos), cubeSdf(center, radius, rot, pos), radius * 0.6);
    return softcubeSdf(center, radius, rot, 0.25, pos);
}

vec2 map(in vec3 pos) {
    vec3 ctr1 = vec3(sin(time * 0.5) * 6.0, 0.0, 8.0 + cos(time * 0.3) * 2.9);
    vec3 ctr2 = vec3(sin(time * 0.5 + 2.0) * 6.0, 0.0, 8.0 + cos(time * 0.2 + 0.1) * 2.9);
    float ball1 = shapeSdf(ctr1, 3.0, vec3(time*0.5), pos);
    float ball2 = shapeSdf(ctr2, 3.0, vec3(-time*0.25)+vec3(0.5,2,0), pos);
    return vec2(smin(ball1, ball2, 3.0), ball2 - ball1);
}

vec3 mapNormal(in vec3 p) {
    const float eps = 0.0001;
    const vec2 h = vec2(eps,0);
    return normalize(vec3(map(p+h.xyy).x - map(p-h.xyy).x,
                          map(p+h.yxy).x - map(p-h.yxy).x,
                          map(p+h.yyx).x - map(p-h.yyx).x));
}

vec3 rayColor(in vec3 origin, in vec3 dir, in float maxDist) {
    dir = normalize(dir);
    vec3 p = origin;
    vec3 prev = p;
    float s = map(p).x;
    float dist = maxDist;
    while (s > 0.0001 && dist > 0.0) {
        float stepLen = max(s, 0.02);
        dist -= stepLen;
        prev = p;
        p += dir * stepLen;
        s = map(p).x;
    }
    if (s > 0.0001) return vec3(0);
    vec3 norm = mapNormal(p);
    float mat = map(p).y;
    float red = clamp(smoothstep(-5.0, 5.0, mat), 0.0, 1.0);
    float blue = clamp(smoothstep(-5.0, 5.0, -mat), 0.0, 1.0);
    vec3 ambient = normalize(vec3(red, 0.0, blue)) * 0.3;
    vec3 lightDir = normalize(vec3(1,-1,1));
    vec3 diffuse = max(dot(lightDir, -norm),0.0) * vec3(0.9);
    return ambient + diffuse;
}

void main(void)
{
    vec2 xy = (gl_FragCoord.xy/resolution.y - vec2(0.5 * ASPECT, 0.5)) * 5.0;
    vec3 cam = vec3(0,0,-4);
    vec3 ray = vec3(xy,0.0) - cam;
    
    vec3 col = rayColor(cam, ray, 20.0);

    // Output to screen
    glFragColor = vec4(col, 1.0);
}

#version 420

// original https://www.shadertoy.com/view/3syGRG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float cylinder(float r, float h, vec3 p) {
    return max(length(p.xy)-r, abs(p.z)-h);
}

mat2 rot(float angle) {
    return mat2(sin(angle), cos(angle), cos(angle), -sin(angle));
}

float sceneSDE(vec3 p) {
    float h = p.y;
    float angle1 = time;
    float angle2 = time * 1.6;
    p.yz *= rot(angle1);
    p.xz *= rot(angle2);
    return min(cylinder(1.,1.,p), h+2.);
}

vec3 rayMarch(vec3 origin, vec3 dir) {
    vec3 p = origin;
    while(true) {
        float d = sceneSDE(p);
        if (d < 0.01) { return p; }
        if (length(p - origin) > 100.) { return p; }
        p += dir * d;
    }
}

float light(vec3 p, vec3 l) {
    vec3 lvec = normalize(l-p);
    if (length(rayMarch(p+0.1 * lvec, lvec)-p) < length(l-p)) { return 0.; }
    vec2 helper = vec2(1e-5,0);
    float d = sceneSDE(p);
    vec3 norm = normalize(vec3(
        sceneSDE(p + helper.xyy) - d,
        sceneSDE(p + helper.yxy) - d,
        sceneSDE(p + helper.yyx) - d
        ));
   return dot(norm, lvec);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-resolution.xy*0.5)/resolution.y;
    vec3 eye1 = vec3(-0.05,0,10);
    vec3 eye2 = vec3(0.05,0,10);
    vec3 l = vec3(3,10,5);
    vec3 canvas = vec3(uv*3., 5);
    
    glFragColor = vec4(0,0,0,1);

    vec3 p = rayMarch(eye1, normalize(canvas-eye1));
    if (length(eye1-p)>100.) { glFragColor.x = 0.; }
    else { glFragColor.x = light(p, l); }
    if (abs(p.y - -2.)<0.01) {glFragColor.x *= sin(p.x+time)*0.4+0.5; }
    
    p = rayMarch(eye2, normalize(canvas-eye2));
    if (length(eye2-p)>100.) { glFragColor.y = 0.; }
    else { glFragColor.y = light(p, l); }
    if (abs(p.y - -2.)<0.01) {glFragColor.y *= sin(p.x+time)*0.4+0.5;}
    glFragColor.z = glFragColor.y;
}

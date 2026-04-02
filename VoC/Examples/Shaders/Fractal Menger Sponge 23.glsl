#version 420

// original https://www.shadertoy.com/view/ssByDw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.1415926;
const vec3 CAMERA_POS = vec3(0.0, 0.0, -2.0);
const vec3 DIRECTIONAL_LIGHT_DIR = normalize(vec3(-1.0, -1.0, 1.0));
const vec3 AMBIENT_LIGHT_COLOR = vec3(0.05);

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

mat2 rotate2d(float angle){
    return mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
}

vec2 foldRotate(vec2 p, float s) {
    float t = PI * 2.0 / s;
    float a = -atan(p.x, p.y) + PI / 2.0 + t / 2.0;
    a = mod(a, t) - t / 2.0;
    a = abs(a);
    return length(p) * vec2(cos(a), sin(a));
}

float mengerSponge(vec3 p0) {
    vec4 p = vec4(p0, 1.0);
    for (int n = 0; n < 3; n++) {
        p.xy = foldRotate(p.xy, 6.0);    
        p.yz = foldRotate(p.yz, 6.0);    
        p = abs(p);
        p *= 3.0; 
        p.xyz -= 2.0;
        p.z += 1.0;
        p.z = abs(p.z);
        p.z -= 1.0;
    }
    return sdBox(p.xyz, vec3(1.0))/p.w;
}

float distFunc(vec3 p){
    vec2 mouse = (mouse*resolution.xy.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);

    //if (mouse*resolution.xy.z>0.) {
    //    p.xy = rotate2d(mouse.x * 3.0)*p.xy;
    //    p.yz = rotate2d(mouse.y * 3.0)*p.yz;
    //}else{
        p.xy = rotate2d(time)*p.xy;
        p.yz = rotate2d(time)*p.yz;
    //}
    return mengerSponge(p);
}

vec3 estimateNormal(vec3 p){
    float d = 0.001;
    vec3 dX = vec3(d, 0.0, 0.0);
    vec3 dY = vec3(0.0, d, 0.0);
    vec3 dZ = vec3(0.0, 0.0, d);
    return normalize(vec3(
        distFunc(p + dX) - distFunc(p),
        distFunc(p + dY) - distFunc(p),
        distFunc(p + dZ) - distFunc(p)
    ));
}

vec3 rayMarching(vec3 rayPos, vec3 rayDir){
    for(int i = 0; i < 64; i++){
        float d = distFunc(rayPos);
        if(abs(d) < 0.001){
            vec3 normal = estimateNormal(rayPos);
            float diffuseReflection = max(dot(normal, -DIRECTIONAL_LIGHT_DIR), 0.0);
            return vec3(diffuseReflection) + AMBIENT_LIGHT_COLOR;
        }
        rayPos += rayDir * d;
    }
    return vec3(0.0);
}

void main(void)
{
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    vec3 rayDir = normalize(vec3(p.x, p.y, 1.0));
    vec3 color = vec3(rayMarching(CAMERA_POS, rayDir));
    glFragColor = vec4(color, 1.0);
}

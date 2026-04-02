#version 420

// original https://www.shadertoy.com/view/slByRw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_ITER 10
#define MAX_STEPS 100
#define MAX_DIST 10.
#define MIN_DIST .001
#define EPSILON .0001

vec2 cis(float theta) {
    return vec2(cos(theta), sin(theta));
}

vec2 mul(vec2 z, vec2 w) {
    return z.x * w + z.y * vec2(-w.y, w.x);
}

vec3 rotate(vec3 p, vec3 rot) {
    vec2 v = mul(p.yz, cis(rot.x));
    vec3 p_prime = vec3(p.x, v.xy);
    v = mul(p_prime.xz, cis(rot.y));
    p_prime = vec3(v.x, p_prime.y, v.y);
    v = mul(p_prime.xy, cis(rot.z));
    p_prime = vec3(v.xy, p_prime.z);
    return p_prime;
}

float DE(vec3 c) {
    vec3 z = c;
    float power = 8.0;
    float bailout = 2.0;
    float dr = 1.0;
    float r = 0.0;
    for (int k = 0; k < MAX_ITER; k++) {
        r = length(z);
        if (r > bailout) break;
        
        float theta = power * acos(z.z/r);
        float phi = power * atan(z.y, z.x);
        dr =  pow(r, power-1.0) * power * dr + 1.0;        
        r = pow(r,power);
        
        z = r * vec3(sin(theta) * cos(phi), sin(phi) * sin(theta), cos(theta)) + c;
    }
    return 0.5*log(r)*r/dr;
}

float RayMarch(vec3 ro, vec3 rd) {
    float dO=0.;
    
    for(int i=0; i<MAX_STEPS; i++) {
        vec3 p = ro + rd*dO;
        float dS = DE(p);
        dO += dS;
        if(dO>MAX_DIST || dS<MIN_DIST) break;
    }
    
    return dO;
}

vec3 normalVector(vec3 p) {
    float d = DE(p);
    vec2 e = vec2(EPSILON, 0);
    
    vec3 n = d - vec3(
        DE(p-e.xyy),
        DE(p-e.yxy),
        DE(p-e.yyx));
    
    return normalize(n);
}

float lighting(vec3 p) {
    vec3 lightPos = rotate(vec3(0.0, -5.0, 5.0), vec3(-0.5, 0., time / 5.));
    vec3 l = normalize(lightPos - p);
    vec3 n = normalVector(p);
    
    float dif = clamp(dot(n, l), 0.0, 1.0);
    float d = RayMarch(p + n * MIN_DIST * 2.0, l);
    if(d < length(lightPos - p)) dif *= .1;
    
    return dif;
}

void main(void)
{
    float zoom = 2.0;
    vec2 uv = zoom * (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.x;
    
    vec3 rot = vec3(-0.5, 0.0, time / 5.);
    vec3 ro = rotate(vec3(0.0, -3.0, 0.0), rot);
    vec3 rd = normalize(rotate(vec3(uv.x, 1.0, uv.y), rot));

    float d = RayMarch(ro, rd);
    
    vec3 p = ro + rd * d;
    
    float dif = lighting(p);
    vec3 col = vec3(dif);
    
    col = pow(col, vec3(0.45));
    
    glFragColor = vec4(col, 1.0);
}

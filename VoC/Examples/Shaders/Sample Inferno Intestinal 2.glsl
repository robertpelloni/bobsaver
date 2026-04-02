#version 420

// original https://www.shadertoy.com/view/mssBzs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 70
#define MAX_DIST 35.0
#define EPS 0.01
#define STEP_COEF .4
#define NORMAL_COEF EPS

#define funcRayMarch float step, t = 0.; for(int i = 0; i < MAX_STEPS; i++){step = map(ro + t * rd); t += step * STEP_COEF; if(t > MAX_DIST || step < EPS) break;} return t;
#define funcNormal float d = map(p); vec2 e = vec2(NORMAL_COEF, 0); vec3 n = vec3(d) - vec3(map(p-e.xyy), map(p-e.yxy), map(p-e.yyx)); return n;
#define funcShadow return dot(normalize(normal(p)), normalize(lightPos - p));

#define PI atan(.0, -1.)
#define T time

#define fire vec3(8, 4, 1) / 5.
#define blood vec3(7, 2, 0) / 15.

float id;

vec2 path(in float z) {
    float a = sin(z * 0.16);
    float b = cos(z * 0.13);
    return 3. * vec2(a - b, b + a);
}

float map(vec3 p) {
    p.xy -= path(p.z);
    
    float gyr = dot(cos(p * PI/2.), sin(p.yzx * PI/2.)) + 1.;
    
    float delg = gyr 
        + .25 
        + dot(cos(p * 13. - T * 20.), vec3(.02));
    
    float cyl = max(
        3.25 
        - length(p.xy - vec2(0, 1)) 
        + .05 * cos(p.z * PI / 100.), 
        
        .75 - gyr 
        
    ) - abs(1.2 - 2. * gyr) * .35;
    
    id = step(cyl, delg);
    return min(cyl, delg);
}

float rayMarch(vec3 ro, vec3 rd){funcRayMarch}
vec3 normal(vec3 p) {funcNormal}
float shadow(vec3 p, vec3 lightPos) {funcShadow}

void main(void) {
    vec2 uv = (gl_FragCoord.xy - resolution.xy * 0.5) / resolution.y;
    
    vec3 lookAt = vec3(0, 1, T * (3.+cos(T*.1)*.09));
    vec3 ro = lookAt + vec3(0, 0, -0.1);
    vec3 lightPos = ro + vec3(0, 0, 4);
    
    lookAt.xy += path(lookAt.z);
    ro.xy += path(ro.z);
    lightPos.xy += path(lightPos.z);

    vec3 forward = normalize(lookAt - ro);
    vec3 right = normalize(vec3(forward.z, 0., -forward.x));
    vec3 up = cross(forward, right);
    vec3 rd = normalize(forward + uv.x * right + uv.y * up);

    float t = rayMarch(ro, rd);

    vec3 col = id < .5 ? fire : blood;
    col *= shadow(ro + t * rd, lightPos); 
    
    col = mix(col, vec3(1, 0, 0), .04/(t / MAX_DIST + .7));
    glFragColor = vec4(col, 1.0);
}

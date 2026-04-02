#version 420

// original https://www.shadertoy.com/view/3ldyD2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define EPS 0.001
#define MAX_DIST 20.

float sdTorus(vec3 pos) {
      return length(vec2(length(pos.xz) - 0.85, pos.y)) - 0.2;  
}

vec3 twistX(vec3 p, float k) {
    float c = cos(k * p.x);
    float s = sin(k * p.x);
    return vec3(mat2(c, -s, s, c) * p.yz, p.x);
}

float calcDist(vec3 pos) {
    float t = time / 1.5;
    float d1 = sdTorus(0.3 * twistX(pos, 2.5 * cos(t)));
    float d2 = sdTorus(0.3 * twistX(pos.yxz, 5.5 * sin(t)));

    float morphK = 2.5;
    return -log(exp(-morphK * d1) + exp(-morphK * d2)) / morphK;
}

float rayMarch(vec3 rayO, vec3 rayD) {
    float distFromO = 0.;
    for (int i = 0; i < 100; ++i) {
        float dS = calcDist(rayO + rayD * distFromO);
        distFromO += dS;
        if (dS < EPS || distFromO > MAX_DIST) break;
    }
    
    return distFromO;
}

vec3 calcNormal(vec3 pos) {
    float d = calcDist(pos);
    return normalize(vec3(d - calcDist(pos - vec3(EPS, 0,  0 )),
                            d - calcDist(pos - vec3( 0, EPS, 0 )),
                             d - calcDist(pos - vec3( 0,  0, EPS))));
}

vec3 calcLight(vec3 fragPos, vec3 lightPos, vec3 lightCol, vec3 camDir) {    
    vec3 normal = calcNormal(fragPos);
    vec3 lightDir = normalize(lightPos - fragPos);
    
    vec3 ambient = vec3(0.13);
    vec3 diffuse = vec3(max(dot(normal, lightDir), 0.0));
    
    return lightCol * (ambient + clamp(diffuse, 0.2, 1.));
}

void main(void) {
    vec2 xy = (gl_FragCoord.xy - resolution.xy / 2.) / min(resolution.x, resolution.y);
    
    vec3 camPos = vec3(0, 0, -10);
    vec3 camDir = normalize(vec3(xy, 1.));
    
    float dist = rayMarch(camPos, camDir);
    
    vec3 col = vec3(0.26, 0.28, 0.3);
    
    if (dist < MAX_DIST) { 
        col = calcLight(camPos + dist * camDir, 
                        vec3(5, 0, -15), 
                        vec3(0.89, 0.95, 1.), 
                        camDir);
    } 
    
    glFragColor = vec4(pow(col, vec3(1.3)), 1.);
}

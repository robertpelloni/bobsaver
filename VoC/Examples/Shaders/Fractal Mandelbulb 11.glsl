#version 420

// original https://www.shadertoy.com/view/MsXcRM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int maxIter = 100;
float df(vec3 p, float power) {
    vec3 z = p;
    float r = 0.0;
    float dr = 1.0;
    for(int i = 0; i < maxIter; i++) {
        r = length(z);
        if(r > 100.0) break;
        
        float theta = acos(z.z/r);
        float phi = atan(z.y, z.x);
        
        dr = power*pow(r, power-1.0)*dr + 1.0;
        
        r = pow(r, power);
        theta *= power;
        phi *= power;
        
        z = r*vec3(sin(theta)*cos(phi), sin(theta)*sin(phi), cos(theta));
        z += p;
    }
    return 0.5*log(r)*r/dr;
}

struct Ray {
    bool hit;
    vec3 hitPos;
    float t;
    int steps;
};
const int maxSteps = 100;
Ray trace(vec3 camPos, vec3 rayDir) {
    vec3 p;
    float t;
    int steps;
    bool hit = false;
    for(int i = 0; i < maxSteps; i++) {
        p = camPos + t*rayDir;
        float d = df(p, 8.0*abs(sin(0.5*time)) + 1.0);
        if(d < 0.001) {
            hit = true;
            steps = i;
            break;
        }
        t += d*0.9;
    }
    return Ray(hit, p, t, steps);
}

vec3 shading(Ray tr) {
    if(tr.hit) {
        return vec3(pow(float(tr.steps)/float(maxSteps), 0.7));
    }
    else {
        return vec3(0);
    }
}

void main(void)
{
    vec2 uv = (2.0*gl_FragCoord.xy - resolution.xy) / resolution.y;
    
    //vec3 camPos = vec3(-2, 0, 0);
    vec3 camPos = 2.0*vec3(cos(time), 0, sin(time));
    vec3 camFront = normalize(-camPos);
    vec3 camUp = vec3(0, 1, 0);
    vec3 camRight = cross(camFront, camUp);
    float focus = 1.0;
    
    vec3 rayDir = normalize(uv.x*camRight + uv.y*camUp + focus*camFront);
    Ray tr = trace(camPos, rayDir);
    
    glFragColor = vec4(shading(tr), 1.0);
}

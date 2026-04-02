#version 420

// original https://www.shadertoy.com/view/fdtSDX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415326

mat2 rotate2D(float r) {
    return mat2(cos(r), sin(r), -sin(r), cos(r));
}

float levelDist(vec3 p, float level) {
    float scale = 1./pow(4., level);
    p = mod(p + scale, scale*2.) - scale;
    p = abs(p);
    return .3*scale - min(max(p.x, p.y), min(max(p.y, p.z), max(p.z, p.x)));
}

float cylinder(vec3 p) {
    return .5-length(p.xy);
}

// Max gives us the intersection of all the surfaces
float maxDist(vec3 p) {
    float dist = 0.;
    for (float i = 0.; i < 4.; i++) {
        dist = max(dist, levelDist(p, i));
    }
    return max(dist, cylinder(p));
}

void main(void) {
    float i;
    float eyeDist, minDist;

    vec3 eyePos = vec3(0, 0, time); // Keep moving forward
    vec3 ray = vec3((gl_FragCoord.xy-.5*resolution.xy)/resolution.x, 1.);
    ray = normalize(ray);
    
    // Camera rotation
//     ray.xz *= rotate2D(PI*time*.2);    

    for(minDist=1.; i<100. && minDist>.001; i++) {  
        // Point to check
        vec3 p = eyePos+eyeDist*ray;
        
        minDist = maxDist(p);
        // Move point forward
        eyeDist += minDist*.5;
    }
    // Fix for banding
    i += 2.*(minDist*1000.-1.);
    glFragColor = vec4(0);
    glFragColor += 400./(i*i);
}

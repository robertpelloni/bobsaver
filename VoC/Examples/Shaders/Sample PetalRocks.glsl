#version 420

// original https://www.shadertoy.com/view/Nd3XDj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415326

mat2 rotate2D(float r){
    return mat2(cos(r), sin(r), -sin(r), cos(r));
}

// Distance of point p to wave #waveNum
float distanceTo(vec3 p, float waveNum) {
    float frequency = exp(waveNum);
    return p.y+(abs(cos(p.x*frequency*PI))+sin(p.z*frequency*PI))/frequency;
}

float minimumDist(vec3 p) {
    float minDist = 1000.;
    // This loop determines the number of waves being vizualized
    for(float j=mod(time, 15.); j > 0.; j--) {
        float curDist = distanceTo(p, j);
        minDist = min(minDist, curDist);
    }
    return minDist;
}

void main(void) {
    float i;
    
    vec2 xy = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    for(float z, minDist = 1.; i<100. && minDist>0.001; i++) {
        // Point to check
        vec3 p = vec3(z*xy, z-1.);
        // Camera motion
        //p.yz *= rotate2D(5.1+cos(time)*.3);
        p.yz *= rotate2D(5.);
        p.xz *= rotate2D(time);
         
        minDist = minimumDist(p);
        // Move point forward
        z += minDist*.2;
    }
    glFragColor = vec4(1.-i/100.);
}


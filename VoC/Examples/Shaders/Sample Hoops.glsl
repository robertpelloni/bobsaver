#version 420

// original https://www.shadertoy.com/view/fstXWl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415326

mat2 rotate2D(float r) {
    return mat2(cos(r), sin(r), -sin(r), cos(r));
}

// Distance of point p to hoop #hoopNum
float distanceTo(vec3 p, float hoopNum) {
    float radius = hoopNum*0.03;
    float height = .01;
    // Account for hoop rotation
    p.xy *= rotate2D(sin(time)*20.*radius+time);
    // SDF for hoop
    return max(abs(p.y), abs(length(p.zx)-radius))-height;
}

// Distance to closest hoop
float minimumDist(vec3 p) {
    float minDist=1.;
    for(float j=1.; j<=10.; j++) { // number of hoops
        float curDist = distanceTo(p, j);
        minDist = min(minDist, curDist); 
    }
    return minDist;
}

void main(void) {
    float i;
    float minDist, eyeDist;

    vec3 eyePos = vec3(0, 0, -1);
    vec3 ray = vec3((gl_FragCoord.xy-.5*resolution.xy)/resolution.x, 1.);
    ray = normalize(ray);

    // Camera motion
    eyePos.yz *= rotate2D(-0.8);
    ray.yz *= rotate2D(-0.8);

    for(minDist=1.; i<100. && minDist>.001; i++) {  
        // Point to check
        vec3 p = eyePos+eyeDist*ray;
        
        minDist = minimumDist(p);
        // Move point forward
        eyeDist += minDist*.5;
    }
    // Adjust color by current distance to surface to fix banding
    i += 2.*(minDist*1000.-1.);
    glFragColor = vec4(0);
    glFragColor += 100./(i*i);
}

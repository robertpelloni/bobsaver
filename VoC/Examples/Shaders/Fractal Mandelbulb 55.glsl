#version 420

// original https://www.shadertoy.com/view/fdB3zt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEP 100
#define MAX_DIST 100.
#define SURFACE_DIST .01
#define PI 3.141592653589793238462643
#define Iterations 6
#define Bailout 10.

float DE(vec3 pos, float time) {
    float Power = cos(time/PI)/2.+3.5;
    vec3 z = pos;
    float dr = 1.0;
    float r = 0.0;
    for (int i = 0; i < Iterations ; i++) {
        r = length(z);
        if (r>Bailout) break;
        
        // convert to polar coordinates
        float theta = acos(z.z/r) * Power;
        float phi = atan(z.y,z.x) * Power;
        dr =  pow( r, Power-1.)*Power*dr + 1.;
        
        // scale and rotate the point
        float zr = pow( r,Power);
        theta = theta*Power;
        phi = phi*Power;
        
        // convert back to cartesian coordinates
        z = zr*vec3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
        z+=pos;
    }
    return 0.5*log(r)*r/dr;
}

vec3 RayMarch(vec3 ro, vec3 rd) {
    float dO = 0.;
    float minDist = MAX_DIST;
    float nbSteps = 0.;
    
    for (int i=0;i<MAX_STEP;i++) {
        nbSteps += 1.;
        vec3 p = ro + rd * dO;
        float dS = DE(p,time);
        dO += dS;
        if (dS<minDist) minDist = dS;
        if (dS<=SURFACE_DIST) minDist = 1.;
        if (i>=MAX_STEP || dS<=SURFACE_DIST ) break;
    }
    return vec3(dO,minDist,nbSteps);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;

    vec3 ro = vec3(1,0,-3.);
    vec3 rd = normalize(vec3(uv.x-0.65, uv.y, 1.));

    vec3 col = vec3(0.);
    
    vec3 RM = RayMarch(ro,rd);
    vec2 dif = vec2(1.-(RM.x/10.), RM.y);

    vec3 glowmap = vec3(0.,0.,pow(1.-dif.y,2.));
    
    vec3 difMap = vec3(dif.x*10.-7.,0.,dif.x*10.-8.);  //MANDELBULB RÉGLAGES
    vec3 ambiantOccl = (1.-vec3(1.-RM.z/15.))*(max(RM.y, .99)-.99)*100.;
    
    col = max(difMap*ambiantOccl*1.5,glowmap);
    //vec3(RM.z/10.)
    glFragColor = vec4(col,1.0);
}

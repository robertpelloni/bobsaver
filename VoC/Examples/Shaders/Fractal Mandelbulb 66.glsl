#version 420

// original https://www.shadertoy.com/view/Nlt3RS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 60
#define MAX_DIST 2.5
#define SURF_DIST .0001

#define ITERATIONS 10
#define BAILOUT 10.

mat2 Rotate(float a) {
  float s = sin(a);
  float c = cos(a);
  return mat2(c, -s, s, c);
}

// http://blog.hvidtfeldts.net/index.php/2011/09/distance-estimated-3d-fractals-v-the-mandelbulb-different-de-approximations/
vec2 DE(vec3 pos) {
    float POWER = 5. +sin(time)*2.;
    vec3 z = pos;
    float dr = 1.0;
    float r = 0.0;
    int i = 0;
    for (i = 0; i < ITERATIONS ; i++) {
        r = length(z);
        if (r>BAILOUT) break;
        
        // convert to polar coordinates
        float theta = acos(z.z/r);
        float phi = atan(z.y,z.x);
        dr =  pow( r, POWER-1.0)*POWER*dr + 1.0;
        
        // scale and rotate the point
        float zr = pow( r,POWER);
        theta = theta*POWER;
        phi = phi*POWER;
        
        // convert back to cartesian coordinates
        z = zr*vec3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
        z+=pos;
    }
    return vec2(0.5*log(r)*r/dr,i);
}

vec2 GetDistance(vec3 point) {
    vec3 p = point;
    p.z -=  1.;
    p.yz *= Rotate(time/2.);
    p.xy *= Rotate(cos(time/5.));
    return DE(p);
}

vec2 RayMarch(vec3 rayOrgin, vec3 rayDirection) {
    float distance=0.;
    vec2 d = vec2(0.);
    
    for(int i=0; i<MAX_STEPS; i++) {
        vec3 point = rayOrgin + rayDirection * distance;
        d = GetDistance(point);
        float surfaceDistance = d.x;
        distance += surfaceDistance;
        // Stop marching if we go too far or we are close enough of surface
        if(distance>MAX_DIST || surfaceDistance<SURF_DIST) break;
    }
    
    return vec2(distance, d.y);
}

void main(void)
{
    // put 0,0 in the center
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
       
    // camera   
    float diff = time/10.;
    vec3 rayOrgin = vec3(0., 0., -1.);
    vec3 rayDirection = normalize(vec3(uv.x, uv.y, 1));

    vec2 data = RayMarch(rayOrgin, rayDirection);
  
    float r = 0.;
    float g = smoothstep(0.1,.5,1.-data.y/10.);
    float b = 1.-data.y/10.;
    
    vec3 col = vec3(r,g,b);
    if (data.x > 2.3) {
        col *= .2;
        col.b = uv.y + .3;
    }
    
    glFragColor = vec4(col,1.0);
}

#version 420

// original https://www.shadertoy.com/view/flGSRV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rot(a)          mat2(cos(a+vec4(0,11,33,0)))  // rotation

void main(void) //WARNING - variables void (out vec4 O, vec2 U) need changing to glFragColor and gl_FragCoord.xy
{
    vec4 O = vec4(0.0);
    vec2 U = gl_FragCoord.xy;

    float t=9.; 
    
    vec3  R = vec3(resolution.xy,1.0), Y = vec3(0,1,0),
          D = normalize(vec3((U+U-R.xy)/R.y, -3.)),   // ray direction
          p = vec3(0,0,25), q,a,                      // marching point along ray 
          M = vec3(10,12,0)/1e2*cos(time+vec3(0,11,0))+vec3(0,.12,0); 

    for ( O=vec4(1); O.x > 0. && t > .005; O-=.01 ) {
        q = p,
        q.yz *= rot(.5-6.3*M.y),                      // rotations
        q.xz *= rot(-6.3*M.x), // t = 9.,
        a = abs(q), 
        q = fract(q)-.5,                              // cells
        t = length(q)-.2,                             // spheres
     // t = min( t, min(length(q.xy),min(length(q.yz),length(q.xz)))-.01), // axis
        t = max( t, max(a.x, max(a.y,a.z))-6. ),      // clamp to cube
     
        p += .4*t*D;                                  // step forward = dist to obj
    }

    glFragColor=O;
}
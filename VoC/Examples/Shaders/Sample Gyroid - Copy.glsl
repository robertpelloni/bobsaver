#version 420

// original https://www.shadertoy.com/view/4stfRX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void) {
    vec2 U = gl_FragCoord.xy;
    vec4 O = glFragColor;
    float t = time,v,d=t;
    mat2  R = mat2( sin(t+vec4(0,33,11,0)) );
    vec3  q = vec3(resolution,1.0),
          D = vec3(.3*(U+U-q.xy)/q.y, -1),              // ray direction
          p = 30./q, a;                                 // marching point along ray 
    O-=O; 
    for ( O++; O.x > 0. && d > .01 ; O-=.015 )
        q = p,
        q.xz *= R, q.yz *= R,                           // rotation
        d = abs( v= dot(sin(q),cos(q.yzx)) ) -.1,       // gyroid
        a = abs(q),
        d = max(d, max(a.x,max(a.y,a.z))-6.),           // clamped to cube
        a = abs(fract(q)-.5),
        d = max(d, max(a.x,max(a.y,a.z))-.5+.05*sin(t) ),
        p += .5*d*D;                                    // step forward = dist to obj
    O *= sign(v)>0. ? vec4(1,.8,.8,1) : vec4(.8,.8,1,1);
    glFragColor=O;
}

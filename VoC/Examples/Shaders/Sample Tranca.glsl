#version 420

// original https://www.shadertoy.com/view/dl2fWK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rot(r) mat2(cos(r), -sin(r), sin(r), cos(r))
#define R resolution.xy
#define PI 3.14
#define T6 2. * PI/ 6.

float curve(vec3 p, float a, float b){    
    vec2 q = cos(
                   p.x * vec2(1, 2) 
                 +  T6 * vec2(a, b)
             
             ) * vec2(7, 3) * .1;
             
    return length(p.zy - q) - .4;
}

float m(vec3 p) {
    p.yz *= rot(4. * time);
    
    float a = curve(p, 0., 1.),
          b = curve(p, 2., 5.),
          c = curve(p, 4., 3.);
    
    //return .7 * a;
    return .7 * min(min(a, b), c);
}

void main(void) {
    vec2 u = gl_FragCoord.xy;
    vec4 O = vec4(0.0);
        
    vec3 p = vec3(0, 0, 12), 
         D = vec3(u = (u + u - R) / R.x, -3) / 3.;
         
    O = vec4(3, 4, 4, 1) * .1;
    
    for(float i, s; i++ < 22.; p += s * D)
        s = m(p),
        s < .01
          ? O = vec4(.8, .2, .0, 0)
                  * (.6 * p.x + 2. * p.z) * length(p) 
          : O;
    
    O *= cos(length(u));
    glFragColor=O;
}
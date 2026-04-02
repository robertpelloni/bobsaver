#version 420

// original https://www.shadertoy.com/view/XlsBRn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// nabr
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// http://glslsandbox.com/e#43610.12

void main(void) {

  
    float t = time*.1;
    
    vec3 ro = vec3(.0, .0, -15.);
    vec3 rd = normalize(vec3((gl_FragCoord.xy * 2. - resolution.xy) / min(resolution.x, resolution.y), 1.));
    
    // ---- rotation 

    float  s = sin(t), c = cos(t);
    mat3 r = mat3(1., 0, 0,0, c, -s,0, s, c) * mat3(c, 0, s,0, 1, 0, -s, 0, c);
    
    // ---- positions 
    vec3  n = vec3(  mod(t,5.)/12.+1.49  );

    // ---- cube length (max(abs(x) - y, 1.) )
    for (int i = 0; i < 8; i++) 
    ro += (length(sin(ro*sin(ro*1.1)*r)-n-cos(2.8077)/atan(ro.z*tan(.7)/120.-exp(.0001*t),-rd.z) )-.9) * rd;

    // ---- shading
    glFragColor.rgb = (vec3(.1, .25, 0.27)  *-ro.z +0.8);
    glFragColor.a = 1.;

}

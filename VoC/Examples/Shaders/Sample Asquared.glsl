#version 420

// original https://www.shadertoy.com/view/dtjBWd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void) {
    vec2 F = gl_FragCoord.xy;
    vec4 O = vec4(0.0);
    
    vec2 r = resolution.xy, u = (F+F-r)/r.y;    
    O.rgb*=0.;
    
    for (float i; i<18.; O.rgb +=
    .003/(abs(length(u+u*u)-i*.04)+.0009)                  
    * (cos(i*vec3(0,1,3))+01.)                           
    * smoothstep(.5,.7, abs(tan((length(mod(time,2.)-i*.1)-1.))))
    ) u*=mat2(sin((time+i++)*.05 + vec4(0,33,11,0)));
    
    glFragColor = O;
}

#version 420

// original https://www.shadertoy.com/view/tsj3Rh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-resolution.xy*.5)/resolution.y;
    uv *= mat2(.71+ (0.145 * time) , -.707 -(0.175 * time), .701+ (0.125 * time), .707+ (0.105 * time)); 
    uv *= 15.;

    vec2 gv = fract(uv)-.5; 
    vec2 id = floor(uv);

    vec4 mc = vec4(0,0,0,0);
    float t;
    for(float y=-1.; y<=-1.; y++) {
        for(float x=-1.; x<=2.; x++) {
            vec2 offs = vec2(x, y);

            t = -time+length(id-offs)* 0.87; 
            float r = mix(.88, 1.75, sin(t)*.45);
              float r2 = mix(.88, 2.05, sin(t + 0.15)*.75); 
            float r3 = mix(.88, 1.05, sin(t + 0.25) *1.95);
            float c = smoothstep(r * 1.7, r * 0.9, length(gv+offs));
            mc.x = mc.x*(1.0-c) + c*(1.-mc.x) * ( r2 );
            mc.y = mc.y*(1.-c) + c*(1.-mc.y)* r;
            mc.z = mc.z*(1.-c) + c*(1.-mc.z) * r3;
            mc.a = mc.a*(1.-c) + c*(1.-mc.a); } } 
        
            mc *= 0.5; 
   
    
    glFragColor = mc; 

}

#version 420

// original https://www.shadertoy.com/view/Wdy3zy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)*200./resolution.y;

    
    vec3 o = vec3(0.,0.,.0);

    vec2 left = uv;
    left.x +=30.;
    
    vec2 right = uv;
    right.x -=30.;
    
    
    float lft_module = length(left);
    float rgt_module = length(right);
    
    vec3 unit = vec3(.6,.2,-.3);
    
    o = unit*sin(lft_module-time*12.)*3.+ 
        unit*sin(rgt_module-time*12.)*3.+1.;
    

    // Output to screen
    glFragColor = vec4(o,1.0);
}

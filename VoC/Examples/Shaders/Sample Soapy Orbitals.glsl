#version 420

// original https://www.shadertoy.com/view/WtVfzt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    float d = length(uv)*5.5;
    
    float c = cos(d)*cos(time);
    float s = sin(d)*sin(time*1.);
    
    mat2 rot = mat2(c,s,s,c);
    
    uv *= rot;
    
    vec2 gv = fract(uv * 5.0)-0.5;
    
    float r = length(gv);

    r = smoothstep(0.5,0.29,r);
    
    vec3 col;
    col.rb = gv;
    //col.rb += uv;
    col += vec3(r);

    // Output to screen
    glFragColor = vec4(col,1.0);
}

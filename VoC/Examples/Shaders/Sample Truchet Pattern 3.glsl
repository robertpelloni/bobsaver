#version 420

// original https://www.shadertoy.com/view/3dK3Dd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float random (vec2 st) {
    highp float a = 12.9898;
    highp float b = 8.233;
    highp float c = 43758.5453;
    highp float dt= dot(st.xy ,vec2(a,b));
    highp float sn= mod(dt,3.14);
    return fract(sin(sn) * c);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    
    uv *= 3.5;
    
    uv = abs(uv + sin(uv)) + time * 0.5;
    vec2 coord = floor(uv);
    
    float rand = random(coord) - 0.51;
    
    vec2 gv = (fract(uv) -.5 );
    vec3 col = vec3(0.);
    
    float width = 0.25;
    
    float d = abs(abs(gv.x + (gv.y * sign(rand))) - 0.5);
    
    float mask = smoothstep(0.01,-0.01,(d-width));
    
    
    col = vec3(1.,.32,0.0) * mask ;
    
    //if(gv.x > 0.48 || gv.y > 0.48) col = vec3(1.,0.,0.);
    glFragColor = vec4(col,1.0);
}

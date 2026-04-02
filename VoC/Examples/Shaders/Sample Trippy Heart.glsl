#version 420

// original https://www.shadertoy.com/view/MltBWM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 p = (2.0*gl_FragCoord.xy-resolution.xy)/min(resolution.y,resolution.x);
    
    // heart shape
    p *= 0.6;
    p.y = -0.1 - p.y*1.2 + abs(p.x)*(1.0-abs(p.x));
    float r = length(p);
    float d = 0.5;

    
    // heart color
    float mX = (sin(time * 0.5) + 1.0) * 0.2;
    float mY = (cos(time * 0.5) + 1.0) * 0.2;
    vec3 hcol = vec3((gl_FragCoord.xy)/(resolution.y),mX);
    for (int i = 0; i < 100; i++){
        hcol.xzy = vec3(1.3,0.999,0.7)*(abs((abs(hcol)/dot(hcol,hcol)-vec3(1.0,1.0,mY))));
    }
    
    // apply one more iteration for background color
    vec3 bcol = vec3(0.0);
    bcol.xzy = vec3(1.3,0.999,0.7)*(abs((abs(hcol)/dot(hcol,hcol)-vec3(1.0,1.0,mY))));
    
    bcol.r *= 0.5;
    hcol.r *= 2.0;
   
    vec3 col = mix( bcol, hcol, smoothstep( -0.15, 0.15, (d-r)) );

    glFragColor = vec4(col,1.0);
}

#version 420

// original https://www.shadertoy.com/view/wtf3z8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415
void main(void)
{
    float time = cos(time*0.1)*12.5-12.5;
    vec2 uv = (gl_FragCoord.xy-resolution.xy*0.5)/resolution.xx;
    float alpha = atan(uv.y, uv.x);
    float r = length(uv);
    alpha += sin(time*0.25)*r*5.0;
    float ra = time*0.075*log(r*200.0);
    
    glFragColor = mix(
        vec4(1.0,1.0,1.0,1.0),
        vec4(1.0-smoothstep(0.2, 1.0, abs(sin(ra*12.0)-sin(alpha*12.0)))),
        r*50.0
    );
   
}

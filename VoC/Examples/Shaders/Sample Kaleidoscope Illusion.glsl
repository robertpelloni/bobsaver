#version 420

// original https://www.shadertoy.com/view/llGcRK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359
#define rot(a) mat2(cos(a + PI*0.25*vec4(0,6,2,0)))

void main(void)
{
    vec2 uv = gl_FragCoord.xy - resolution.xy * 0.5;
    uv /= resolution.y;
    uv *= cos(time*0.5) + 1.5;
    
    glFragColor.rgb = vec3(0);
    
    float scale = PI/3.0;
    float m = 0.5;
    
    for (int i = 0 ; i < 10 ; i++) {
        float scaleFactor = float(i)+(sin(time*0.05) + 1.5);
        uv *= rot(time * scaleFactor * 0.01);
        float theta = atan(uv.x, uv.y)+PI;
        theta = (floor(theta/scale)+0.5)*scale;
        vec2 dir = vec2(sin(theta), cos(theta));
        vec2 codir = dir.yx * vec2(-1, 1);
        uv = vec2(dot(dir, uv), dot(codir, uv));
        uv.xy += vec2(sin(time),cos(time*1.1)) * scaleFactor * 0.035;
        uv = abs(fract(uv+0.5)*2.0-1.0)*0.7;
        vec3 p = vec3(1,5,9);
        glFragColor.rgb += exp(-min(uv.x, uv.y)*16.) * (cos(p*float(i)+time*0.5)*.5+.5)*m ;
        m *= 0.9;
        
    }
    
    
    glFragColor.rgb *= 1.2;
    glFragColor.a = 20.0;
}

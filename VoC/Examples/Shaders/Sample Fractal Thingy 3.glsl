#version 420

// original https://www.shadertoy.com/view/XlXczr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359
#define rot(a) mat2(cos(a + PI*0.25*vec4(0,6,2,0)))

#define SIDES 5

void main(void)
{
    vec2 uv = gl_FragCoord.xy - resolution.xy * 0.5;
    uv /= resolution.y;
    
    //if (mouse*resolution.xy.z > 0.5) {
    //    uv -= (mouse*resolution.xy.zw-mouse*resolution.xy.xy) / resolution.y;
    //}
    
    uv *= 3.0;
    
    glFragColor.rgb = vec3(0);
    
    for (int i = 0 ; i < 7 ; i++) {
        
        float scaleFactor = float(i)+2.0;
        
        // rotation
        uv *= rot(time * scaleFactor * 0.01);
        
        // polar transform
        const float scale = 2.0*PI/float(SIDES);
        float theta = atan(uv.x, uv.y)+PI;
        theta = (floor(theta/scale)+0.5)*scale;
        vec2 dir = vec2(sin(theta), cos(theta));
        vec2 codir = dir.yx * vec2(-1, 1);
        uv = vec2(dot(dir, uv), dot(codir, uv));
        
        // translation
        uv.x -= time * scaleFactor * 0.01;
        
        // repetition
        uv = abs(fract(uv+0.5)*2.0-1.0)*0.7;
        
        // coloration
        glFragColor.rgb += exp(-min(uv.x, uv.y)*10.) * (cos(vec3(2,3,1)*float(i)+time*0.5)*.5+.5);
        
    }
    
    glFragColor.rgb *= 0.4;
    glFragColor.a = 1.0;
}

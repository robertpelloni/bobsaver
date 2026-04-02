#version 420

// original https://www.shadertoy.com/view/Wlyfz1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 triangle_wave(vec2 a,float scale){
    return abs(fract(a*scale)-.5);
}

void main(void)
{
    glFragColor = vec4(0.0);
    vec3 col;  
    float t1 = 2.0;
    float offset = .16;
    float scale2 = 1.05;
    for(int c=0;c<3;c++){
        float scale = 1.5;
        vec2 uv = (gl_FragCoord.xy-resolution.xy)/resolution.y/t1/2.0;
        uv += vec2(time/2.0,time/3.0)/t1/8.0;
        
        
        for(int i=0;i<6;i++)
        {
          
            uv = triangle_wave(uv+offset,scale)+triangle_wave(uv.yx,scale);
            uv = triangle_wave(uv+col.xy,scale);
            uv.y *= -1.0;
            scale /= scale2+col.x;
            offset /= scale2;

        }
     col[c] = fract((uv.x)-(uv.y));
    }
    
    glFragColor = vec4(vec3(col),1.0);
    
}

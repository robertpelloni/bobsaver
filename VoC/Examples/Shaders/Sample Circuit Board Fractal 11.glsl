#version 420

// original https://www.shadertoy.com/view/3lyBWz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//vec3 c1 = vec3(7.0,5.0,1.4); //change this constant to get different patterns!
//vec3 c1 = vec3(7.0,9.0,1.4);
vec3 c1 = vec3(2.0,2.5,1.4); //looks like a maze
//vec3 c1 = vec3(1.7,1.9,1.4);

vec2 triangle_wave(vec2 a,float scale){
    return abs(fract((a+c1.xy)*scale)-.5);
}

void main(void)
{
    glFragColor = vec4(0.0);
    vec3 col;  
    float t1 = 4.0;
    float offset = .16;
    float scale2 = 1.05;
    vec2 uv = (gl_FragCoord.xy-resolution.xy)/resolution.y/t1/2.0;
    uv += vec2(time/2.0,time/3.0)/t1/8.0;
    for(int c=0;c<3;c++){
        float scale = c1.z;
        for(int i=0;i<9;i++)
        {
          
            uv = triangle_wave(uv+offset,scale)+triangle_wave(uv.yx,scale);
            uv = triangle_wave(uv+col.xy,scale);
            scale /= scale2+col.x;
            offset *= scale2;
            uv.y /= -1.0;
            //uv = uv.yx;

        }
     col[c] = fract((uv.x)-(uv.y));
    }
    
    glFragColor = vec4(vec3(col),1.0);
    
}

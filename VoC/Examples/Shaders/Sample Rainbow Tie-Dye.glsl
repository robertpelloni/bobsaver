#version 420

// original https://www.shadertoy.com/view/fds3Wl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//----------------------------------------------------------------------------------------
//  1 out, 1 in...
float hash11(float p)
{
    p = fract(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

//----------------------------------------------------------------------------------------
//  3 out, 1 in...
vec3 hash31(float p)
{
   vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
   p3 += dot(p3, p3.yzx+33.33);
   return fract((p3.xxy+p3.yzz)*p3.zyx); 
}

vec3 c1 = vec3(6.2,6.4,1.1); //change this constant to get different patterns!
//vec3 c1 = vec3(7.2,7.4,1.1);
//vec3 c1 = vec3(8.0,8.2,1.1);
//vec3 c1 = vec3(8.0,9.0,1.1);
//vec3 c1 = vec3(2.0,2.7,1.07); //looks like a carpet
//vec3 c1 = vec3(9.8,10.0,1.1);

vec2 triangle_wave(vec2 a,float scale,vec3 h1){
    
    return abs(fract((a+c1.xy+h1.xy)*scale)-.5);
}

void main(void)
{
    glFragColor = vec4(0.0);
    vec3 col;  
    float t1 = 1.0;
    float offset = .16;
    float scale2 = 1.2;
    vec3 h1 = hash31(floor(time/5.0))*5.0;
    for(int c=0;c<6;c++){
        float scale = c1.z;
        vec2 uv = (gl_FragCoord.xy-resolution.xy)/resolution.y/t1/2.0;
        uv += vec2(time/2.0,time/3.0)/t1/8.0;
        for(int i=0;i<3;i++)
        {          
            uv = triangle_wave(uv+offset,scale,h1);
            uv = triangle_wave(uv+col.xy,scale,h1);
            //scale /= scale2+col.x;
            offset /= scale2;
            uv.y /= -1.0;
            //uv *= scale+offset;
            
        }
     col[c] = fract((uv.x)-(uv.y));
     col = col.yzx;
    }
    
    glFragColor = vec4(vec3(col),1.0);
    
}

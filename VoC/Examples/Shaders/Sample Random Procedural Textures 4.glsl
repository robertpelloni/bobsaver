#version 420

// original https://www.shadertoy.com/view/fdB3zh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 c1 = vec3(6.2,6.4,1.1); //change this constant to get different patterns!
//vec3 c1 = vec3(7.2,7.4,1.1);
//vec3 c1 = vec3(8.0,8.2,1.1);
//vec3 c1 = vec3(8.0,9.0,1.1);
//vec3 c1 = vec3(2.0,2.7,1.07);
//vec3 c1 = vec3(9.8,10.0,1.1);

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

vec2 triangle_wave(vec2 a,float scale,vec3 h1){
    
    return abs(fract((a+c1.xy+h1.xy)*scale)-.5);
}

void main(void)
{
    glFragColor = vec4(0.0);
    vec3 col;  
    float t1 = .5;
    float scale = 1.1;
    //float scale2 = .25;
    vec3 h1 = hash31(floor(time/5.0))*5.0;
    float scale2 = h1.z+.5;
    vec2 uv1 = (gl_FragCoord.xy-resolution.xy)/resolution.y/t1/2.0;
    uv1 += vec2(time/2.0,time/3.0)/t1/8.0; 
    vec2 uv = uv1; 
    for(int c=0;c<6;c++){
        uv = triangle_wave(uv,scale,h1);
        uv = triangle_wave(uv+col.xy,scale,h1);
        //offset /= scale2;
        uv.y /= -1.0;
        uv = uv.yx;
        col[c] = fract((uv.x)-(uv.y));
        col = col.yzx;
    }
    
    glFragColor = vec4(vec3(col),1.0);
    
}

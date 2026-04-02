#version 420

// original https://www.shadertoy.com/view/ftVXzD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//change these constants to get different patterns!
#define c2 0.0

#define c1 vec4(3.0+c2,.5+c2,1.5,0)
//#define c1 vec4(2.0+c2,1.5+c2,1.4,0)
//#define c1 vec4(1.0,1.5,1.4,0)
//#define c1 vec4(7.0,5.0,1.4,0)
//#define c1 vec4(7.0,9.0,1.4,0)
//#define c1 vec4(5.0,5.5,1.4,0)

//----------------------------------------------------------------------------------------
//  3 out, 1 in...
vec3 hash31(float p)
{
    //from David Hoskin's "Hash without sine"
   vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
   p3 += dot(p3, p3.yzx+33.33);
   return fract((p3.xxy+p3.yzz)*p3.zyx); 
}

vec2 triangle_wave(vec2 a,float scale){
    return abs(fract((a+c1.xy)*scale)-.5);
}

void main(void)
{
    glFragColor = vec4(0.0);
    
    

    
    vec3 col;  
    float t1 = 4.5*4.;

    vec2 uv = (gl_FragCoord.xy-resolution.xy)/resolution.y/t1/2.0;
    uv += vec2(time/2.0,time/3.0)/t1/8.0;
    //vec3 random1 = hash31(floor((time)/10.0+uv.x))*10.*.0;
    //vec3 random2 = hash31(1.+floor((time)/10.0+uv.x));
    float t2 = floor((time/2.+uv.x)/10.0)/t1;
    //vec3 random1 = (hash31(3.+t2)-.5)/12.;
    //vec3 random2 = (hash31(4.+t2)-.5)/12.;
    //vec3 random3 = (hash31(3.+t2)-vec3(.5))/1.5;
    //vec3 random4 = (hash31(4.+t2)-vec3(.5))/4.;
    
    float offset = .5;
    float scale2 = 1.5;
    float bend = 1.;
    for(int c=0;c<1;c++){
        float scale = c1.z;
        //float scale1 = 1.0;
        for(int i=0;i<9;i++)
        {
            vec2 t2 = vec2(0);
            for(int k = 0; k < 3; k++){    
                uv /= -scale2;
                uv -= t2.yx/(scale);
                t2 = triangle_wave(uv.yx-offset,scale);
                vec2 t3 = triangle_wave(uv,scale);
                uv.yx = t2+t3;
 

            }
            offset += .5/scale;
            scale /= 1.+(scale2)*col.x/(8.);
            scale2 -= (col.x-1.)/(4.);

            col[c] = abs((uv.x)-(uv.y)+col.x);
            col = col.yzx;
            //random2 = col - random2;
            

        }
    }
    
    glFragColor = vec4(vec3(col),1.0);
    
}

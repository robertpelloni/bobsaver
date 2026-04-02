#version 420

// original https://www.shadertoy.com/view/stc3zS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//change these constants to get different patterns!
#define c2 2.

#define c1 vec4(-c2,sign(c2)*.5+c2,1.5,0)
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
    float t1 = 4.5/2.;

    vec2 uv = (gl_FragCoord.xy-resolution.xy)/resolution.y/t1/2.0;
    uv += vec2(time/2.0,time/3.0)/t1/8.0;
    float t2 = +floor((time)/10.0+uv.x);
    vec3 random1 = (hash31(t2)-vec3(.5))/4.;
    vec3 random2 = (hash31(1.+t2)-vec3(.5))/4.;
    vec3 random3 = (hash31(2.+t2)-vec3(.5))/4.;
    vec3 random4 = (hash31(3.+t2)-vec3(.5))/4.;
    vec3 random5 = (hash31(4.+t2)-vec3(.5))/2.-.25;
    vec3 random6 = (hash31(5.+t2)-vec3(.5))/2.-.25;
    
    float offset = .5;
    for(int c=0;c<3;c++){
        float scale = c1.z;
        for(int i=0;i<3;i++)
        {
            float factor = -1.25;
            float l1 = col.x;
            
            uv = triangle_wave(uv.yx+l1+offset,scale)+triangle_wave(uv,scale);
            uv.x *= factor;
            
            //l1 *= 1. - uv.x/2.;

            for(int k = 0; k < 3; k++){
                //int k1 = k%3;
                uv = triangle_wave((uv+uv.yx*vec2(random1[k],random2[k])-l1+offset)/(random4[k]+1.),scale+random3[k]);
                //l1 *= 1. - uv.x/2.;
                uv.x /= factor;
                uv /= 1.+1./(8.);

                //uv *= 1.-random5[k]/8.;
                //uv.yx *= 1. + vec2(random5[k])*col.yx;
        
            }

            scale *= 1./(1.+l1);

            //scale2 *= 2. - l1;

            col = col.yxz;
            col[c] = fract((uv.x)-(uv.y));

        }
    }
    
    glFragColor = vec4(vec3(col),1.0);
    
}

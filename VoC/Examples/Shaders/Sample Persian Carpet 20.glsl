#version 420

// original https://www.shadertoy.com/view/7lc3W2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//change this constant to get different patterns!
#define c2 0.

#define c1 vec4(3.+c2,2.5+c2,1.5,0)
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
    float t1 = 4.5/4.;

    vec2 uv = (gl_FragCoord.xy-resolution.xy)/resolution.y/t1/2.0;
    uv += vec2(time/2.0,time/3.0)/t1/8.0;
    //vec3 random1 = hash31(floor((time)/10.0+uv.x))*10.*.0;
    //vec3 random2 = hash31(1.+floor((time)/10.0+uv.x));
    float t2 = floor((time/2.+uv.x)/10.0);
    vec3 random1 = (hash31(2.+t2)-.5)/8.;
    vec3 random2 = (hash31(3.+t2)-.5)/8.;
    vec3 random3 = (hash31(4.+t2))/8.;
    vec3 random4 = (hash31(5.+t2))/8.;
    
    float offset = .5;
    float scale2 = 1.5;
    for(int c=0;c<3;c++){
        for(int i=0;i<3;i++)
        {
            for(int k = 0; k < 3; k++){       
                uv += vec2(random1[k],random2[k]);
                uv /= -scale2;

                uv = triangle_wave(uv-offset,scale2)*(1.+random3[k])+triangle_wave(uv.yx,scale2)*(1.+random4[k])-col.yx;
                //uv = -triangle_wave(uv-offset,scale2)*(1.-random4[k])+triangle_wave(uv.yx,scale2)*(1.-random3[k])-col.yx;

            }
            //random1 *= scale2;
            //random2 *= scale2;
            col[c] = abs((uv.x)-(uv.y));
            //col[c] = (uv.y-uv.x+col[c]);

        }
    }
    
    //col /= 1.5;
    glFragColor = vec4(min(col,vec3(1.)),1.0);
    
}

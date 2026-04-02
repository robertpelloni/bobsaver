#version 420

// original https://www.shadertoy.com/view/7st3DH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//change these constants to get different patterns!
#define c2 0.0

#define c1 vec4(3.0+c2,2.5+c2,1.5,0)
//#define c1 vec4(2.0+c2,1.5+c2,1.4,0)
//#define c1 vec4(1.0,1.5,1.4,0)
//#define c1 vec4(7.0,5.0,1.4,0)
//#define c1 vec4(7.0,9.0,1.4,0)
//#define c1 vec4(5.0,5.5,1.4,0)

//to do: drag and drop using https://www.shadertoy.com/view/WdGGWh

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
    float t1 = 4.5*3./2.;

    vec2 uv = (gl_FragCoord.xy-resolution.xy)/resolution.y/t1/2.0;
    uv += vec2(time/2.0,time/3.0)/t1/8.0;
    //vec3 random1 = hash31(floor((time)/10.0+uv.x))*10.*.0;
    float t2 = floor((time+4.)/20.0+uv.x);
    vec3 random2 = hash31(1.+t2);
    
    
    float offset = .25;
    float scale2 = 1.+random2.x;
    for(int c=0;c<3;c++){
        float scale = c1.z;
        float scale1 = 1.0;
        //vec3 col_prev = 0.0;
        for(int i=0;i<3;i++)
        {
            vec3 col_prev = col;
            
            uv = triangle_wave(uv.yx+1.5,scale)+triangle_wave(uv,scale);
            uv.x *= -1.1;

            uv = triangle_wave((uv+offset),scale);
            uv.x /= -1.1;
            
            uv = triangle_wave(uv+offset,scale);
            uv.x *= -1.1;
            
            uv = triangle_wave((uv+offset),scale);
            uv.x /= -1.1;
            
            //uv.x *= -1.0;
            //uv = triangle_wave(uv+c1.y,scale);
            scale /= 1.+scale2*col.x;
            //offset *= scale2/(1.+random4.x);
            
            //uv = -uv.yx;
            //uv = uv.yx;
            scale2 += col.x/8.;
            if(i>0) col = (col.yzx*random2.x + col_prev*random2.y)/(random2.x+random2.y);
            col[c] = fract((uv.x)-(uv.y));

            

        }
            float t3 = float(c+1)+t2;
            random2 = hash31(1.+t3);
            //random3 = (hash31(2.+t3)-vec3(.5))/4.;
            //random4 = (hash31(3.+t3)-vec3(.5))/4.;
    }
    
    glFragColor = vec4(vec3(col),1.0);
    
}

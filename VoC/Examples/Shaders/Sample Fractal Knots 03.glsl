#version 420

// original https://www.shadertoy.com/view/NssBDS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//change these constants to get different patterns!
#define c1 vec3(1.,0.5,1.5)

vec2 triangle_wave(vec2 a,float scale){
    return abs(fract((a+c1.xy)*scale)-.5);
    //return abs(fract((a+c1.xy)*scale+time/500.)-.5); //morphing
}

void main(void)
{
    glFragColor = vec4(0.0);
    vec3 col = vec3(0.);
    float t1 = 8.;
    vec2 uv = (gl_FragCoord.xy-resolution.xy)/resolution.y/t1/2.0;
    uv += vec2(time/2.0,time/3.0)/t1/8.0;
    float scale = c1.z;
    float offset = 0.;
    //float offset1 = time/1000.;
    vec2 t2 = vec2(0.);
        vec2 t3 = vec2(0.);   
        for(int k = 0; k < 18; k++){
        //float scale = scale + col.x/8.;
        //float scale = scale-col.x/16.;
            //float scale = scale + col.x/16.;

            //uv /= -scale-col.x;
            
            //uv -= offset + (t2.yx)/(1.+(col.x+col.y+col.z)/3.);
            uv -= offset + (t2.yx)/(scale);

            //uv += time/1000.-(t2.yx)/(scale);

            
            //uv -= (t2.yx)/(scale+t3);
            //uv -= (t2.yx)/(scale+col.x);
            t2 = triangle_wave(uv.yx-.5,scale);
            //t2 = triangle_wave(uv.yx+.5+float(i),scale);
            
            t3 = -triangle_wave(uv,scale);
            
            uv.yx = -(t2+t3)/scale;
            //offset += offset1;
            //offset += time/400.+ col.x/(scale-col.x);
        col.x = 1.-abs(-uv.y+uv.x+col.x);
        col = col.yzx;
        
        uv /= scale*scale;
      }
    glFragColor = vec4(col,1.0);   
}

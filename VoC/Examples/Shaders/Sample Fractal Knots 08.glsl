#version 420

// original https://www.shadertoy.com/view/7dSfWK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//change these constants to get different patterns!
#define c1 vec3(1.,0.5,1.5)

vec2 triangle_wave(vec2 a,float scale){
    //a = -a;
    return abs(fract((a+c1.xy)*scale)-.5);
    //return abs(fract((a+c1.xy)*scale+time/500.)-.5); //morphing
}

void main(void)
{
    glFragColor = vec4(0.0);
    vec3 col = vec3(0.);
    float t1 = 36.*16.;
    vec2 uv = (gl_FragCoord.xy)/resolution.y/t1/2.0;
    uv += vec2(time/2.0,time/3.0)/t1/8.0;
    float scale = c1.z;
    float offset = 0.;
    float offset1 = time/1000.;
    for(int i=0;i<12;i++)
    {
        vec2 t2 = vec2(0.);
        vec2 t3 = vec2(0.);
        //float scale = scale+col.x/16.;
        for(int k = 0; k < 3; k++){
            
            //uv /= -scale-col.x;
            uv += (t2.yx);
            uv /= -scale*scale;
            
            //uv -= offset + (t2.yx)/(scale+length(col));
            
            //uv -= (t2.yx)/(scale+t3);
            //uv -= (t2.yx)/(scale+col.x);
            vec2 temp = t2;
            t2 = triangle_wave(uv.yx-.5,scale);
            //t2 = triangle_wave(uv.yx-.5+float(i),scale);
            
            t3 = triangle_wave(uv,scale);
            
            uv.yx = (t2-t3)/scale;
            uv += uv/scale;
            //t2 /= (1.-temp);
            //offset -= col.x/16.;
            //offset += offset1;
        }
        //offset += .5/scale;
        col.x = abs(uv.y+uv.x-col.x);
        //col.x = abs(uv.y-abs(uv.x-col.x));
        //col.x = abs(abs(col.x-uv.y)+uv.x/2.);
        //col.x = abs(abs(col.x-uv.x)+uv.y/2.);
        //col.x = abs(abs(uv.y-uv.x)-col.x/2.);

        col = col.yzx;
        //scale *= 1.0+col.x/16.;
    }
    glFragColor = vec4(col,1.0);   
}

#version 420

// original https://www.shadertoy.com/view/NlGSRt

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
    float t1 = 36.*2.;
    vec2 uv = (gl_FragCoord.xy-resolution.xy)/resolution.y/t1/2.0;
    uv += vec2(time/2.0,time/3.0)/t1/8.0;
    float scale = c1.z;
    float offset = 0.;
    for(int i=0;i<9;i++)
    {
        vec2 t2 = vec2(0.);
        vec2 t3 = vec2(0.);
        for(int k = 0; k < 3; k++){
            //float scale = scale + col.x/16.;

            //uv /= -scale-col.x;
            uv /= -scale;
            uv -= offset + (t2.yx)/(scale);
            //uv -= offset + col.x/4. + (t2.yx)/(scale);
            //uv += time/1000.-(t2.yx)/(scale);

            
            //uv -= (t2.yx)/(scale+t3);
            //uv -= (t2.yx)/(scale+col.x);
            t2 = triangle_wave(uv.yx-.5,scale);
            
            t3 = triangle_wave(uv,scale);
            
            uv.yx = (t2+t3)/scale;

        }
        //offset += .5/scale;
        col.x = abs(uv.y+uv.x-col.x);
        col = col.yzx;
    }
    glFragColor = vec4(col,1.0);   
}

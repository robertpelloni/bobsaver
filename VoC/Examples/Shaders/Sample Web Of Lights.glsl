#version 420

// original https://www.shadertoy.com/view/7syyDR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define c1 vec3(1.,0.5,1.5)

vec2 triangle_wave(vec2 a,float scale){
    return abs(fract((a+c1.xy)*scale)-.5);
}

void main(void)
{
    glFragColor = vec4(0.0);
    vec3 col = vec3(0.);
    float t1 = 8.;
    vec2 uv = (gl_FragCoord.xy)/resolution.y/t1/2.0;
    uv += vec2(time/2.0,time/3.0)/t1/8.0;
    float scale = c1.z;
    float offset = 0.;
    float offset1 = time/1000.;
    for(int i=0;i<6;i++)
    {
        vec2 t2 = vec2(0.);
        vec2 t3 = vec2(0.);
        for(int k = 0; k < 2; k++){
            uv += 1.+(t2.yx);
            t2 = triangle_wave(uv.yx-.5,scale);
            
            //float num = 4.;
            //t2.x += floor((fract(uv.x)*num))/num;
            
            t3 = triangle_wave(uv,scale);
            //t3 *= -1.; //makes a star pattern
            uv.yx = (t2-t3)/(scale);
        }
        col.x = min(((uv.y-uv.x)+col.x),col.x)/sqrt(2.);
        col = (col+vec3(col.x))/sqrt(2.);
    }
    glFragColor = vec4(-vec3(col),1.0);
}

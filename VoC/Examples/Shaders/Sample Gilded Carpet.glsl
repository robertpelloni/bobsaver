#version 420

// original https://www.shadertoy.com/view/NlsyDr

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
    uv += (time+8.)/vec2(2.0,3.0)/t1/8.0;
    float scale = c1.z;
    vec2 t2 = vec2(0.);
    vec2 t3 = vec2(0.);
    for(int k = 0; k < 18; k++){
        vec2 uv1 = uv;
        uv -= (t2.yx);
        t2 = triangle_wave(uv.yx+.5,scale)/2.;
        t3 = triangle_wave(uv,scale);      
        uv.yx = t3-t2*1.5;
        col.x = max((uv.x-uv.y),col.x);
        col = abs(col.yzx-vec3(col.x*(2.)));
        uv /= scale*scale;
        
        //this makes a flower pattern
        //uv += float(k%3)/2.;
        
        //another carpet pattern
        //uv *= 2. - float(k%3);
        
        //another carpet pattern
        //uv /= .5 + float(k%3)/2.;

    }
    glFragColor = vec4(abs(col),1.0);   
}

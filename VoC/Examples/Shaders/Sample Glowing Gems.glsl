#version 420

// original https://www.shadertoy.com/view/stXcWS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define c1 vec3(1.,0.5,1.5)

vec2 triangle_wave(vec2 a,float scale){
    return abs(fract((a+c1.xy)*scale)-.5);
}

float triangle_wave(float a){
    return abs(fract(a)-.5);
}

void main(void)
{
    glFragColor = vec4(0.0);
    vec3 col = vec3(0.);
    float t1 = 2.;
    vec2 uv = (gl_FragCoord.xy)/resolution.y/t1/2.0;
    uv += (time+8.)/vec2(2.0,3.0)/t1/12.0;
    float scale = c1.z;
    vec2 t2 = vec2(0.);
    vec2 t3 = vec2(0.);
    //float s1 = 1.;
    for(int k = 0; k < 12; k++){
        vec2 uv1 = uv;
        uv -= (t2.yx);
        t2 = triangle_wave(uv.yx+.5,scale).yx/2.;
        t3 = triangle_wave(uv,scale).yx;      
        uv.yx = t3-t2/3.;
        //uv.y *= sign(uv.x);
        float m1 = uv.x;
        
        
        //More interesting patterns here:
        //float m1 = (uv.y-uv.x)/(1.-t2.x);
        //float m1 = (uv.y+uv.x)/2./(1.-t2.x);

        //float m1 = uv.x-uv.y;
        //float m1 = uv.y-uv.x;
        //float m1 = uv.x*float(k%2)+uv.y*float((k+1)%2);
        
        col.x = max(m1,col.x);
        col = abs(col.yzx-vec3(col.x*(2.125+.125*4.*triangle_wave((uv.x)*16.+time*4.)/8.-t2.y)));
        uv /= 1.25;
        //uv -= float(k%3)/2.;
        //uv -= float(k%3+5)/2.;

        
        //if(k>3) uv.x += time/s1/4.;
        //s1 *= scale;
        //uv /= 1.+normalize(t2).x/3.;
    }
    glFragColor = vec4(col,1.0);   
}

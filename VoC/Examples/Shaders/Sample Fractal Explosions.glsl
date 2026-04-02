#version 420

// original https://www.shadertoy.com/view/NdlfDS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 triangle_wave(vec2 a,float scale){
    return abs(fract((a)*scale)-.5);
}

void main(void)
{
    glFragColor = vec4(0.0);
    vec3 col = vec3(0.);
    float t1 = 1.;
    vec2 uv = (gl_FragCoord.xy-resolution.xy)/resolution.y/t1/2.0;
    //uv += vec2(time/2.0,time/3.0)/t1/8.0;
    float scale = 1.5;

    vec2 t2 = vec2(0.);
    vec2 t3 = vec2(0.);
        for(int k = 0; k < 12; k++){

            uv -= (t2.yx)/(scale);

            t2 = triangle_wave(uv.yx,scale);

            t3 = triangle_wave(uv-time/10.,scale);
            
            uv.yx = (t2+t3)/scale;

        col.x = abs(uv.y-uv.x+col.x);
        col = col.yzx;
        uv *= scale;

        }
    glFragColor = vec4(col,1.0);   
}

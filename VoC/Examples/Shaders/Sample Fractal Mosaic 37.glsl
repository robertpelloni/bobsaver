#version 420

// original https://www.shadertoy.com/view/dtjGRc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 triangle_wave(vec2 a){
    vec2 a2 =
        vec2(1.,.5)
    ,
    a1 = a+a2;
    return abs(fract((a1)*(a2.x+a2.y))-.5);
}

void main(void)
{
    vec3 col = vec3(0.);
    float t1 = 1.;
    vec2 uv = (gl_FragCoord.xy)/resolution.y/t1/2.0;
    uv.x += time/t1/12.0;
    float scale = 1.5;
    vec2 t2 = vec2(0.);
    for(int k = 0; k < 9; k++){
        vec2 uv1 = uv;
        uv = (uv+t2)/scale;
        t2 = triangle_wave(uv+.5);
        uv = fract(t2+triangle_wave(uv.yx)+.5);
        col.x =
            max(max((t2.y+t2.x*sign(uv.x)),abs(uv.y+uv.x))/6.,col.x)
        ;
        col =
            max(abs(col-1.+col.x),col/3.);
            //max((col-1.+col.x/1.5),(1.-col-col.yzx));
    }
    glFragColor = vec4(col,1.0);
}

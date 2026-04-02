#version 420

// original https://www.shadertoy.com/view/sdKBRc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 triangle_wave(vec2 a){
    return abs(fract((a+vec2(1.,0.5))*1.5)-.5);
}

void main(void)
{
    glFragColor = vec4(0.0);
    vec3 col = vec3(0.);
    float t1 = 4.*1.5;
    vec2 uv = (gl_FragCoord.xy)/resolution.y/t1/2.0 + vec2(time/2.0,time/3.0)/t1/16.0;
    vec2 t2 = vec2(0.);
    for(int k = 0; k < 9; k++){
        float p1 = sign(uv.x);
        t2 *= (1.+p1)/2.;
        uv = (uv+t2)/1.5;
        t2 = -p1*triangle_wave(uv-.5);
        uv = t2-p1*triangle_wave(uv.yx);
        vec2 uv1 = uv+triangle_wave(uv.yx+time/4.)/4.;
        col.x = min(p1*(uv1.y-uv1.x),col.x)+col.x;
        col = abs(col.yzx-vec3(col.x)/(3.));
    }
    glFragColor = vec4(col*3.,1.0);
}

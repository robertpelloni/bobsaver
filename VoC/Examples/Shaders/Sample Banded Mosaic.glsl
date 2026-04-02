#version 420

// original https://www.shadertoy.com/view/NtXyWs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define c1 vec3(1.,0.5,1.5)

vec2 rotate(vec2 v, float a) {
    float s = sin(a);
    float c = cos(a);
    mat2 m = mat2(c, -s, s, c);
    return m * v;
}

vec2 triangle_wave(vec2 a,float scale,float num){
    //a = rotate(a,num*radians(180.));
    return abs(fract((a+c1.xy)*scale)-.5);
}

void main(void)
{
    glFragColor = vec4(0.0);
    vec3 col = vec3(0.);
    float t1 = 36.;
    vec2 uv = (gl_FragCoord.xy)/resolution.y/t1/2.0;
    uv += vec2(time/2.0,time/3.0)/t1/8.0;
    float scale = c1.z;
    float offset = 0.;
    float offset1 = time/1000.;
    float p1 = 1.;
        vec2 t2 = vec2(0.);
        vec2 t3 = vec2(0.);
        for(int k = 0; k < 12; k++){
            //uv += ceil(uv.x)/2.;
            uv += t2;
            uv /= scale;
            //uv -= ceil(t2.x*t2.y+5.)/4.; //mosaic pattern

            //uv += vec2(1.); //this also makes an interesting pattern
            t2 = -p1*triangle_wave(uv-.5,scale,floor(uv.y)/2.);
            t3 = p1*triangle_wave(uv.yx,scale,floor(uv.y)/2.);
            uv = t2-t3;
            p1 *= -1.;
            col.x = max(uv.y+uv.x-col.x,col.x*2.25);
            col = abs(col.yzx-vec3(1.5-col.x))/2.;
        }

    glFragColor = vec4(col*2.,1.0);
}

#version 420

// original https://www.shadertoy.com/view/Nl2yDD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 rotate(vec2 v, float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c)*v;
}

vec2 triangle_wave(vec2 a,float num,int iters){
    a = rotate(a,num*radians(180.));
    vec2 to_return = abs(fract((a+vec2(1.,0.5))*1.5)-.5);
    return to_return/1.5;
    //return to_return/(1.5+(iters > 0?1.:0.)*(a.x+a.y)/4.);
}

void main(void)
{
    glFragColor = vec4(0.0);
    vec3 col = vec3(0.);
    float t1 = 8.;
    vec2 uv = (gl_FragCoord.xy)/resolution.y/t1/2.0;
    float time1 = time/64.;
    uv += vec2(time1/2.0,time1/3.0)/t1/4.0+(vec2(cos(time1),sin(time1)))*8./t1;
    float scale = 1.5;
    float p1 = 1.;
    vec2 t2 = vec2(0.);
    vec2 t3 = vec2(0.);
    float rotation_number = 0.;
    for(int k = 0; k < 12; k++){
        rotation_number = float(int(uv.x+uv.y)+1+k)/2.;
        //rotation_number += float(int(uv.x+uv.y)+1+k)*.5;

        uv += t2;
        t2 = -p1*triangle_wave(uv-.5,rotation_number,k);
        t3 = p1*triangle_wave(uv.yx,rotation_number,k);
        uv = t2-t3;
        p1 *= -1.;
        float multiplier = 1.25;
        col.x = max(uv.y+uv.x-col.x,col.x);
        //col.x = max(((uv.y+uv.x)-col.x)/multiplier,col.x*multiplier);
        //col.x = max(uv.y*(1.25)+uv.x/(1.25)-col.x,col.x);
        //col.x = max(uv.y+uv.x-col.x,col.x*multiplier)/multiplier;

        col = abs(col.yzx-vec3(1.-col.x))/multiplier;
        uv /= scale;
    }
    glFragColor = vec4(col*2.,1.0);
}

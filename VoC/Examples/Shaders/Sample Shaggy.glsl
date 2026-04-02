#version 420

// original https://neort.io/art/br0cm0k3p9f48fkiug3g

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

const float pi = 3.14159265;
const float pi2 = pi * 2.;

//BPM
float bpm = time * (30. / 60.);
                           //bpm

mat2 rot(float a){
    float c = cos(a);
    float s = sin(a);
    return mat2(c, s, -s, c);
}

//イージング
//https://scrapbox.io/sayachang/%E3%82%A4%E3%83%BC%E3%82%B8%E3%83%B3%E3%82%B0
float ease_out_bounce(float x, float t, float b, float c, float d) {
    if ((t/=d) < (1./2.75)) {
        return c*(7.5625*t*t) + b;
    } else if (t < (2./2.75)) {
        return c*(7.5625*(t-=(1.5/2.75))*t + .75) + b;
    } else if (t < (2.5/2.75)) {
        return c*(7.5625*(t-=(2.25/2.75))*t + .9375) + b;
    } else {
        return c*(7.5625*(t-=(2.625/2.75))*t + .984375) + b;
    }
}

float ease_out_bounce(float x){
    return ease_out_bounce(x, x, 0., 1., 1.);
}

float ease_in_bounce(float x, float t, float b, float c, float d) {
    return c - ease_out_bounce (x, d-t, 0., c, d) + b;
}

float ease_in_bounce(float x){
    return ease_in_bounce(x, x, 0., 1., 1.);
}

// pSFold by gaz https://www.shadertoy.com/view/WdfcWr
vec2 pSFold(vec2 p,float n)
{
    float h=floor(log2(n)),a =6.2831*exp2(h)/n;
    for(float i=0.; i<3.; i++)
    {
         vec2 v = vec2(-cos(a),sin(a));
        float rp = (pi / 3.) * .5;
        float halfpi = pi /2.;
        float mixtime = clamp(acos(cos(time * .5 + halfpi)) - halfpi, -rp, rp) + rp;
        float g= dot(p,v * mixtime);
         p-= (g - sqrt(g * g + 5e-3))*v ;
         a*=0.5;
    }
    return p;
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    
    //円の描画用
    vec2 circleuv = uv;
    
    uv = pSFold(uv, 24. * ((sin(time) +1.)) * .5 + 0.5);
    uv = uv * rot(time * .1);
    
    float t = time * 1.;
    float a = .7;    //振幅
    float f = 2.;     //周波数
    
    vec3 mcol = vec3(0, 0, 0);
    
    float rp = (pi / 3.) * .5;
        float halfpi = pi /2.;
    float mixtime = clamp(acos(cos(time * .5 + halfpi)) - halfpi, -rp, rp) + rp;
    uv = uv * ((mixtime * 1.) + .3);
    
    for (float j = .001; j < 12.; j++)
    {
    
    for (float i = .001; i <24.; i++)
    {
        float wave = (a / i) * j * sin(uv.x * f - t * 0.2 * i) + j * .002;
        float wave1 = (a / i) * j * sin(uv.x * f - t * 0.2 * i - (0.012 * sin(t))) + j * .002;

        float beamx = i * 0.0002 / abs(uv.y + wave1);
        float beamy = i * 0.00022 / abs(uv.y + wave); 
        float beamz = i * 0.00023 / abs(uv.y + wave);
        
        //rainbow
        float rt = j * .9 * (ease_out_bounce(fract(time * .1)) + .2) + 3.* sin(time * .4);
        
        float rx = (sin(rt) +1.) * .5;
        float ry = (sin(rt - 2.) + 1.) * .5;
        float rz = (sin(rt - 4.) + 1.) * 0.5;
        vec3 rainbow = vec3(rx, ry, rz);
        
        //float grad = (sin(j * .8 + 1.5) + 1.) * .5;
        float grad = j * .03;

        vec3 mixcol = vec3(beamx, beamy, beamz) * (ease_in_bounce(fract(time)) + .6);
        mcol = mcol + mixcol * rainbow * grad;
    }

        
    }
        
    vec3 col = vec3(mcol.x, mcol.y, mcol.z);
    
    //ガンマ補正
    float gamma = 0.7;
    col.x = pow(col.x, gamma);
    col.y = pow(col.y, gamma);
    col.z = pow(col.z, gamma);
    
    //ビネット
    float vig = abs(uv.y);
    vig = pow(vig + 0.0, 0.9) ;
    vig = 1.- clamp(0., 1., vig) * .1;
    
    col = col * vig;
    
    
    //blur
    vec2 backuv = gl_FragCoord.xy / resolution.xy;
    vec4 texR = texture2D(backbuffer, vec2(backuv.x + 0.002, backuv.y + 0.01 * sin(time)));
    vec4 texG = texture2D(backbuffer, vec2(backuv.x, backuv.y));
    vec4 texB = texture2D(backbuffer, vec2(backuv.x - 0.005, backuv.y - 0.002));
    vec4 tex = vec4(texR.r, texG.r, texB.r, 1.0);
    

    
    //ブラーのかかる部分をcircleで指定した部分だけにする
    //circle
    float r = distance(circleuv, vec2(0.0, 0.0));
    float c = smoothstep(0.0, 2.0, r);
    vec3 ccol = 1. - vec3(c);
    tex *= vec4(ccol, 1)  + 0.5;
    
    col = mix((col + tex.rgb* .1), col, ((sin(time) + 1.) *.5)) ;

    glFragColor = vec4(col, 1.0);
}

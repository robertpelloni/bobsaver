#version 420

// original https://neort.io/art/bpsgsnk3p9fefb924jk0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

const float pi = 3.14159265;
const float pi2 = pi * 2.;

mat2 rot(float a){
    float c = cos(a);
    float s = sin(a);
    return mat2(c, s, -s, c);
}

vec2 pmod(vec2 p, float r){
    float a = atan(p.x, p.y) + pi / r;
    float n = pi2 / r;
    a = floor(a / n) * n;
    return p * rot(-a);
}

//のこぎり波
float saw(float a) {
    return a - floor(a);
}

//イージング
float ease_in_expo(float x) {
    float t=x; float b=0.; float c=1.; float d=1.;
    return (t==0.) ? b : c * pow(2., 10. * (t/d - 1.)) + b;
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);

    //ビーム用uv
    vec2 buv = uv * 0.24;
    
    //タイル
    //buv = fract(buv * 8.) - vec2(0.5);
    
    //BPM
    float bpm = 10. * 0.5; //originally 120 and not 10, but 10 is more "anmbient"
    
    //回転
    buv = rot(time * 0.1 * pi) * buv;
    //pmod
    buv = pmod(buv, 2. + (floor(sin(time * (bpm / 30.)) + 1.0) * 1.0));
    
    //fog用UV
    vec2 foguv = buv;
    //beamcol2用UV
    vec2 buv2 = buv;
    
    
    //uvオフセット調整
    buv.y += 0.002;
    buv.x -= -1.2;
    
    buv2.y += 0.002;
    buv2.x -= 0.5;
    
    
    //スクロール
    buv.x = buv.x + 22.0 * (ease_in_expo(saw(time * (bpm / 60.))) - 0.5);
    buv2.x = buv2.x + 22.0 * (ease_in_expo(saw(time * (bpm / 60.) + 0.5)) - 0.5);
    
    float beam = 0.;
    float beamGrad = 0.;
    vec3 beamcol = vec3(0.);
    vec3 bcol = vec3(0.);
    
    float beam2 = 0.;
    float beamGrad2 = 0.;
    vec3 beamcol2 = vec3(0.);
    vec3 bcol2 = vec3(0.);
    
    vec2 fuv = vec2(buv.x, -buv.y);
    
    for (float i = 0.; i <13.; i++)
    {
        //beamcol1
        fuv = vec2(buv.x,-buv.y);
        fuv.y = fuv.y + (abs(pow(1.1, - i * 5.))) * 0.4;
        fuv.x = fuv.x + 0.9 * i;
        
        beam = 0.001 / abs(fuv.y);
        beamGrad = 1. - smoothstep(0.3, 1.0, abs(fuv.x));
        
        beam = pow(beam * beamGrad, 1./ 2.2);        
        bcol = vec3(0.8 + (sin(time) +1.0) * 0.5, 0.9, 0.8) * beam;
        beamcol += bcol;
        
        
        //beamcol2
        vec2 fuv2 = vec2(buv2.x, -buv2.y);
        fuv2.y = fuv2.y + (abs(pow(1.1, - i * 5.))) * 0.4;
        fuv2.x = fuv2.x + 0.9 * i;
        beam2 = 0.003 / abs(fuv2.y);
        beamGrad2 = 1. - smoothstep(0.3, 1.0, abs(fuv2.x));
        
        beam2 = pow(beam2 * beamGrad2, 1. / 2.2);
        bcol2 = vec3(0.2 + 0.9 * abs(sin(time)), 1.0, 1.3 + (sin(time) +1.0) * 0.5) * beam2 ;
        beamcol2 += bcol2;
    }

    //mix
    beamcol += beamcol2;
    
    //blur
    vec2 backuv = gl_FragCoord.xy / resolution.xy;
    vec4 texR = texture2D(backbuffer,  backuv - vec2(0.002));
    vec4 texG = texture2D(backbuffer, vec2(backuv.x, backuv.y));
    vec4 texB = texture2D(backbuffer, backuv + vec2(0.002));
    vec3 blur = vec3(texR.r, texG.r, texB.r);
    
    vec3 col = (beamcol + blur * 1.3) / 1.4;
    
    //fog
    float fog = smoothstep(0.0, 0.7, foguv.y) + 0.01;
    fog = pow(fog,  0.2);
    
    col = col * vec3(fog);
    

    glFragColor = vec4(col, 1.0);
}

#version 420

// original https://www.shadertoy.com/view/lssBD2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// 2017 created by soma_arc
// This shader is based on Kleinian limit set-Maskit slice by Jos Leys
// https://www.shadertoy.com/view/MtKXRh

// from Syntopia http://blog.hvidtfeldts.net/index.php/2015/01/path-tracing-3d-fractals/
vec2 rand2n(vec2 co, float sampleIndex) {
    vec2 seed = co * (sampleIndex + 1.0);
    seed+=vec2(-1,1);
    // implementation based on: lumina.sourceforge.net/Tutorials/Noise.html
    return vec2(fract(sin(dot(seed.xy ,vec2(12.9898,78.233))) * 43758.5453),
                fract(cos(dot(seed.xy ,vec2(4.898,7.23))) * 23421.631));
}

const float GAMMA_COEFF = 2.2;
const float DISPLAY_GAMMA_COEFF = 1. / GAMMA_COEFF;
vec3 gammaCorrect(vec3 rgb) {
  return vec3((min(pow(rgb.r, DISPLAY_GAMMA_COEFF), 1.)),
              (min(pow(rgb.g, DISPLAY_GAMMA_COEFF), 1.)),
              (min(pow(rgb.b, DISPLAY_GAMMA_COEFF), 1.)));
}

vec3 degamma(vec3 rgb) {
  return vec3((min(pow(rgb.r, GAMMA_COEFF), 1.)),
              (min(pow(rgb.g, GAMMA_COEFF), 1.)),
              (min(pow(rgb.b, GAMMA_COEFF), 1.)));
}

float lineY(vec2 pos, vec2 uv){
    return uv.x * .5 + sign(uv.y * .5) * (2.*uv.x-1.95)/4. * sign(pos.x + uv.y * 0.5)* (1. - exp(-(7.2-(1.95-uv.x)*15.)* abs(pos.x + uv.y * 0.5)));
}

vec2 TransA(vec2 z, vec2 uv){
    float iR = 1. / dot(z, z);
    z *= -iR;
    z.x = -uv.y - z.x; z.y = uv.x + z.y;
    return z;
}

vec2 TransAInv(vec2 z, vec2 uv){
    float iR = 1. / dot(z + vec2(uv.y,-uv.x), z + vec2(uv.y, -uv.x));
    z.x += uv.y; z.y = uv.x - z.y; 
    z *= iR;
    return z;
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 computeColor(float n){
    return hsv2rgb(vec3(.3 +0.06 * n, 1., .7));
}

vec3 computeColor2(float n) {
    if(n == 0.) return vec3(0);
    return hsv2rgb(vec3(0. + 0.05 * (n -1.), 1.0, 1.0));
}

const int LOOP_NUM = 200;
vec3 josKleinianIIS(vec2 pos, vec2 uv, float translation){
    float loopNum = 0.;
    vec2 lz = pos + vec2(1.);
    vec2 llz = pos + vec2(-1.);

    for(int i = 0 ; i < LOOP_NUM ; i++){
        // translate
        pos.x += translation/2. + (uv.y * pos.y) / uv.x;
        pos.x = mod(pos.x, translation);
        pos.x -= translation/2. + (uv.y * pos.y) / uv.x;

        // rotate 180
        if (pos.y >= lineY(pos, uv.xy)){
            // pos -= vec2(-uv.y, uv.x) * .5;
            // pos = - pos;
            // pos += vec2(-uv.y, uv.x) * .5;
            // |
            pos = vec2(-uv.y, uv.x) - pos;
            //loopNum++;
        }

        pos = TransA(pos, uv);

        if(uv.x < pos.y) {
            pos.y -= uv.x;
            pos.y *= -1.;
            pos.y += uv.x;
            loopNum++;
        }
        if(pos.y <= 0.){
            pos.y *= -1.;
            loopNum++;
        }

        // 2-cycle
        if(dot(pos-llz,pos-llz) < 1e-6) return computeColor2(loopNum);

        llz=lz; lz=pos;
    }
    return vec3(0);
}

const float PI = 3.141592;
const float SAMPLE_NUM = 10.;
void main(void) {
    vec3 sum = vec3(0);
    float ratio = resolution.x / resolution.y / 2.0;
    
    float n = 1.;
    float k = 2. * cos(PI / n); // default value is k = 2
    for(float i = 0. ; i < SAMPLE_NUM ; i++){
        vec2 position = ( (gl_FragCoord.xy + (rand2n(gl_FragCoord.xy, i))) / resolution.yy ) - vec2(ratio, 0.5);
        position = position * 2.;
        position.y += .99;
//        position.x += 1.86 - mod(time, 2.);
        
        sum += josKleinianIIS(position, 
                           vec2(2. - .29*abs(sin(time)), 0.31*(sin(time))), 
                           k);

    }
    glFragColor = vec4(gammaCorrect(sum/SAMPLE_NUM), 1.);
}

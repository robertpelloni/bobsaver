#version 420

// original https://www.shadertoy.com/view/tttfDn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/////////////////////
//Version using sdf//
/////////////////////
#if 1
//Thanks iq for the 2d sdf!
float sdHexagon( in vec2 p, in float r ) {
    p = p.yx;
    const vec3 k = vec3(-0.866025404,0.5,0.577350269);
    p = abs(p);
    p -= 2.0*min(dot(k.xy,p),0.0)*k.xy;
    p -= vec2(clamp(p.x, -k.z*r, k.z*r), r);
    return length(p)*sign(p.y);
}

float sdBox( in vec2 p, in vec2 b ) {
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

float sdThreeHexagon(vec2 p, float r) {
    return min(sdHexagon(p-vec2(0.0, 0.5*sqrt(3.)), r),
           min(sdHexagon(p-vec2(0.5, 0.0), r),
               sdHexagon(p-vec2(0.5, (2.+3./7.)/sqrt(3.)), r)));
}

vec2 carpet_shining(vec2 uv, float blur) {
    float modulus = (2.+3./7.)/sqrt(3.);
    uv.x = abs(fract(uv.x+0.5)-0.5);
    uv.y = mod(uv.y, modulus);
    float sdSmallHex = sdThreeHexagon(uv, 1./7.);
    float sd = max(sdThreeHexagon(uv, 2./7.), -sdSmallHex);
    sd = max(sdThreeHexagon(uv, 3./7.), -sd);
    float sdb = min(sdBox(uv-vec2(0.0, 1.25), vec2(0.5/7., 0.15)),
                    sdBox(uv-vec2(0.5, 1.0), vec2(0.5/7., 0.15)));
    sd = max(sd, -sdb);
    return vec2(smoothstep(blur, -blur, sd), sdSmallHex < 0.1);
}

//////////////////////////////////
//Version using hexagonal tiling//
//////////////////////////////////
#else

#define ANTIALIAS 1

vec2 carpet_shining(vec2 uv, float blur) {
    uv = uv.yx;
    vec2 off = vec2(sqrt(3.), 1.);
    float modulus = (2.+3./7.)/sqrt(3.);
    int id = int(floor(uv.x/modulus));
    uv.y = abs(fract(uv.y+0.5)-0.5);
    uv.x = mod(uv.x, modulus);
    uv.x += 2./sqrt(3.);
    if(dot(vec2(uv.x, -abs(uv.y)), normalize(off)) < 1.) {
        uv.x += modulus;
        id += 1;
    }
    vec2 uv1 = mod(uv, off)-off/2.;
    vec2 uv2 = mod(uv+off/2., off)-off/2.;
    vec2 nuv = (length(uv1) < length(uv2)) ? uv1 : uv2;
    float d = max(abs(nuv.y), dot(abs(nuv), normalize(off)));
    float N = 3.5;
#if ANTIALIAS == 1
    // There is still a little glitch on the connexion with the adjacent tiling :(
    // (Hopefully we have to zoom in to see it!)
    float b = smoothstep(0.5/N+blur, 0.5/N     , mod(d, 1./N))
            * smoothstep(0.5/N     , 0.5/N-blur, mod(d, 1./N))
            * smoothstep(0., blur, mod(d, 1./N))
            * smoothstep(1./N, 1./N-blur, mod(d, 1./N));
    if(uv.x < (2.+4./7.)/sqrt(3.) && uv.y < 0.6/7.) {
        b = 0.;
    }
    if(uv.x < (2.+3.5/7.)/sqrt(3.)) {
        float s = smoothstep(0.5/7.+blur, 0.5/7.     , uv.y)
                + smoothstep(1.5/7.-blur, 1.5/7.     , uv.y);
        b = 1.-s*(1.-b);
    }
    if(d < 0.25/9.) b = 1.;
#else
    bool b = mod(d, 1./N) < 0.5/N;
    b = b && !(uv.x < (2.+4./7.)/sqrt(3.) && uv.y < 0.5/7.);
    b = b ||  (uv.x < (2.+3.5/7.)/sqrt(3.) && 0.5/7. < uv.y && uv.y < 1.5/7.);
#endif
    bool ii = d < 1.5/7.;
    
    return vec2(b, ii);
}

#endif

const vec3 red = vec3(161., 28., 31.)/255.;
const vec3 orange = vec3(225., 99., 40.)/255.;
const vec3 brown = vec3(71., 38., 31.)/255.;

void main(void) {
    vec2 uv = gl_FragCoord.xy/resolution.y;
    uv *= 5.;
    uv.y += time/4.;
    float pixelSize = 5./resolution.y;
    
    vec2 res = carpet_shining(uv, 1.5*pixelSize/2.);
    float b = res.x;
    float ii = res.y;
    vec3 col = mix(brown, mix(orange, red, ii), b);
    glFragColor = vec4(col,1.0);
}

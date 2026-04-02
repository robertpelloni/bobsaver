#version 420

// original https://www.shadertoy.com/view/WlcSD7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// https://creativecommons.org/licenses/by-sa/4.0/
// by Denis H.

#define PI 3.14159
#define TWO_PI 6.28318

// Perlin Noise from https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83
float rand(vec2 c){
    return fract(sin(dot(c.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float noise(vec2 p, float freq ){
    float unit = 1./freq;
    vec2 ij = floor(p/unit);
    vec2 xy = mod(p,unit)/unit;
    xy = .5*(1.-cos(PI*xy));
    float a = rand((ij+vec2(0.,0.)));
    float b = rand((ij+vec2(1.,0.)));
    float c = rand((ij+vec2(0.,1.)));
    float d = rand((ij+vec2(1.,1.)));
    float x1 = mix(a, b, xy.x);
    float x2 = mix(c, d, xy.x);
    return mix(x1, x2, xy.y);
}

float pNoise(vec2 p, int res){
    float persistance = .5;
    float n = 0.;
    float normK = 0.;
    float f = 4.;
    float amp = 1.;
    int iCount = 0;
    for (int i = 0; i<50; i++){
        n+=amp*noise(p, f);
        f*=2.;
        normK+=amp;
        amp*=persistance;
        if (iCount == res) break;
        iCount++;
    }
    float nf = n/normK;
    return nf*nf*nf*nf;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec2 st = vec2(atan(uv.x, uv.y), length(uv));
    uv = vec2(.5+st.x/TWO_PI, st.y);

    float t = time*2., x, y, m;
    float n = pNoise(vec2((cos(uv.x * TWO_PI) + 1.), (sin(uv.y * TWO_PI) + 1.) )+time/9., 10);
    vec3 col;
    
    for(int i = 0; i < 3; i++) {
        x = uv.x + n * .1;
        y = uv.y + n * .09 + sin(uv.x * TWO_PI * 10. + t) * .05;
        x *= 20.;
        m = min(fract(x), fract(1.-x));
        col[i] = smoothstep(0., .1, .25 + m * .3 - y);
        t+= 1.;
    }
    
    glFragColor = vec4(col,1.0);
}

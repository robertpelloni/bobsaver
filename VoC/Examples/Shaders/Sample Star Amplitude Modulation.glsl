#version 420

// original https://www.shadertoy.com/view/wsVyzw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float zoom = 3.;
const float lineWeight = 4.3;
const bool invertColors = true;
const float sharpness = 0.2;

const float StarRotationSpeed = -.5;
const float StarSize = 1.8;
const int StarPoints = 3;
const float StarWeight = 3.4;

const float waveSpacing = .3;
const float waveAmp = .4;
const float waveFreq = 25.;
const float phaseSpeed = .33;

const float waveAmpOffset = .01; // just a little tweaky correction

mat2 rot2D(float r){
    return mat2(cos(r), sin(r), -sin(r), cos(r));
}

// signed distance to a n-star polygon with external angle en
float sdStar(in vec2 p, in float r, in int n, in float m) // m=[2,n]
{
    // these 4 lines can be precomputed for a given shape
    float an = 3.141593/float(n);
    float en = 3.141593/m;
    vec2  acs = vec2(cos(an),sin(an));
    vec2  ecs = vec2(cos(en),sin(en)); // ecs=vec2(0,1) and simplify, for regular polygon,

    // reduce to first sector
    float bn = mod(atan(p.x,p.y),2.0*an) - an;
    p = length(p)*vec2(cos(bn),abs(sin(bn)));

    // line sdf
    p -= r*acs;
    p += ecs*clamp( -dot(p,ecs), 0.0, r*acs.y/ecs.y);
    return length(p)*sign(p.x);
}
float sdShape(vec2 uv) {
    uv *= rot2D(-time*StarRotationSpeed);
    return sdStar(uv, StarSize, StarPoints, StarWeight);
}

// https://www.shadertoy.com/view/3t23WG
// Distance to y(x) = a + b*cos(cx+d)
float udCos( in vec2 p, in float a, in float b, in float c, in float d )
{
    // convert all data to a primitive cosine wave
    p = c*(p-vec2(d,a));
    
    // reduce to principal half cycle
    const float TPI = 6.28318530718;
    p.x = mod( p.x, TPI); if( p.x>(0.5*TPI) ) p.x = TPI - p.x;

    // find zero of derivative (minimize distance)
    float xa = 0.0, xb = TPI;
    for( int i=0; i<7; i++ ) // bisection, 7 bits more or less
    {
        float x = 0.5*(xa+xb);
        float si = sin(x);
        float co = cos(x);
        float y = x-p.x+b*c*si*(p.y-b*c*co);
        if( y<0.0 ) xa = x; else xb = x;
    }
    float x = 0.5*(xa+xb);
    for( int i=0; i<4; i++ ) // newtown-raphson, 28 bits more or less
    {
        float si = sin(x);
        float co = cos(x);
        float  f = x - p.x + b*c*(p.y*si - b*c*si*co);
        float df = 1.0     + b*c*(p.y*co - b*c*(2.0*co*co-1.0));
        x = x - f/df;
    }
    
    // compute distance    
    vec2 q = vec2(x,b*c*cos(x));
    return length(p-q)/c;
}

vec3 dtoa(float d, in vec3 amount){
    return 1. / clamp(d*amount, amount/amount, amount);
}

// 4 out, 1 in...
vec4 hash41(float p)
{
    vec4 p4 = fract(vec4(p) * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy+33.33);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);
}
void main(void)
{
    vec2 C = gl_FragCoord.xy;
    vec4 o = glFragColor;

    vec2 R = resolution.xy;
    vec2 N2 = C/R;
    vec2 N = C/R-.5;
    vec2 uv = N;
    uv.x *= R.x/R.y;
    float t = time * phaseSpeed;
    
    uv *= zoom;

    float a2 = 1e5;
    vec2 uvsq = uv;
    float a = sdShape(uvsq);
    vec2 uv2 = uv;

    uv.y = mod(uv.y, waveSpacing) - waveSpacing*.5;
    
    for (float i = -3.; i <= 3.; ++ i) { // necessary to handle overlapping lines. if your lines don't overlap, may not be necessary.
        vec2 uvwave = vec2(uv2.x, uv.y + i * waveSpacing);
        float b = (smoothstep(1., -1.,a)*waveAmp)+ waveAmpOffset;
        float c = waveFreq;
        a2 = min(a2, udCos(uvwave, 0., b, c, t));// a + b*cos(cx+d)
    }
    
    vec3 tint = vec3(1.,.5,.4);
    float sh = mix(100., 1000., sharpness);
    o.rgb = dtoa(mix(a2, a-lineWeight + 4., .03), sh*tint);
    if (!invertColors)
        o = 1.-o;
    o *= 1.-dot(N,N*2.);
    o = clamp(o,vec4(0),vec4(1));

    glFragColor = o;
}


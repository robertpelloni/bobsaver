#version 420

// original https://www.shadertoy.com/view/dtcGWS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))
#define T time
#define saturate(x) clamp(x, 0., 1.)

const float PI=3.1415926536;
const float TAU=PI*2.;
const float eps=1e-6;
const float DEG2RAD = PI/180.;
const float LT = 20.;

vec2 pmod(vec2 p, float n)
{
    float a = mod(atan(p.y, p.x),TAU / n) - .5 * TAU / n;
    return length(p) * vec2(sin(a), cos(a));
}

float opu(float d1, float d2) { return min(d1, d2); }

float ops(float d1, float d2) { return max(-d1, d2); }

vec2 path(float t)
{
    return vec2(sin(t), cos(t))*.1;
}

float exp2Fog(float d, float density)
{
    float dd = d * density;
    return exp(-dd * dd);
}

float triangle(vec2 p) {
    p.x /= sqrt(3.);
    float d1 = abs(fract(p.x + p.y + .5) - .5);
    float d2 = abs(fract(p.x - p.y + .5) - .5);
    float d3 = abs(fract(p.x * 2. + .5) - .5);
    return min(min(d1, d2), d3) * sqrt(3.) * .5;
}

float map(vec3 p)
{
    vec3 pp = p;
    pp.xy *= rot(DEG2RAD*30.);
    pp.xy += vec2(.3, .5);    //offset
    pp.z = mod(pp.z, .5) - .25;
    
    float d;
    
    float triBase=abs(triangle(pp.xy))-.05;
    float d0=abs(pp.z)-.13;
    
    float triIn=triangle(pp.xy)-.08;
    float d1=abs(pp.z)-.03;
    d = opu(max(triIn, d1), max(triBase,d0));
    
    return d;
}

vec3 makeN(vec3 p)
{
    vec2 eps = vec2(.0001, 0.);
    return normalize(vec3(map(p+eps.xyy)-map(p-eps.xyy),
                          map(p+eps.yxy)-map(p-eps.yxy),
                          map(p+eps.yyx)-map(p-eps.yyx)));
}

void main(void)
{
    vec2 uv=(2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    float zfac = ((1.0-dot(uv, uv))*.1 + 1.);
    float dist, hit, i = 0.;
    vec3 cPos = vec3(0., 0., T*1.3);
    vec3 lookAt = cPos + vec3(0., 0., .5);
    cPos.xy += path(cPos.z) * 3.7;
    lookAt.xy += path(lookAt.z) * 2.5;
    float fov = PI/3.5;
    vec3 forward = normalize(lookAt - cPos);
    vec3 right = normalize(vec3(forward.z, 0., -forward.x));
    vec3 up = cross(forward, right);
    vec3 ray = forward*zfac + fov*uv.x*right + fov*uv.y*up;
    ray = normalize(ray);
    vec3 L = normalize(vec3(1.)*vec3(sin(T), cos(T), 1.));
    vec3 col=vec3(0);
    float t=mod(T, LT);
    
    for(;i<128.;i++)
    {
        vec3 rp = cPos + ray * hit;
        rp.xy += -path(rp.z)*4.5;
        dist = map(rp);
        hit += dist;
        
        if(dist < eps)
        {
            vec3 N=makeN(rp);
            float diff = dot(N,L) * .5 + .5;
            diff += .5;
            float spec = pow(saturate(dot(reflect(L, N), ray)), 100.0);

            col = vec3(.3);
            if(mod(rp.z-(.25-.13)-(.13-.031), 1.5) < .03*2.) col = vec3(1., .656, .238);
            col = col * diff + spec;
        }
    }
    
    float ft = 10.; // fadeTime
    if(t<1.3) col *= abs(2. * fract((T*LT)* .5 - .25) - 1.); // flicker
    if((mod(t-8., LT) < 8.)) col *= 1.-1./(1.+exp(6.-mod(T-8.,LT)*ft)); // fadeout
    if((mod(t-16., LT) < 1.)) col *= 1./(1.+exp(6.-mod(T-16.,LT)*ft)); // fadein
    
    // fog
    vec3 fogCol = vec3(1., 1., 1.);
    float fp = .36; // fogPower
    float fog = exp2Fog(hit, fp);
    col = mix(fogCol, col, fog);
    
    glFragColor = vec4(col,1.);
}

#version 420

// original https://www.shadertoy.com/view/wsKGDc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_ITER 1000.
#define R 100.
#define S(a,b,c) smoothstep(a,b,c)

//conversion helper
float f(float n, vec3 hsl){
    float k = mod(n+hsl.x*12., 12.);
    float a = hsl.y*min(hsl.z, 1.-hsl.z);
    return hsl.z-a*max(min(k-3., min(9.-k, 1.)),-1.);
}
// hsl in range <0, 1>^3
vec3 hsl2rgb(vec3 hsl){
    return vec3(f(0.,hsl), f(8.,hsl), f(4.,hsl));
}

vec3 hue2rgb(float hue){
    return hsl2rgb(vec3(hue, 1., .5));
}

vec2 Rain(vec2 uv, float t){
    t*= 40.;
    vec2 aspect = vec2(3.,1.);
    vec2 st = uv*aspect;
    
    vec2 id = floor(st);
    st.y+=t*.22;
    float n = fract(sin(id.x*256.45)*85.);
    st.y += n;
    uv.y += n;
    id = floor(st);
    st = fract(st)-.5;
    
    t+= fract(sin(id.x*56.45+id.y*485.)*155.)*6.28;
    
    float y = -sin(t+sin(t+.5*sin(t)))*0.43;
    float x = (fract(sin(id.x*384.45)*id.y*288.)-.5)*.6;
    vec2 p1 = vec2(x, y);
    vec2 o1 = (st-p1)/aspect;
    float d = length(o1);
    
    float m1 = S(.07, .0, d);
    
    vec2 o2 = (fract(uv*aspect.x*vec2(1.,2.)-vec2(p1.x,0.))-.5)/vec2(1.,2.);
    d = length(o2);
    
    float m2 = S(0.2*(.5-st.y), .0, d) * S(-.1, .1, st.y-p1.y);
    
    //if(st.x>.46 || st.y>.49) m1 = 1.;
    
    return vec2(m1*o1*30.+m2*o2*10.);
}

vec3 julia(float zx, float zy, float cx, float cy){
    float iter = 0.;
    while(zx * zx + zy * zy < R*R && iter<MAX_ITER){
        float xtemp = zx*zx - zy*zy;
        zy = 2. * zx * zy + cy;
        zx = xtemp + cx;
        
        iter+=1.;
    }
    /*if(iter>=MAX_ITER)
        return vec3(1,1,0);*/
    float dist = length(vec2(zx,zy));
    float fracIter = log2(log(dist) / log(R)) - 1.;
    iter -= fracIter;
    return hue2rgb(sqrt(iter/10.));
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec2 m = mouse*resolution.xy.xy/resolution.xy;
    m-=.5;
    m*=2.;
    uv*=2.;
    float t = time;
    t*=.7;
    //vec3 col = julia(uv.x, uv.y, m.x, m.y);
    vec2 rain = Rain(uv*2., t*.13);
    rain += Rain(uv*3., t*.15) * .25;
    uv -= rain * 0.35;
    vec3 col = julia(uv.x, uv.y, .7*cos(t), .7*sin(t));
    glFragColor = vec4(col, 1.0);
}

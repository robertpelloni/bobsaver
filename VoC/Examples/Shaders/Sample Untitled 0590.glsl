#version 420

// original https://www.shadertoy.com/view/Wl3czn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float df;
float rep = 2.75;
float sz;

#define pi acos(-1.)

#define pump(g,a) (floor(g) + pow(fract(g),a))
#define xor(a,b,c) min(max(a,-(b)), max(-(a) + c,b))

mat2 rot(float angle){
    return mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
}

float sdCirc (vec2 uv, float s){
    return length(uv) - s;
}

float sdRect (vec2 uv, vec2 s){
    uv = abs(uv)- s;
    return max(uv.x,uv.y);
}
float sdRect (vec2 uv, float s){
    uv = abs(uv)- s;
    return max(uv.x,uv.y);
}
float sdCube (vec3 uv, float s){
    
    uv = abs(uv)- s;
    uv.xz *= rot(0.);
    return max(uv.x,max(uv.y,uv.z));
}

float sdSphere(vec3 p, float s){return length(p) -s;}

float get(vec2 uv, vec2 id, float T){
    
    T *= 0.1;
    #define m (sin(length(id/sz)*0.2 + T*11.)*0.5)

    vec3 p = vec3(uv,0.1 + m*0.1);
    p.x += m;
    
    
    p.yz *= rot(-pi*(0.25 + pow(m,2.)*0.));
    p.xy *= rot(pi*0.25);

    float dc = sdCube (p,sz*(0.1 + mouse.x*resolution.xy.x/resolution.x*0.05 + pow(m,2.)*0.4)*2.);
    
    float d = abs(dc - 0.1*(1.-m));
    //d = abs(d);
    return d;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-resolution.xy*0.5)/resolution.y;
    vec2 guv = uv;
    uv *= 5.  ;
    df = dFdx(uv.x);
    sz = 1./rep;
    
    vec3 col = vec3(0);    
    vec2 id = floor(uv*rep);
    
    uv = mod(uv,sz) - sz*0.5;
    float d = 10e6;
    #define pal(a,b,c,d,e) (a + (b)*sin((c)*(d) + (e)))
     
    float chrabs = 9.;
    for(float chrab = 0.; chrab < chrabs; chrab++){
        float overstep = 3.*2.*1.;
        float nd = 10e5;
        for(float i = 0.; i < overstep*overstep; i++){
            vec2 idx = vec2(
                mod( i,overstep)  - 0.5*overstep , 
                floor( (i)/overstep) - 0.5*overstep
                );
            nd = min(nd, get(uv - idx*sz, id + idx, time - 0.4*chrab/chrabs) - 0.04*chrab/chrabs);

        }
        
        nd = max(nd,-d);
        vec3 c = pal(.5,0.5,vec3(3,2,1. + sin(time)),1. ,41. + 6.*chrab/chrabs + time + length(guv)*0.4);
        col = mix(col,c*(1.4-chrab/chrabs*1.64),smoothstep(df,0.,nd ));
        
    
    }
    col = smoothstep(0.,1.,col*2.);
    col = pow(col,vec3(0.45454));
    
    glFragColor = vec4(col,1.0);
}

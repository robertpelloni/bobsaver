#version 420

// original https://www.shadertoy.com/view/dtt3R8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Using code from

//Morgan McGuire for the noise function
// https://www.shadertoy.com/view/4dS3Wd

// TDM for the getSkyColor function
// https://www.shadertoy.com/view/Ms2SD1

#define time time
#define depth 40.0
#define fogSize 25.0
#define seuil 4.0
#define steps 200.0
float fogCoef=1.0/(depth-fogSize);

float PI=acos(-1.0);

float random (in float x) {
    return fract(sin(x)*1e4);
}

float noise(in vec3 p) {
    const vec3 step = vec3(110.0, 241.0, 171.0);

    vec3 i = floor(p);
    vec3 f = fract(p);

    // For performance, compute the base input to a
    // 1D random from the integer part of the
    // argument and the incremental change to the
    // 1D based on the 3D -> 1D wrapping
    float n = dot(i, step);

    vec3 u = f * f * (3.0 - 2.0 * f);
    return mix( mix(mix(random(n + dot(step, vec3(0,0,0))),
    random(n + dot(step, vec3(1,0,0))),
    u.x),
    mix(random(n + dot(step, vec3(0,1,0))),
    random(n + dot(step, vec3(1,1,0))),
    u.x),
    u.y),
    mix(mix(random(n + dot(step, vec3(0,0,1))),
    random(n + dot(step, vec3(1,0,1))),
    u.x),
    mix(random(n + dot(step, vec3(0,1,1))),
    random(n + dot(step, vec3(1,1,1))),
    u.x),
    u.y),
    u.z);
}

mat2 rot(float a) {
    float ca=cos(a);
    float sa=sin(a);
    return mat2(ca,sa,-sa,ca);
}

float water(in vec3 p, vec3 centerPos, float scale,float radius ) {
    vec3 truc = vec3(p.x+sin(length(p*0.2)+time)*2.0,p.y+sin(length(p*0.2))*2.0,0.0);
    float coef = length(truc)-4.0;

    float c=1.0;
    float n1=1.0;
        
    float d=1.0;
    for(int i=0; i<8; ++i) {
        n1+=2.0/c*abs(noise((p*c-time*0.5*c*d)*scale));
        c*=2.0;
        d+=1.5;
    }

    return n1*coef;

}

float mapHyper(vec3 p){
    return water(p,vec3(0,0,0),0.3,0.1);
}  

vec3 tunnel(vec3 p){
    vec3 off=vec3(0);
    off.x += sin(p.z*0.2)*1.5;
    off.y += sin(p.z*0.3)*1.3;
    return off;
}

vec3 getSkyColor(vec3 e) {
    e.y = (e.y);
    e.y = max(e.y,0.0);
    return vec3(pow(1.0-e.y,2.0), 1.0-e.y, 0.6+(1.0-e.y)*0.4)*noise(e);
}

void main(void)
{
    
    
    vec2 uv = vec2(gl_FragCoord.xy.x / resolution.x, gl_FragCoord.xy.y / resolution.y);
    uv -= 0.5;
    uv /= vec2(resolution.y / resolution.x, 1);
    vec3 s=vec3(-1.0,-1.0,-3);
    float t2=(time*1.5);
    s.xz *= rot(sin(t2)*0.015);
    vec3 t=vec3(0,0,0);
    s -= tunnel(s);
    t -= tunnel(t);
    s.x += cos(t2*0.2)*1.0*sin(time*0.01);
    s.y += sin(t2*0.2)*1.0*sin(time*0.01+10.0);
    vec3 cz=normalize(t-s);
    vec3 cx=normalize(cross(cz,vec3(0,1,0)));
    vec3 cy=normalize(cross(cz,cx));
    vec3 r=normalize(uv.x*cx+uv.y*cy+cz*0.7);
    vec3 p=s;
    float c= 0.0;
    
    for(int i=0; i<int(steps); ++i) 
    {
        float mH;
        mH = mapHyper(p);
        c +=mH;    
        if(c>seuil)break;
        p+=r*(mH-seuil)*0.09;
    }
    
    vec3 col=vec3(0);
    float fresnel;
    vec3 reflected;
    
    vec2 off=vec2(0.05,0.0);
    vec3 zVect = vec3(0.0,0.0,1.0);
    vec3 n=normalize(mapHyper(p)-vec3(mapHyper(p-off.xyy), mapHyper(p-off.yxy), mapHyper(p-off.yyx)));
    col = mix(vec3(0.2,0.3,0.4),vec3(0.1,0.365,0.441),(abs(1.0+dot(n,s)*pow(dot(zVect,r),5.0))));
    fresnel = clamp(1.0- dot(n,s), 0.05, 0.75);
    reflected = getSkyColor(abs(reflect(r,n)));
    col = mix(col,reflected,(fresnel*reflected.x));
 
    float fog =  clamp((length(p-s)-fogSize)*fogCoef,0.0,1.0);
    col = mix(col,vec3(0.85,0.85,0.85),fog);
    glFragColor = vec4(col,1.0);
}

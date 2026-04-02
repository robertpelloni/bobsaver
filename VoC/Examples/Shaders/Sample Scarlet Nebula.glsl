#version 420

// original https://www.shadertoy.com/view/slXcRl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 bg(vec3 n){
    return vec3(10.f*n.y-9.5f,10.f*n.y-9.5f,10.f*n.y-9.5f);
}
vec3 rotx(vec3 p, float a){
    float s = sin(a);
    float c = cos(a);
    return(vec3(p.x*c+p.y*s,-p.x*s+p.y*c,p.z));
}
vec3 radialz(vec3 p, float n,float r){
    float dir = atan(p.x,p.y)+r;
    float len = length(vec2(p.x,p.y));
    dir = abs(mod(dir,3.141592f*2.0f/n)-3.141592f/n);
    return vec3(sin(dir)*len, cos(dir)*len, p.z);
}

float sdSph(vec3 p, float r){
    return length(p) - r;
}

float getSDF(vec3 p,float time){
    /*float n = 1.f + round(abs(p.x)-0.5f);
    float m = 1.f + round(abs(p.y)-0.5f);
    float s = 1.f + 0.1f*round(abs(p.z)-0.5f);
    float q = round(p.x - 0.5f) + round(p.y - 0.5f) + round(p.z-0.5f);
    float r = 0.0825f+0.0425f*sin(round(p.x - 0.5f) + round(p.y - 0.5f) + round(p.z-0.5f));
    float t = sdSph((radialz(radialz(rotx((mod(p.xyz,1.f)-0.5f).xzy,time*q*0.1f).xzy,n,time*s)+vec3(0,0,-0.1f).xzy,m,time*s*2.f)+vec3(0,-0.1,0)).xzy,r);
    */
    vec3 pos = p;
    float s = 1.;
    for(int i = 0; i < 4; i++){
        pos = radialz(pos,5.,time*0.08).zyx-s*vec3(0.5,0.7+0.1*cos(time*0.52),0);
        pos = radialz(pos,3.,time*0.02).zyx-s*vec3(0.5,0.3+0.3*sin(time*0.13),0);
        s = s*(0.45+0.05*cos(0.05*time));
    }
    float t = sdSph(pos,-0.0001f);
    return t;
    
}

vec3 refl(vec3 d, vec3 n){
    return d - 2.f * n * dot(d,n);
}

vec3 findNormal(vec3 p, float d,float t){
    return normalize(vec3(getSDF(p + vec3(d,0,d),t) - getSDF(p - vec3(d,0,0),t),
    getSDF(p + vec3(0,d,0),t) - getSDF(p - vec3(0,d,0),t),
    getSDF(p + vec3(0,0,d),t) - getSDF(p - vec3(0,0,d),t)
    ));
}

void main(void)
{
float speed = 1.f;
float time = time*speed;

    vec2 uv = (gl_FragCoord.xy-0.5f*resolution.xy)/resolution.x;

    // Time varying pixel color
    vec3 col = 0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4));
    
    // Setup
    vec3 pos = vec3(0.0*sin(time*0.1f),2.0*cos(time*0.1f),-2.0*sin(time*0.1f));
    //vec3 dir = normalize(rotx(rotx(vec3(uv.x,uv.y,1),time*0.2f).zxy,time*0.1f).zxy);
    vec3 dir = normalize(rotx(vec3(uv.x,uv.y,-1.).zxy,time*0.1).zxy);
    int ma = 100;
    
    float s = 0.0f;
    float mins = 100000.0f;
    float glow = 0.00f;
    float mdis = 0.f;
    // March Ray
    float lasts = s;
   // bool isn = false;
   vec3 coltot = vec3(0,0,0);
    for(int i = 0; i < ma; i++){
        lasts = s;
        s = min(getSDF(pos,time),0.5f);
        
        mins = min(s,mins);
        pos = pos + dir * s;
        mdis += s;
        if(s < 0.001f){
            i = ma;
        }
        //if(s - lasts  > 0.f){
        glow += (0.0005f/s);
        float l = length(pos);

        coltot += (0.0005/s) * vec3(1.,0.2,0.6/(l+0.4));
        //}

    }
    
    //float l = length(pos);
    //vec3 pos2 = pos + dir * 0.01f;
    // col = vec3(glow,glow*0.2,);
    glFragColor = vec4(coltot,1.0);
   // glFragColor = texture(iChannel0, uv);
}

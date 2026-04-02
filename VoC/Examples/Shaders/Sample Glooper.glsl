#version 420

// original https://www.shadertoy.com/view/3sKBRz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 100
#define MAX_DIST 400.0
#define SURF_DIST 0.01

float sdSphere(vec3 p, vec4 s){
    return  length(p-s.xyz)-s.w;
}

float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float GetDist(vec3 p){
    
       float sd = sdSphere(p-vec3(0.0,1.0,6.0),vec4(0,0,0,1.));
    float v = 0.5+sin(time*2.4 + p.z*5.4+p.y*3.4+p.x*4.1)*0.5;
    sd += v*0.25;
    float k = 3.5+sin(p.y*3.2+time*3.16);
    float d = smin(sd*0.75,p.y+.5,k);
    return d;
}

float RayMarch(vec3 ro, vec3 rd){
    float dO = 0.;
    for(int i = 0; i < MAX_STEPS;i++){
        vec3 p = ro + rd  * dO;
        float dS = GetDist(p);
        dO += dS;
        
        if(dO > MAX_DIST || dS < SURF_DIST) break;
    
    }
    
    return dO;
}

vec3 GetNormal(vec3 p){
    float d = GetDist(p);
    vec2 e = vec2(0.005,0);
    
    
    vec3 n = d - vec3(GetDist(p - e.xyy),
                      GetDist(p - e.yxy),
                      GetDist(p - e.yyx));
    
    return normalize(n);
}

float GetLight(vec3 p,vec3 rd)
{
    float t = fract(time*0.54)*6.28;
    vec3 lightPos = vec3(0,8.+sin(t+p.z)*5.0,3);
    vec3 l = normalize(lightPos - p);
    
    vec3 n = GetNormal(p);
    
    float dif = clamp(dot(n,l),0.0,1.);
    float d = RayMarch(p+n*SURF_DIST*2., l);
    if(d < length(lightPos-p)) dif *= .5;

    vec3 ref = reflect(rd, n);
    float spe = max(dot(ref, l), 0.0);
       dif += pow(spe,64.0);
    
    return dif;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec3 col = vec3(0.0);
    vec3 ro = vec3(0,2,-1);
    vec3 rd = normalize(vec3(uv.x,uv.y-.3,2));
    float d = RayMarch(ro,rd);
    vec3 p = ro + rd *d;
    float dif = GetLight(p,rd);
    col = vec3(dif*(1.0+sin(rd.x)),dif,dif*0.8);
    glFragColor = vec4(col,1.0);
}

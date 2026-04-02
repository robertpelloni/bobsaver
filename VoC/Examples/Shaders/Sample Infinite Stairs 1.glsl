#version 420

// original https://www.shadertoy.com/view/3sfcz8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// All the distance functions from:http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
// raymarching based from https://www.shadertoy.com/view/wdGGz3
#define USE_MOUSE 0
#define MAX_STEPS 80
#define MAX_DIST 50.
#define SURF_DIST .003
#define Rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))
#define matRotateX(rad) mat3(1,0,0,0,cos(rad),-sin(rad),0,sin(rad),cos(rad))
#define matRotateY(rad) mat3(cos(rad),0,-sin(rad),0,1,0,sin(rad),0,cos(rad))
#define matRotateZ(rad) mat3(cos(rad),-sin(rad),0,sin(rad),cos(rad),0,0,0,1)

float smin( float a, float b, float k ) {
    float h = clamp( 0.5+0.5*(b-a)/k, 0., 1. );
    return mix( b, a, h ) - k*h*(1.0-h);
}

vec4 combine(vec4 val1, vec4 val2 ){
    return (val1.w < val2.w)?val1:val2;
}

// A smart way to control the animation. function is from "http://qiita.com/gaziya5/items/29a51b066cb7d24983d6"
float animscene(in float t, float w, float s) {
    return clamp(t - w, 0.0, s) / s;  
}

float stairPart(vec3 p) {
    vec3 p2 = p;
    p2 += vec3(0.1,0.1,0.0);
    p2= abs(p2)-vec3(0.25,0.25,2.0);
    p = abs(p)-vec3(0.2,0.2,0.7);
    float b = max(p.x,max(p.y,p.z));
    float b2 = max(p2.x,max(p2.y,p2.z));
    b = max(-b2,b);
    return b;
}

float stair(vec3 p, int drawBall){
    vec3 pref = p;
    float b = stairPart(p);
    float b2 = stairPart(p-vec3(-0.4,0.4,0.0));
    b = min(b,b2);
    b2 = stairPart(p-vec3(0.4,-0.4,0.0));
    b = min(b,b2);
    b2 = stairPart(p-vec3(-0.8,0.8,0.0));
    b = min(b,b2);
    b2 = stairPart(p-vec3(0.8,-0.8,0.0));
    b = min(b,b2);
    b2 = stairPart(p-vec3(-1.2,1.2,0.0));
    b = min(b,b2);
    b2 = stairPart(p-vec3(-1.6,1.6,0.0));
    b = min(b,b2);
    b2 = stairPart(p-vec3(-2.0,2.0,0.0));
    b = min(b,b2);
    p = abs(p-vec3(1.7,-1.0,0.0))-vec3(0.7,0.03,0.7);
    float b3 = max(p.x,max(p.y,p.z));
    b = min(b,b3);
    
    
    if(drawBall == 1){
        
        p = pref;
        p = abs(p-vec3(2.7,-1.0,0.0))-vec3(0.35,0.03,0.7);
        float b4 = max(p.x,max(p.y,p.z));
        b = min(b,b4);
        p = pref;
        p = abs(p-vec3(3.,0.2,0.0))-vec3(0.03,1.2,0.7);
        float b5 = max(p.x,max(p.y,p.z));
        b = min(b,b5);
        p = pref;
        p = abs(p-vec3(3.,0.2,0.0))-vec3(0.06,1.15,0.6);
        float b6 = max(p.x,max(p.y,p.z));
        b = max(-b6,b);
        
        float speed = 0.6;
        float animTime = mod(time,speed*10.0);
        float x = 0.0;
        x += animscene(animTime, 0.0, speed)*0.4;
        x += animscene(animTime, speed, speed)*0.4;
        x += animscene(animTime, speed*2.0, speed)*0.4;
        x += animscene(animTime, speed*3.0, speed)*0.4;
        x += animscene(animTime, speed*4.0, speed)*0.4;
        x += animscene(animTime, speed*5.0, speed)*0.4;
        x += animscene(animTime, speed*6.0, speed)*0.4;
        x += animscene(animTime, speed*7.0, speed)*0.4;
        x += animscene(animTime, speed*8.0, speed*2.0)*2.0;

        float y = 0.0;
        y += animscene(animTime, speed, speed*0.2)*-0.38;
        y += animscene(animTime,speed+speed, speed*0.1)*-0.38;
        y += animscene(animTime,speed+(speed*2.0), speed*0.1)*-0.42;
        y += animscene(animTime,speed+(speed*3.0), speed*0.1)*-0.42;
        y += animscene(animTime,speed+(speed*4.0), speed*0.1)*-0.38;
        y += animscene(animTime,speed+(speed*5.0), speed*0.1)*-0.38;
        y += animscene(animTime,speed+(speed*6.0), speed*0.1)*-0.38;
        y += animscene(animTime,speed+(speed*7.0), speed*0.1)*-0.38;

        float s = length(pref-vec3(-2.0+x,2.4+y,0.0))-0.2;
        b = min(b,s);
    }
    
    return b;
}

vec4 GetDist(vec3 p) {
    
    vec3 prevP = p;
    float _floor = p.y;

    float y = 0.25;
    
    p.y+= time*1.5;
    p.y=mod(p.y,12.6)-6.3;
    p.y-= 4.20;
    
    float b = stair(p,0);
    float b2 = stair((p+vec3(-1.7,3.17,2.5))*matRotateY(radians(90.0)),1);
    float b3 = stair((p+vec3(0.8,3.17*2.0,4.2))*matRotateY(radians(-180.0)),0);
    float b4 = stair((p+vec3(2.5,3.17*3.0,1.7))*matRotateY(radians(-90.0)),1);
    b = min(b,min(b2,min(b3,b4)));
    
    vec4 resB = vec4(vec3(0.8),b*0.6);

    return resB;
}

vec4 RayMarch(vec3 ro, vec3 rd) {
    vec4 dO= vec4(0.0,0.0,0.0,0.0);
    
    for(int i=0; i<MAX_STEPS; i++) {
        vec3 p = ro + rd*dO.w;
        vec4 dS = GetDist(p);
        dO.w += dS.w;
        dO.xyz = dS.xyz;
        if(dO.w>MAX_DIST || dS.w<SURF_DIST) break;
    }
    
    return dO;
}

vec3 GetNormal(vec3 p) {
    float d = GetDist(p).w;
    vec2 e = vec2(.001, 0);
    
    vec3 n = d - vec3(
        GetDist(p-e.xyy).w,
        GetDist(p-e.yxy).w,
        GetDist(p-e.yyx).w);
    
    return normalize(n);
}

float shadowMap(vec3 ro, vec3 rd){
    float h = 0.0;
    float c = 0.001;
    float r = 1.0;
    float shadow = 0.5;
    for(float t = 0.0; t < 30.0; t++){
        h = GetDist(ro + rd * c).w;
        if(h < 0.001){
            return shadow;
        }
        r = min(r, h * 16.0 / c);
        c += h;
    }
    return 1.0 - shadow + r * shadow;
}

vec2 GetLight(vec3 p) {
    vec3 lightPos = vec3(2,8,3);
    vec3 l = normalize(lightPos-p);
    vec3 n = GetNormal(p);
    
    float dif = clamp(dot(n, l)*.5+.5, 0., 1.);
    float d = RayMarch(p+n*SURF_DIST*2., l).w;
    
    float lambert = max(.0, dot( n, l))*0.1;
    
    float shadow = shadowMap(p + n * 0.001, l);
    
    return vec2((lambert+dif),max(0.9, shadow)) ;
}

vec3 R(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = p+f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i-p);
    return d;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec2 m = mouse*resolution.xy.xy/resolution.xy;
    float t = mod(time,8000.0);
    vec3 col = vec3(0);
    
    vec3 ro = vec3(0, 5, -6);
    #if USE_MOUSE == 1
    ro.yz *= Rot(-m.y*3.14+1.);
    ro.xz *= Rot(-m.x*6.2831);
    #else
    ro.yz *= Rot(radians(-20.0));
    ro.xz *= Rot(t*.3+1.0);
    #endif
    
    vec3 rd = R(uv, ro, vec3(0,1,0), 1.);

    vec4 d = RayMarch(ro, rd);
    
    if(d.w<MAX_DIST) {
        vec3 p = ro + rd * d.w;
    
        vec2 dif = GetLight(p);
        col = vec3(dif.x)*d.xyz;
        col *= dif.y;
        
    } else {
        // background
        col = vec3(1.0);
    }
    
    glFragColor = vec4(col,1.0);
}

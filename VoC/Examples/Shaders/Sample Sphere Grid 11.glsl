#version 420

// original https://www.shadertoy.com/view/wtyyRd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURF_DIST .01

#define pi 3.14159265359
#define twoPi 6.28318530718

float rand(vec3 p) {
    p = fract(p * vec3(321.456, 876.789, 432.976));
    p += dot(p, p+32.56);
    return fract(p.x*p.y*p.z);
}

//from kynd https://thebookofshaders.com/edit.php?log=160414040804
float smoothen(float d1, float d2, float k) {
    return -log(exp(-k * d1) + exp(-k * d2)) / k;
}

//from iq https://www.shadertoy.com/view/Xds3zN
float sdCapsule( vec3 p, vec3 a, vec3 b, float r )
{
    vec3 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}

float GetDist(vec3 p) {
    vec3 id = floor(p);
    p = fract(p);
    
    float radius = .1;
    vec4 sp = vec4(.5,.5,.5, radius);
    float spDist = length(p-sp.xyz) - sp.w;
    
    vec4 sp2 = vec4(sin(time*2.+rand(id.yzy)*123.3)*.5,.5,.5, .03);
    vec4 sp3 = vec4(1.+sin(time*2.+rand(id.yzy)*123.3)*.5,.5,.5, .03);
    
    float spDist2 = length(p-sp2.xyz) - sp2.w;
    float spDist3 = length(p-sp3.xyz) - sp3.w;
    
    float totalDist = smoothen(spDist, min(spDist2, spDist3), 25.);
    
    return totalDist;
    
    
    float line1 = sdCapsule( p, vec3(-1.,.5,.5), vec3(1.,.5,.5), .01 );
    float line2 = sdCapsule( p, vec3(.5,-1.,.5), vec3(.5,1.,.5), .01 );
    float line3 = sdCapsule( p, vec3(.5,.5,-1.), vec3(.5,.5,1.), .01 );
    
    float l = min(line1, min(line2, line3));
 
    totalDist = smoothen(totalDist, l, 25.);
    
    
    return totalDist;
}

float RayMarch(vec3 ro, vec3 rd) {
    float dO = 0.; //dist from origin
    
    for(int i=0; i<MAX_STEPS; i++) {
        vec3 p = ro + rd * dO; // ray
        float dS = GetDist(p);
        dO += dS;
        
        if(dO > MAX_DIST || dS < SURF_DIST) break;
    }
    
    return dO;
}

vec3 GetNormal(vec3 p) {
    float d = GetDist(p);
    
    vec2 e = vec2(.01, 0);
    
    vec3 n = d - vec3(
        GetDist(p-e.xyy),
        GetDist(p-e.yxy),
        GetDist(p-e.yyx)
    );
    
    return normalize(n);
}

float GetLight(vec3 p, vec3 lO) {
    vec3 l = normalize(lO-p); //light vector
    vec3 n = GetNormal(p); //normal vector
    
    float dif = clamp(dot(l,n), 0., 1.);
    
    //shadow
    //float distToLight = RayMarch(p+n*SURF_DIST*2., l);
    //if(distToLight<length(lO-p)) dif *= .5;
    
    return dif;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;

    vec3 col = vec3(.0);
    
    vec3 ro = vec3(0., .7, 0.); //camera origin
    vec3 rd = normalize(vec3(uv.x, uv.y, 1.)); //camera direction
    
    ro += vec3(.3, .3, 2.1) * time * .5;

    //panorama projection for recording 360 video
    //from starea https://www.shadertoy.com/view/Ms2yDK
    //vec2 sph = gl_FragCoord.xy / resolution.xy * vec2(twoPi, pi);
    //rd = vec3(sin(sph.y) * sin(sph.x), cos(sph.y), sin(sph.y) * cos(sph.x)); 
    
    float the = time * 0.15;
    mat2 rotate = mat2(cos(the), -sin(the), sin(the), cos(the));
    
    rd.xz *= rotate;
    rd.yx *= rotate;
 
    float d = RayMarch(ro, rd);
    
    vec3 p = ro + rd * d; //ray
    
    float dif = GetLight(p, ro);
    
    vec3 c1 = vec3(.1,.1,.1) * 4.;
    vec3 c2 = vec3(.9,.9,.9);
    
    col = mix(c1, c2, dif);
    
    float far = 30.; 
    col *= smoothstep(far, 0., d); //fade out by distance
    col = mix(col, vec3(0.161,0.161,0.161), d/far);
    
    glFragColor = vec4(col,1.0);
}

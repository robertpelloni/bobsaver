#version 420

// original https://www.shadertoy.com/view/3sy3Rz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Koch Snowflake 3D - by Martijn Steinrucken aka BigWings 2019
// Email:countfrolic@gmail.com Twitter:@The_ArtOfCode
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//
// After playing with the koch curve and snowflake in 2d, I tried to
// make it 3d. What you are seeing here is just a bunch of 2d snowflakes
// stacked on top of each other while slowly changing the 'hat' angle.
//
// Be sure to check out the 2d flake tutorial on YouTube if you are not 
// familiar with it: https://www.youtube.com/watch?v=il_Qg9AqQkE

float smin( float a, float b, float k ) {
    float h = clamp( 0.5+0.5*(b-a)/k, 0., 1. );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float smax( float a, float b, float k ) {
    float h = clamp( 0.5+0.5*(b-a)/k, 0.,1. );
    return mix( b, a, h ) + k*h*(1.0-h);
}

float sabs(float p, float k){
    return sqrt(p * p + k * k) - k;
}

mat2 Rot(float a) {
    float s = sin(a), c=cos(a);
    return mat2(c,-s,s,c);
}

vec3 GetDir(vec2 uv, vec3 ro, vec3 lookat, float zoom){
    vec3 f = normalize(lookat-ro),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f, r),
        c = ro + f*zoom,
        i = c + uv.x*r + uv.y*u;
    return normalize(i-ro);                  
}

vec2 N(float angle) {
    return vec2(sin(angle), cos(angle));
}

vec2 FlakeUv(vec2 uv, float angle, float radius) {
    uv.x = abs(uv.x);
    
    vec3 col = vec3(0);
    float d;
    vec2 n = N((5./6.)*3.1415);
    
    uv.y += tan((5./6.)*3.1415)*.5;
       d = dot(uv-vec2(.5, 0), n);
    uv -= max(0.,d)*n*2.;
    
    float scale = 1.;
    
    n = N(angle*(2./3.)*3.1415);
    uv.x += .5;
    for(int i=0; i<5; i++) {
        uv *= 3.;
        scale *= 3.;
        uv.x -= 1.5;
        
        uv.x = sabs(uv.x, radius);
        uv.x -= .5;
        d = dot(uv, n);
        uv -= smin(0.,d, radius)*n*2.;
    }
    
    d = length(uv - vec2(clamp(uv.x,-1., 1.), 0));
    uv /= scale;    // normalization
    
    return uv;
}

float GetDist(vec3 p) {
    float d = length(p)-1.;
    

    float y = 1.-abs(p.y*.5);

    vec2 uv = FlakeUv(p.xz*.25, clamp(y,0.,1.), .1);
    d= uv.y;
    
    return d;
}

vec3 GetNormal(float d, vec3 p) {
    vec2 e = vec2(.001,0);
    return normalize(
        d - vec3(
            GetDist(p+e.xyy),
            GetDist(p+e.yxy),
            GetDist(p+e.yyx)
            )
        );
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec2 mouse = mouse*resolution.xy.xy/resolution.xy; // 0 1 
    uv *= 1.25;
    vec3 col = vec3(0);
    
    if(mouse.x<.1) mouse.x = time*.1;
    
    vec3 ro = vec3(0,3, -4);
    ro.yz *= Rot(mouse.y*3.145);
    ro.xz *= Rot(-mouse.x*6.2832);
    
    vec3 rd = GetDir(uv, ro, vec3(0), 1.);
    
    float dS=0.,dO=0.;
    vec3 p;
    for(int i=0;i<1000; i++) {
        p = ro + dO*rd;
        dS = GetDist(p);
        if(abs(dS)<.001 || dO>100.) break;
        dO += dS;
    }
    
    if(dS<.001) {
        vec2 fv = FlakeUv(p.xz, 1., .1);
        vec3 n = GetNormal(dS, p);
        col += n*.5+.5;
        col *= dot(n, normalize(vec3(1)))*.4+.6;
        //col.rg += fv;
    }
    //col *= 0.;
    //vec2 fv = FlakeUv(uv, mouse.y, .2);
    //col = texture(iChannel0, fv).rgb;
    
    glFragColor = vec4(col,1.0);
}

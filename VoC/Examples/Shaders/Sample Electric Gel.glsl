#version 420

// original https://www.shadertoy.com/view/MlSSWW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by randy read - rcread/2015
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

//    a variant of sechristo's very cool https://www.shadertoy.com/view/MljXW1

//shoutout to iq for the getNormal function

#define EPS 0.01
#define TAU 2.0*3.14159265359

float map (float r, float angle) {
    return (tan(angle*3.0+time*0.1)*0.5)+0.5 + sin(r*30.0)*0.1;
}

vec3 getNormal(float r, float angle) {
    vec3 n = vec3( map(r-EPS,angle) - map(r+EPS,angle),map(r,angle-EPS) - map(r,angle+EPS),5.0*EPS);
    return normalize( n );
}

float map1(float x, float y) {
    vec2 uv = vec2(x,y);
    float r = sqrt(pow(uv.x,2.0)+pow(uv.y,2.0));
    float angle = atan(uv.y,uv.x);
    
    vec3 light = normalize(vec3(sin(1.0),cos(1.0),sin(time*0.1)));
    return pow(dot(light,getNormal(r,angle)),2.0);
}

float map1(float x, float y, float offset) {
    vec2 uv = vec2(x,y);
    float r = sqrt(pow(uv.x,2.0)+pow(uv.y,2.0));
    float angle = atan(uv.y,uv.x);
    
    vec3 light = normalize(vec3(sin(1.0),cos(1.0),sin(time*0.1)));
    return pow(dot(light,getNormal(r,angle+offset)),2.0);
}

vec3 getXYNormal(float x, float y) {
        vec3 n = vec3( map1(x-EPS,y) - map1(x+EPS,y),map1(x,y-EPS) - map1(x,y+EPS),150.0*EPS);
    return normalize( n );
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 mouse = mouse*resolution.xy.xy / resolution.xy;
    
    float c = 0.5;
    
    uv.x -= 0.5;
    uv.y -= 0.5;
    mouse.x -= 0.5;
    mouse.y -= 0.5;
    
    uv.y *= resolution.y/resolution.x;
    mouse.y *= resolution.y/resolution.x;
    
    float ch = 50.0;
    float cr = sin(map1(uv.x,uv.y,0.0)*sin(map1(uv.x,uv.y,0.0)));
    float cg = sin(map1(uv.x,uv.y,1.0*ch)*sin(map1(uv.x,uv.y,1.0*ch)));
    float cb = sin(map1(uv.x,uv.y,2.0*ch)*sin(map1(uv.x,uv.y,2.0*ch)));
    cr = map1(cr,cg);
    cg = map1(cg,cb);
    cb = map1(cr,cb);
    vec3 tint = vec3(0.2,0.1,0.3);
    float w = 6. * sin( time * 7. / 11. );
    vec3 col = vec3( cr,cg,cb) + tint;
    col = ( w * normalize( col ) + -w * col / max(cr,max(cg,cb) ) ) / 2.;
    
    vec3 mLoc = vec3(sin(-time)*0.333,cos(-time)*0.333,-2.0);
    vec3 light = vec3(uv.x,uv.y,map1(uv.x,uv.y))-mLoc;
    vec3 lDir = normalize(light);
    vec3 normal = getXYNormal(map1(uv.x,uv.y),map1(uv.y,uv.x));
    col += pow(clamp(dot(lDir,normal),0.,1.),200.0)*6.0;
    col += pow(clamp(dot(lDir,normal),0.,1.),50.0)*1.0;
    col += tint;
    col*=0.1;
    
    glFragColor = vec4(col,1.0);
    
    
}

#version 420

// original https://www.shadertoy.com/view/wslGzM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS  50
#define MAX_DIST   65.
#define SURF_DIST .05

float sinus_plane(vec3 p, vec4 n){
  return  dot(p,n.xyz) + n.w + 
          0.3 * sin(5.*p.x) + 0.6 * sin(p.x+time*3.) +
            0.1 * sin(5.*p.y) + 1.  * sin(p.z+time*9.);
}

float scene(vec3 p){
  return min(sinus_plane(p,vec4(0.,1.,0.,3.)),sinus_plane(p,vec4(0.,-0.3,0.,3.)));
}

float march(vec3 ro, vec3 rd){
    float dO=0.;
    for(int i=0; i<MAX_STEPS; i++) {
        vec3 p = ro + rd*dO;
        float dS = scene(p);
        dO += dS;
        if(dS<SURF_DIST)break;
        if(dO>MAX_DIST)return MAX_DIST+1.;
    }
    return dO;
}

vec3 normal(vec3 p){
    float d = scene(p);
    vec2  e = vec2(.01, 0);
    vec3  n = d - vec3(scene(p-e.xyy),scene(p-e.yxy),scene(p-e.yyx));
    return normalize(n);
}

float light(vec3 p) {
    vec3 pos = vec3(3, 4, 1);
    vec3 l = normalize(pos-p);
    vec3 n = normal(p);
    return clamp(dot(n, l), 0., 1.);
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec3 ro = vec3(sin(time), 1.+1.4*sin(0.3*time), 0);
    vec3 rd = normalize(vec3(uv.x+0.15*sin(0.25*time), uv.y+0.1+0.05*sin(time), 1.));
    float d = march(ro, rd);
    vec3  p = ro + rd * d;
    float l = light(p);
    
    if(d>MAX_DIST)glFragColor=vec4(vec3(.8),1.);
    else if(p.y<0.1)glFragColor = vec4(vec3(d/80.,d/80.,l),1.);
    else glFragColor=vec4(vec3(l,d/80.,d/80.),1.);
}

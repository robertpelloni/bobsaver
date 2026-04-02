#version 420

// original https://www.shadertoy.com/view/tlBGRc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 cossin(float a) { return vec2(cos(a),sin(a)); }
mat2x2 rotmat(float a) {
    vec2 cs = cossin(a);
    return mat2x2(cs.x, -cs.y, cs.y, cs.x);
}

float hash(vec2 v) {
    return fract(sin(dot(v, vec2(15.1345, 7823.949)))*1903.34);
}

float minMirrorDist = 1000.;
vec2 mirror(vec2 p, vec2 c, float a) {
    p-=c;
    p*=rotmat(-a);
    p.y = abs(p.y);
    minMirrorDist = min(minMirrorDist, p.y);
    p*=rotmat(a);
    p+=c;
    return p;
}

vec2 angleMirror(vec2 p, vec2 c, float a) {
    p-=c;
    float t = atan(p.y, p.x)-a/2.;
    t = mod(t,a)-a/2.;
    p = vec2(cos(t), sin(t))*length(p);
    p+=c;
    return p;
}
float tmod(float v, float b) {
    return b - abs(b - mod(v,b*2.));
}
vec2 tangleMirror(vec2 p, vec2 c, float a) {
    p-=c;
    float t = atan(p.y, p.x)+a/2.;
    t = tmod(t,a)-a/2.;
    p = vec2(cos(t), sin(t))*length(p);
    p+=c;
    return p;
}

#define PI 3.1415926
#define TAU 6.2831852
void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy*2.-resolution.xy)/resolution.y;
    vec2 muv = (mouse*resolution.xy.xy*2.-resolution.xy)/resolution.y;
    
    
    
        vec2 ouv = uv;
    float d = 1000.;
    for(float i = 0. ; i < TAU ; i += TAU/3.) {
        vec2 ouv = uv;
        uv *= rotmat(i+time*.01);
        uv = tangleMirror(uv, 1.-abs(2.*cossin(i+time*.1)), TAU/6.);
        d = min(d,length(uv-ouv));
    }
    
    //uv = tangleMirror(uv, muv, TAU/6.);
    
    
    //uv -= vec2(.2,0)*(1.+cos(time));
    //vec3 col = vec3(0,1.-length(uv)*10.,1.-minMirrorDist*10.);
    //uv = 1.-5.*min(fract(uv*5.),1.-fract(uv*5.));
    vec3 col = vec3(.5-10.*fract(uv*2.)*.5,1.-fract(d)*10.);
    // Output to screen
    glFragColor = vec4(col,0);
}

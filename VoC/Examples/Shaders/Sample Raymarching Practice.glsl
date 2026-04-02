#version 420

// original https://neort.io/art/bpifhis3p9fbkbq82s40

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

const float pi = acos(-1.0);
const float pi2 = pi*2.;
mat2 rot (float a){
  float c = cos(a),s = sin(a);
  return mat2(c,s,-s,c);
  }

vec2 pmod(vec2 p, float r) {
    float a =  atan(p.x, p.y) + pi/r;
    float n = pi2 / r;
    a = floor(a/n)*n;
    return p*rot(-a);
}
float sdbox(vec3 p,vec3 s){

    p = abs(p)-s;
    return length (max(p,0.0))+min(max(p.x,max(p.y,p.z)),0.0);
}

float dist(vec3 p){
    p.z = mod(p.z,30.0)-15.;
    p.xy = pmod(p.xy,8.0);
    float s = floor(time);
    vec3 a = vec3(0.2,0.2,0.2);
    vec3 b = vec3(0.1,2.5,0.1);
    float d = sdbox(p,a);
    for (int i = 0;i<5; i++){
        p = abs(p)-0.75;
        p.xy *= rot(4. * s);
        p.zy *= rot(-2.);
        p.xz *= rot(3.);
        float d1 = sdbox (p,a);
        d = min(d1,d);
    }
    vec2 c = vec2(0.5,0.5);
    return d;
}

void main (void){
    vec2 p = (gl_FragCoord.xy * 2. -resolution) /min(resolution.x, resolution.y);
    vec3 ca = vec3(0.,0.,time*100.);
    float sc = 2.5;
    vec3 ray = normalize (vec3(p,sc));
    float depth = 0.0;
    vec3 col = vec3 (0.0);
    float ac = 0.0;
    vec3 c = vec3(0.3,0.,1.);
    vec3 no = vec3(0.0);

    for(int i = 0; i < 100; i++){
    vec3 rp = ca+ray*depth;
    float d = dist(rp);
    d = max(abs(d),0.02);
    ac += exp (-d*3.);
    depth += d;
    }
    col = vec3(ac*0.02) * c;
    glFragColor = vec4(col,1.0);

}

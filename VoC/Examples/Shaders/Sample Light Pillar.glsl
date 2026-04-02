#version 420

// original https://www.shadertoy.com/view/WttXWf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rot(float a) {
    return mat2(
        cos(a), sin(a), -sin(a), cos(a)
    );
}

float sdRoundBox( vec3 p, vec3 b, float r )
{
    
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

float map(vec3 p) {
    vec3 pos = vec3(0,0,10);
    pos = pos-p;
    pos = abs(pos) - 2.;
    
       for(int i=0; i<10; i++) {
           pos = abs(pos) - 3.;
        pos.xz *= rot(time*.1);
    }
    
    pos.xz *= rot(time);
    pos.xz *= 1.+sin(p.y+time)*.5+sin(p.y+time*2.14)*.2+.3;
    pos.xz *= rot(p.y);
    // pos.yz *= rot(time);
    return sdRoundBox(pos, vec3(1.,10000.,1.), .2);

}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec3 col = vec3(0.);
    vec3 lookat = vec3(0,-8.,3)+vec3(sin(time*.1)+sin(time*.1+21.14)*.2,0,0);
    vec3 ro = vec3(0);

    vec3 forward = normalize(lookat-ro);
    vec3 right = cross(forward, vec3(0,1,0));
    vec3 up = cross(forward, right);
    float z = 1.5;
    vec3 center = ro + forward*z;
    vec3 i = center + up*uv.y + right*uv.x;
    
    vec3 rd = normalize(i-ro);
    
    
    // vec3 rd = vec3(vec3(uv,z)-ro);
    // vec3 rd = normalize(target-ro)+vec3(uv,0.);
    
    vec3 p = vec3(0.);
    float t,c;

    for(int i=0; i<1000; i++) {
        p = ro+t*rd;
        float d = map(p);
        d = max(0.02 + (exp(5.*sin(time * 0.3))/exp(5.))*0.1, abs(d));
        if(d<0.01) {
            col = vec3(1.);
            break;
           }
        if(t>100000.) {
            break;
        }
        t += d;
        c += 1./400.;
    }
    
    col = vec3(pow(c,3.5));

    glFragColor = vec4(col,1.0);
}

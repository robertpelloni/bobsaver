#version 420

// original https://www.shadertoy.com/view/3sfyD7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 Rot(float a){
    float s=sin(a), c=cos(a);
    return mat2(c,-s,s,c);
}

float Xor(float a, float b){
 return a*(1.-b)+   b*(1.-a);
}

float HexDist(vec2 p){
    p = abs(p);
    float c= dot(p,normalize(vec2(1,1.73)));
    c=max(c,p.x);   
    return c;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.465*resolution.xy)/resolution.y;

    uv*=Rot(3.1415926535/3.);
    vec3 col = vec3(0);
    float d=HexDist(uv);
    uv*=10.;
    
    vec2 gv = fract(uv)-.5;
    vec2 id = floor(uv);
    
    float m=0.1;
    float c=0.1;
    float t = time;
    
    for(float y=-1.; y<=1.; y++) {
        for(float x=-1.; x<=1.; x++) {
            vec2 offs = vec2(x,y);
            float d=HexDist(gv+offs);
            float dist=length(id-offs)*.3;
            float r = mix(.3,1.5,sin(dist-t)*.5+.5);
            c=Xor(c,smoothstep(r,r*0.95,d));
        }
    }
    col+=c;

    glFragColor = vec4(col,1.0);
}

#version 420

// original https://www.shadertoy.com/view/dtdBRf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rot2(a) mat2(sin(a),cos(a),-cos(a),sin(a))
#define PI 3.14159265

#define time time
#define resolution resolution

float rand(vec2 uv){
    return fract(sin(dot(uv ,vec2(12.9898,58.233))) * 13758.5453);
}

vec4 blurRand(vec2 uv){
    vec4 c = vec4(0.);
    uv = uv * 4.;
    vec2 uf = fract(uv);
    vec2 u = floor(uv);
    //uf = uf*uf*(3.-2.*uf);
    float h = rand(u);    
    float i = rand(u + vec2(1,0));
    float j = rand(u + vec2(0,1));
    float k = rand(u + vec2(1,1));
    
    float hl = length(uf);
    float il = length(uf-vec2(1,0));
    float jl = length(uf-vec2(0,1));
    float kl = length(uf - vec2(1));
    
    //c.x = mix(mix(h,i,uf.x),mix(j,k,uf.x),uf.y);
    c.x = max(max(h * (1.-hl) , i * (1.-il)),max(j*(1.-jl), k*(1.-kl)));
    //c.x = min(min(h*hl,i*il),min(j*jl,k*kl));
    //c.x = mix(h,k,hl)+mix(i,j,jl);

    //c = vec4(hl,il,jl,kl);
    //c = vec4(h,i,j,k);
    return c;
}

void main(void) {

    // old version
    //vec2 uv = (( gl_FragCoord.xy / resolution.xy )*2.-1.) * vec2(1,resolution.y/resolution.x);
    
    // from FabriceNeyret2
    vec2 uv = ( 2.*gl_FragCoord.xy -  resolution.xy ) / resolution.x ;

    float color = 0.0;
    for(float i = 0.;i<7.;i++){
        color += blurRand(uv+color*.2+time*.1).x;
        uv *= 1.4;
        uv *= rot2(PI/5.);
    }
    glFragColor = vec4(vec3(1./color), 1.0 );

}

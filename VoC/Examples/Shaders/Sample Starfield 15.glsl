#version 420

//--- FTL ---
// by Catzpaw 2016

#define ab = (time*0.2)

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

vec3 star(vec2 uv,float scale,float seed){
    uv*=scale;
    vec2 s=floor(uv), f=fract(uv), p;
    float k=3., d;
    p=.5+.440*sin(11.*fract(sin((s+seed)*mat2(7.5,3.3,6.2,5.4))*55.))-f;d=length(p);k=min(d,k);
    k=smoothstep(0.,k,0.007);
        return k*vec3(k,k,1.);
}

void main(void){
    vec4 b=texture2D(backbuffer,gl_FragCoord.xy/resolution.xy);
    vec2 uv=(gl_FragCoord.xy*2.-resolution.xy)/min(resolution.x,resolution.y); 
    
    
    uv *= mat2(cos(time*0.3),-sin(time*0.3),sin(time*0.3),cos(time*0.3));
    
    vec3 c=vec3(0);
    for(float i=0.;i<20.;i+=2.)c+=star(uv,mod(20.+i-time*10.,20.),i*5.1);
    glFragColor = vec4(c+b.gbb*.8,88.5);
}

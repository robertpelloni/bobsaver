#version 420

// original https://www.shadertoy.com/view/MtVGWW

uniform vec4 date;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define ss 1 //anti aliasing
#define iterations 128

float startRandom = fract(sin(floor(date.w-time)*9756962.215)*15465.486);
vec2 rand(vec2 co, float t)
{
float s = t+startRandom;
    return fract(s+vec2(sin(s+dot(co,vec2(75542.8974,99846.16956))),sin(2.*s+dot(co,vec2(75589.1688,9846.16956))))*4849456.48456)-.5;
}

vec2 perlin(vec2 c, float t)
{
vec2 i= floor(c);
float dt = fract(t);
 t =floor(t);
vec2 f = fract(c);
vec2 m1 = vec2(dot(f,rand(i,t)),dot(f,rand(i,t+100.5)));
vec2 m2 = vec2(dot(f-vec2(1,0),rand(i+vec2(1,0),t)),dot(f-vec2(1,0),rand(i+vec2(1,0),t+100.5)));
vec2 m3 = vec2(dot(f-vec2(0,1),rand(i+vec2(0,1),t)),dot(f-vec2(0,1),rand(i+vec2(0,1),t+100.5)));
vec2 m4 = vec2(dot(f-1.,rand(i+1.,t)),dot(f-1.,rand(i+1.,t+100.5)));
    
    t+=1.;

vec2 tm1 = vec2(dot(f,rand(i,t)),dot(f,rand(i,t+100.5)));
vec2 tm2 = vec2(dot(f-vec2(1,0),rand(i+vec2(1,0),t)),dot(f-vec2(1,0),rand(i+vec2(1,0),t+100.5)));
vec2 tm3 = vec2(dot(f-vec2(0,1),rand(i+vec2(0,1),t)),dot(f-vec2(0,1),rand(i+vec2(0,1),t+100.5)));
vec2 tm4 = vec2(dot(f-1.,rand(i+1.,t)),dot(f-1.,rand(i+1.,t+100.5)));
    
    

return mix(mix(mix(m1,m2,smoothstep(0.,1.,f.x)),mix(m3,m4,smoothstep(0.,1.,f.x)),smoothstep(0.,1.,f.y)),
           mix(mix(tm1,tm2,smoothstep(0.,1.,f.x)),mix(tm3,tm4,smoothstep(0.,1.,f.x)),smoothstep(0.,1.,f.y)),smoothstep(0.,1.,dt));
}

void main(void)
{
      vec2 p = mouse*resolution.xy.xy / resolution.y-vec2(.5+(resolution.x-resolution.y)/(2.*resolution.y),.5);
    if(mouse*resolution.xy.xy==vec2(0))
        p=vec2(-.75,.05);
    vec3 fcol=vec3(0);
    for(int i =0;i<ss*ss;i++)
    {
    vec2 uv = (gl_FragCoord.xy+(vec2(mod(float(i),float(ss)),floor(float(i)/float(ss)))+.5)/float(ss))
        / resolution.y-vec2(.5+(resolution.x-resolution.y)/(2.*resolution.y),.5);
            float dmin=1000.;
        vec2 c=p;
        vec2 z=uv*2.6;
    for(int i =0;i<iterations;i++)
    {
        z=z*mat2(z.x,-z.y,z.yx)+c;
        vec2 z1 = z+perlin(z+time,.1*time+float(i));
        dmin=min(dmin, min(abs(z1.y),abs(z1.x)));
    }    
        dmin=1.+log(dmin)/6.;
        vec3 col=mix(vec3(.2,.25,.4),vec3(1,.7,.5),dmin);
        fcol+=col/float(ss*ss);
    }
    glFragColor = vec4(fcol,1.0);
}

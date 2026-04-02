#version 420

// original https://www.shadertoy.com/view/ll3yWj

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define C vec2(.5,.5)
#define TwoPi 6.2831
//line/capsule based on "DrawLine-2D" function from Unreal Engine
float line (vec2 uv,vec2 p1,vec2 p2,float w,float f)
{
vec2 dif =p2-p1;
return 1.-clamp((distance((uv-p1)-clamp(dot(uv-p1,dif)/dot(dif,dif),0.,1.)*dif,vec2(0.,0.))-w)/f,0.,1.);
}
//orbiting point
vec2 orbit (float rot, float dist)
{
return vec2(sin((-rot-.5)*TwoPi),cos((-rot-.5)*TwoPi))*dist;
}

//render
void main(void)
{
    vec4 clock = glFragColor;
    float ar = resolution.x/resolution.y;
    vec2 uv = gl_FragCoord.xy/resolution.xy;
         uv = vec2(uv.x,1.-uv.y)*vec2(ar,1.)-vec2((ar-1.)/2.,0.);
    
//pointers
vec2 HP = orbit(1./43200.*date.w,.22);
vec2 MP = orbit(1./3600.*date.w,.33);
vec2 SP = orbit(1./60.*date.w,.44);
clock.x += line(uv-C,vec2(0.,0.)-HP*.2,HP,.015,.0025)+line(uv-C,vec2(0.,0.)-MP*.2,MP,.0075,.0025)+line(uv-C,vec2(0.,0.)-SP*.2,SP,.005,.0025);

//markings
for(int i=0;i<60; i++)
{
float IsHour = ceil(mod(float(i),5.)/5.);
vec2 point1 =orbit(1./60.*float(i),mix(.35,.4,IsHour));
vec2 point2 =point1*mix(1.3,1.15,IsHour);
clock.x += line(uv-C,point1,point2,mix(.01,.002,IsHour),.0025);
}
        
    clock = vec4(clock.x,clock.x,clock.x,1.0);
    glFragColor = clock;
}

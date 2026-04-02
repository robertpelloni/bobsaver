#version 420

// original https://www.shadertoy.com/view/fll3Rr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define SS(a,b,t) smoothstep(a,b,t)
float rand(float x)
{
    return fract(sin(sin(126.*x)*564.)*.837);
}
float wave12(float x)
{
    return sin(x+sin(x+sin(x)*.5));
}
vec3 paintRaincol(vec2 uv,vec2 pos)
{
    vec3 raincol;
    raincol.xy=uv-pos+.06;
    raincol.z=.1;
    return raincol*10.*vec3(.5,.7,1.);
}
float remap(float a, float b,float c, float d,float x)
{
    return ((x-a)/(b-a))*(d-c)+c;
}
void main(void)
{
    vec4 O=glFragColor;

    float loopTime=600.;
    float t=fract(time/loopTime)*loopTime;//when time is very large, t will be similar in each cell

    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    
    
    //cell
    vec2 ratio=vec2(1.,4.);
    vec2 cuv=uv/ratio*10.;
    cuv.y+=rand(floor(cuv.x)+9.)*4.;
    cuv.y+=t*0.3;
    vec2 id=floor(cuv);
    float hashid=id.x*2.+id.y*4.;
    t+=rand(hashid)*10.;//diff time
    cuv=fract(cuv)-.5;
    cuv+=vec2(sin(cuv.y*10.+t*2.),sin(cuv.x*13.+t*2.))*.005;//distort
    cuv.y*=ratio.y;
    
    //cell line
    //if(cuv.x>.48||cuv.y>.49*ratio.y)
        //O.rgb+=vec3(1.);
        
        
    //rain
    vec2 pos=vec2(0.,ratio.y*wave12(-t*2.)*.3);  
    float d=length(cuv-pos);
    float size=rand(hashid)*.4+.6;
    O.rgb+=vec3(SS(.2*size,.099,d))*paintRaincol(cuv,pos);
    
    
    //trail
    float density=2.;
    float tLengthRate=remap(0.,1.,.2,.4,rand(hashid));
    vec2 tuv=fract(uv*vec2(1.,density)*10.)-.5;
    tuv.y/=density;
    float trd=cuv.y-pos.y;//trail rain dis
    float topPos=ratio.y*tLengthRate;
    float trailr=SS(0.,2.5,topPos-cuv.y)*0.2*size;//nearer the dead line, smaller
    O.rgb+=vec3(SS(trailr,trailr*.1-.01,length(tuv))*SS(.13,.14,trd))*paintRaincol(tuv,vec2(0.));//size,pos*dir*col

    glFragColor=O;
}

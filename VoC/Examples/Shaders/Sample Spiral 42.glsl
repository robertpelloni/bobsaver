#version 420

// original https://www.shadertoy.com/view/fls3R8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define SS(a,b,t) smoothstep(a,b,t)
#define PAI 3.14159265
void main(void)
{
    vec4 O=glFragColor;
    float t=time;
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec2 polar=vec2(atan(-uv.y,-uv.x)/6.2832+.5,length(uv));
    
    //glow
    O.rgb+=SS(.4,.3,polar.y)*vec3(.1,.1,.1)*1.3;
    
    //spiral
    float petalNum=5.;
    float st=sin(t);
    float cx=(polar.x+st)*petalNum;
    float dx=cx+polar.y*st*19.;//distort
    float y=min(fract(dx),fract(1.-dx));
    float len=.3;
    float musk=SS(0.,.02/polar.y,y*len-polar.y+.2);
    O.rgb*=1.-musk;
    O.rgb+=musk*vec3(.7,.1,.1);
    
    //outlines
    float lineNum=10.;
    for(float i=0.;i<lineNum-.1;i+=1.0)
        O.rgb+=SS(.012*fract(cx*sign(-st)),0.,abs(polar.y+sin(t+PAI/lineNum*i*.25)*.2-.56))*vec3(.3,.1,.1);

    glFragColor=O;
}

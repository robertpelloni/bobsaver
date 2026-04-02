#version 420

// original https://www.shadertoy.com/view/Ms3GWH

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define SHARPNESS 450.

float PI = 3.141592653589793238462;
#define clamps(x) clamp(x,0.,1.)
vec2 rotation(in float angle,in vec2 position) //Rotation (Not by me but edited it)
{
    float rot = radians(angle*360.);
    mat2 rotation = mat2(cos(rot), -sin(rot), sin(rot), cos(rot));
    return vec2(position*rotation);
}
float distshape(vec2 uv, float sides) { //http://patriciogonzalezvivo.com/2015/thebookofshaders/07/
    float angle = atan(uv.x,uv.y)+PI;
    float r = (PI*2.)/sides;
    return cos(floor(.5+angle/r)*r-angle)*length(uv);
}
float distanceToSegment( in vec2 p, in vec2 a, in vec2 b )
{
    //Iq's function (I use this for smooth lines)
    vec2 pa = p-a;
    vec2 ba = b-a;
    float h = clamp(dot(pa,ba)/dot(ba,ba),0.0,1.0);
    return length( pa - ba*h );
}
vec2 cossin(float a) //Circle
{
    return vec2(-sin(a*2.*PI),cos(a*2.*PI));
}

//Clock drawing function
float clock(vec2 suv,float sharp) {
    float atans = (atan(suv.x,suv.y)+PI)/(PI*2.); //Degrees in 0 to 1
    float drawing = clamps(1.-((length(suv)-0.45)*sharp)); //Make circle
    drawing -= clamps(1.-((length(suv)-0.4)*sharp)); //Remove inner
    drawing += clamps(1.-((length(suv)-0.01)*sharp)); //Middle joint circle
    //Set thickness
    float dist = 0.35;
    //Second hand
    drawing += clamps(1.-((distanceToSegment(suv,vec2(0.),cossin(-(date.w/60.))*dist)-0.002)*sharp));
    //Thin thickness
    dist -= 0.05;
    //Minute hand
    drawing += clamps(1.-((distanceToSegment(suv,vec2(0.),cossin(-(date.w/3600.))*dist)-0.003)*sharp));
    //Thin thickness
    dist -= 0.05;
    //Hour hand
    drawing += clamps(1.-((distanceToSegment(suv,vec2(0.),cossin(-(date.w/43200.))*dist)-0.005)*sharp));
    //5 minutes lines
    //float ats = fract((atans*12.)-.5)-0.5;
    float sides = 12.;
    float a1 = floor((atans*sides)-.5)/sides;
    float ats = rotation(a1+(1./sides),suv*sides).x*.1;
    float ats2 = distshape(suv,sides);    
    drawing += clamps(1.-((distanceToSegment(vec2(ats,ats2),vec2(0.,0.30),vec2(0.,0.37))-0.003)*sharp));
    //Secounds lines
    sides = 12.*5.;
    a1 = floor((atans*sides)-.5)/sides;
    ats = rotation(a1+(1./sides),suv*sides).x*.02;
    ats2 = distshape(suv,sides);    
    float ats3 = step((1./12.)*2.,fract((atans*12.)+(1./12.)));
    if (ats3 == 1.) { //Do not draw on 5 minutes lines.
    drawing += clamps(1.-((distanceToSegment(vec2(ats,ats2),vec2(0.,0.35),vec2(0.,0.37))-0.003)*sharp));
    }
    return clamps(drawing);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec3 color1 = vec3(1.1,1.04-((1.-uv.y)*.05),1.-((1.-uv.y)*.1));
    vec3 color2 = vec3(1.,0.2,.3);
    vec2 suv = vec2(((uv.x-0.5)*(resolution.x / resolution.y))+0.5,uv.y)-.5; //I subtracted with -.5 so it'll be easier.
    float shadow = clamps(clock(suv+vec2(0.,0.01),90.)-clock(suv,SHARPNESS));
    glFragColor = vec4(mix(color1,color2,clock(suv,SHARPNESS))-(shadow*.2),1.0);
}

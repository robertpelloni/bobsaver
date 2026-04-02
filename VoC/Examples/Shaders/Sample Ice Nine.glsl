#version 420

// original https://www.shadertoy.com/view/ltVBzt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define S(a,b,t) smoothstep(a,b,t)
#define nTime (time+9000.)/7.
#define bluridx 35.
#define BLUE vec3(0.1,.5,.9)*clamp(vec3(abs(sin(nTime+1.))),.1,.9)
#define RED vec3(0.9,.2,.1)*clamp(vec3(abs(sin(nTime+2.))),.1,.9)
#define GREEN vec3(0.1,.9,.6)*clamp(vec3(abs(sin(nTime+3.))),.1,.9)
#define YELLOW vec3(0.9,.9,.0)*clamp(vec3(abs(sin(nTime+4.))),.1,.9)

float DDot(vec2 p1,vec2 p2, float blr) {
    return 1.-(distance(p1,p2)*blr);
}
    

float N21(vec2 p)
{    // Dave Hoskins - https://www.shadertoy.com/view/4djSRW
    vec3 p3  = fract(vec3(p.xyx) * vec3(443.897, 441.423, 437.195));
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

float segment(vec2 p, vec2 a, vec2 b) {
    vec2 ab = b - a;
    vec2 ap = p - a;
    float k = clamp(dot(ap, ab)/dot(ab, ab), 0.0, 1.0);
    return 1.-smoothstep(0.0, 1.0/resolution.y, length(ap - k*ab) - 0.0001);

}

vec2 blob_pos(float i) {
    float t=N21(vec2(i,i+9.));
    float tt=N21(vec2(i+7.,i+9.));
    return vec2(sin(nTime+i*t)+tt, cos(nTime+i+t)+tt)*vec2(0.42,0.22);
}

vec3 ShapeThing(vec2 uv, vec3 inCol, float seed) { 
    
    vec3 col=vec3(0.,0.,0.);
    vec3 colmask;
    vec2 pos;
    
    vec2 pos1 = blob_pos(1.+seed);
    vec2 pos2 = blob_pos(2.+seed);
    vec2 pos3 = blob_pos(3.+seed);
    vec2 pos4 = blob_pos(4.+seed);
    vec2 pos5 = blob_pos(5.+seed);

    float blur1=80.-(bluridx*(sin(time*N21(vec2(1.+seed,1.)))));
    float blur2=80.-(bluridx*(sin(time*N21(vec2(2.+seed,2.)))));
    float blur3=80.-(bluridx*(sin(time*N21(vec2(3.+seed,3.)))));
    float blur4=80.-(bluridx*(sin(time*N21(vec2(4.+seed,4.)))));
    float blur5=80.-(bluridx*(sin(time*N21(vec2(5.+seed,5.)))));

       colmask=inCol;
    col=max(colmask*vec3(DDot(uv,pos1,blur1)),col);
    col=max(colmask*vec3(DDot(uv,pos2,blur2)),col);
    col=max(colmask*vec3(DDot(uv,pos3,blur3)),col);
    col=max(colmask*vec3(DDot(uv,pos4,blur4)),col);
    col=max(colmask*vec3(DDot(uv,pos5,blur5)),col);
    col += segment(uv,pos1,pos2)*inCol;
    col += segment(uv,pos1,pos3)*inCol;
    col += segment(uv,pos3,pos2)*inCol;
    col += segment(uv,pos1,pos4)*inCol;
    col += segment(uv,pos2,pos4)*inCol;
    col += segment(uv,pos3,pos4)*inCol;
    col += segment(uv,pos5,pos1)*inCol;
    col += segment(uv,pos5,pos2)*inCol;
    col += segment(uv,pos5,pos3)*inCol;
    col += segment(uv,pos5,pos4)*inCol;

    return col;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;

    glFragColor = vec4(ShapeThing(uv,RED,0.1),1.0)+vec4(ShapeThing(uv,BLUE,0.2),1.0)+vec4(ShapeThing(uv,GREEN,0.5),1.0)+vec4(ShapeThing(uv,YELLOW,0.6),1.0);
    vec2 uv2=uv*vec2(-1.,-1.);
    glFragColor += vec4(ShapeThing(uv2,RED,0.1),1.0)+vec4(ShapeThing(uv2,BLUE,0.2),1.0)+vec4(ShapeThing(uv2,GREEN,0.5),1.0)+vec4(ShapeThing(uv2,YELLOW,0.6),1.0);
    uv2=uv*vec2(-1.,1.);
    glFragColor += vec4(ShapeThing(uv2,RED,0.1),1.0)+vec4(ShapeThing(uv2,BLUE,0.2),1.0)+vec4(ShapeThing(uv2,GREEN,0.5),1.0)+vec4(ShapeThing(uv2,YELLOW,0.6),1.0);
    uv2=uv*vec2(1.,-1.);
    glFragColor += vec4(ShapeThing(uv2,RED,0.1),1.0)+vec4(ShapeThing(uv2,BLUE,0.2),1.0)+vec4(ShapeThing(uv2,GREEN,0.5),1.0)+vec4(ShapeThing(uv2,YELLOW,0.6),1.0);
}

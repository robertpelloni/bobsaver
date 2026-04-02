#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define iter 25.0
#define pi 3.14159265359

float circleDistance(vec2 p){
    float v;
    for(float i=-iter;i<iter;i++){
        float f=i-fract(time);
        float d=smoothstep(0.127,0.123,distance(p,vec2(f*0.25,0.375)));
        v+=(1.0-abs(f)/iter)*d;
    }
    return v;
}

vec3 background(vec2 p){
    return mix(vec3(0.0,0.3,0.9),vec3(0.3,0.5,1.0),step(0.5,fract(10.0*(atan(p.x,p.y)-0.2*time)/(2.0*pi))));
}

vec4 circle(float r,vec2 p0,vec2 p1,vec3 color){
    return vec4(color,step(distance(p0,p1),r));
}

vec4 cutcircle1(float r,vec2 p0,vec2 p1,vec3 color,float cut){
    vec4 c=circle(r,p0,p1,color);
    return vec4(c.xyz,c.w*step(cut,((p1.y-p0.y)+r)/(2.0*r)));
}

vec4 cutcircle2(float r,vec2 p0,vec2 p1,vec3 color,float cut){
    vec4 c=circle(r,p0,p1,color);
    return vec4(c.xyz,c.w*step(cut,1.0-((p1.y-p0.y)+r)/(2.0*r)));
}

vec3 smiley(vec2 p){
    p*=4.0;
    p.x+=0.5+fract(time);
    p.y=1.0-p.y;
    p=fract(p);
    vec3 c=vec3(0);
    //yellow
    vec4 temp=circle(0.45,vec2(0.5),p,vec3(0.9,0.8,0.2));
    c=mix(c,temp.xyz,temp.w);
    //mouth border
    temp=cutcircle2(0.34,vec2(0.47,0.42),p,vec3(0),0.45);
    c=mix(c,temp.xyz,temp.w);
    //mouth inside
    temp=cutcircle2(0.3,vec2(0.47,0.4),p,vec3(0.5,0.0,0.2),0.45);
    c=mix(c,temp.xyz,temp.w);
    //eye1 border
    temp=cutcircle1(0.15,vec2(0.25,0.62),p,vec3(0),0.2);
    c=mix(c,temp.xyz,temp.w);
    //eye1 inside
    temp=cutcircle1(0.12,vec2(0.25,0.63),p,vec3(1),0.2);
    c=mix(c,temp.xyz,temp.w);
    //eye2 border
    temp=cutcircle1(0.15,vec2(0.63,0.62),p,vec3(0),0.2);
    c=mix(c,temp.xyz,temp.w);
    //eye2 inside
    temp=cutcircle1(0.12,vec2(0.63,0.63),p,vec3(1),0.2);
    c=mix(c,temp.xyz,temp.w);
    //eye1 pupil
    temp=circle(0.05,vec2(0.69,0.69),p,vec3(0));
    c=mix(c,temp.xyz,temp.w);
    //eye2 pupil
    temp=circle(0.05,vec2(0.31,0.69),p,vec3(0));
    c=mix(c,temp.xyz,temp.w);
    return c;
}

void main( void ) {
    vec2 p=gl_FragCoord.xy/resolution-vec2(0.5,0.0);
    p.x*=resolution.x/resolution.y;
    p*=4.0;
    vec2 p2=normalize(p)/length(p);
    float a=circleDistance(p2);
    glFragColor=vec4(mix(background(p-vec2(0.0,2.0)),smiley(p2),a),1.0);    
}

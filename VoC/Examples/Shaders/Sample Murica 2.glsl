#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415926535
#define SR 0.04
#define N 5.
#define TH (PI/(2.*N))

bool star(vec2 pos)
{
    pos += vec2(-0.05,-0.05);
    float l = length(pos);
    float a = abs(mod(atan(pos.y,pos.x)+0.5*PI+time,2.*PI/N)-PI/N);
    float r = (SR*tan(TH))/(sin(a)+tan(TH)*cos(a));
    if(l<r)
        return true;
    return false;
    
}

vec4 meriken( vec2 pos ) {

    vec3 red= vec3(1,0,0);
    vec3 white= vec3(1,1,1);
    vec3 blue= vec3(0,0,1);
    #define nstripe 13.
    vec3 res= mix(red, white, (sign(sin(pos.y*nstripe*3.14+3.14))+1.)/2.);
    float l= .8;
    float h= (7.)/(nstripe);
    if(pos.x< l && 1.-pos.y<h){
        res= blue;
        if( star(pos - vec2(floor(pos.x*10.)*.1, floor(pos.y*11.)/11.)))
        
           res= white;
    }
    return vec4( res, 1. );

}

float mp(vec3 p) {
    return 1.0 - dot(abs(p), vec3(0, 1, 0)) + (cos(p.z+time) + cos(p.x+time)) * 0.3;
}

void main( void ) {
    vec2 pos = ( gl_FragCoord.xy/resolution.y ) * 2.0 - 1.0;
    vec3 dir = normalize(vec3(pos, 1.0));
    vec3 org = vec3(100.0, 0.0, time);
    float t = 0.0;
    for(int i = 0 ; i < 100; i++) {
        t += mp(org + dir * t);
    }
    vec3 ip = org + dir * t;
    vec4 col = meriken(mod(ip.xz, 1.0));
    glFragColor = col + t * 0.04;
    glFragColor.xyz += dir.yzx * 0.4;
}

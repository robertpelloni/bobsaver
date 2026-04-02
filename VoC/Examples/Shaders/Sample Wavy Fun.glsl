#version 420

// original https://www.shadertoy.com/view/Ns2GDw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define count 6
#define freqVar .3
#define freq 5.
#define wobble .5
#define shiftspeed 2.
float x;
vec2 uv;
float wave(float amp, float size){
    return (1.-smoothstep(
        abs(amp*sin(
            sin(time)*amp+freqVar*x*(sin(time)+freq)+time*shiftspeed
        )*sin(time*wobble) - uv.y),
        0.,
        0.1*size
    ));
}

float psin(float x){
    return (sin(x)+1.)*.5;
}

// is this the most efficient? no. Did I figure it out myself? yeah :D
vec3 hsv2rgb(vec3 hsv){
    return hsv.z*((1.-hsv.y) + hsv.y * vec3(
        max(0.,min(1.,1.5-abs(6.*(hsv.x-0.-1./6.)))),
        max(0.,min(1.,1.5-abs(6.*(hsv.x-1./3.-1./6.)))),
        max(0.,min(1.,1.5-abs(6.*(hsv.x-2./3.-1./6.))))
    ));
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    uv = gl_FragCoord.xy/resolution.xy;
       
    uv-=.5;
    uv*=2.;

    x = uv.x * 5.;

              

    vec3 b = vec3(0.);
    for(int i=1; i<count+1; i++){
        //b+=wave(muls[i].x)*muls[i].y;
        float mul= 1./float(i);
        float add = float(i)*.2;

        float size = psin(time+float(i))+.2;
        float gmul = i==count/2?-2.:1.;

        float p=.2*float(i)/float(count);
        vec3 color = hsv2rgb(vec3(p+fract(time*.1),1.,1.));

        b += color*(gmul* psin((sin(time)*float(i)*3.)*wave(mul, size)) * psin(time*(1.+add)+add));
    }

    // Output to screen
    glFragColor = vec4(b,1.0);
}

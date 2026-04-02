#version 420

// original https://www.shadertoy.com/view/fsc3zX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359
#define PI2 6.28309265359

float n21(vec2 n) {
    return fract(sin(dot(n, vec2(12.9898 + floor(1.), 4.1414))) * 43758.5453);
}

float sdBox( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

vec3 renderPlasmaOriginal(vec2 uv) {
    for(float i = 1.0; i < 10.0; i++){
        uv.x += 0.6 / i * cos(i * 2.5* uv.y + time);
        uv.y += 0.6 / i * cos(i * 1.5 * uv.x + time);
    }
    vec3 col = 0.5 + 0.5*sin(time+uv.xyx+vec3(0,2,4));
    return col/(2.1*abs(cos(time-uv.y-uv.x)));
}

float sdCircle(vec2 p, vec2 pos, float radius) {
    return distance(p, pos) - radius;
}

mat2 rot2d(float a) {
    return mat2(vec2(sin(a), cos(a)), vec2(-cos(a), sin(a)));
}

vec3 background(vec2 uv) {
    uv += vec2(0.);
    float d = 1. - step(.5, length(uv));
    float a = atan(uv.x, uv.y) + PI;

    float segments = 18.;
    float sector = floor(segments * (a/PI2));

    vec3 color = vec3(0.);

    if (a < PI) {
        color = vec3(.9, .2, .1) * d;
    } else {
        color =vec3(.5, .6, .2) * d;
    }

    float box = sdBox(abs(uv * rot2d(PI/3.3)), vec2(.3, .5));
    if (a < PI/2. || (a > PI && a < PI + PI/2.)) {
        float d = (1. - step(.0, box));
        if (d > 0.) {
            color = d * vec3(.0, .4, .9);
        }
        color -= (1. - step(.0, abs(box) - .005)) * vec3(2.);
    }

    float box2 = sdBox(abs(uv * rot2d(-PI/5.)), vec2(.3, .5));
    float d1 = (1. - step(.0, box2));
    if ( a < PI && a > PI/2.) {
        if (d1 > 0.) {
            color = d1 * vec3(.5, .6, .2);
        }
        color -= (1. - step(.0, abs(box2) - .005)) * vec3(2.);

    }

    if ( a > PI + PI/2. ) {
        if (d1 > 0.) {
            color = d1 * vec3(.9, .2, .1);
        }
        color -= (1. - step(.0, abs(box2) - .005)) * vec3(2.);
    }

    color *= step(.005, abs(uv.x));
    color *= step(.005, abs(uv.y));

    return max(vec3(0.), color / abs(sin(uv.y*(13. + cos(time)*5.) + time + cos(uv.x*(20. + sin(time)*5. + sin(uv.y*12.)*4.) + time*2.)))*.48);
}

void main(void) {
    float n = n21(vec2(floor(time)));
    float n1 = n21(vec2(floor(time) + 1.));
    float nn = mix(n, n1, fract(time));
    
    float _SegmentCount = 7.;

    vec2 mouse = mouse*resolution.xy.xy/resolution.xy;

    vec2 shiftUV = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;

    shiftUV *= rot2d((nn - .5) * PI/2.);

    float radius = sqrt(dot(shiftUV, shiftUV));
    float angle = atan(shiftUV.y, shiftUV.x) + mouse.x;

    float segmentAngle = PI2 / _SegmentCount;

    float wid = floor((angle + PI) / segmentAngle);

    angle -= segmentAngle * floor(angle / segmentAngle);

    angle = min(angle, segmentAngle - angle);

    vec2 uv = vec2(cos(angle), sin(angle)) * radius;// + sin(time) * 0.1;

    vec3 color = vec3(0.);
    

    color += background((uv/1.4 + vec2(sin(time - uv.y*(3. + nn))*.08, cos(time + uv.x)*.05)) * rot2d(time*.3 + uv.x*sin(time + uv.y/4. + uv.x*4.) * 4.*nn));
    color += renderPlasmaOriginal(uv * rot2d(time*.2 + nn) + vec2(sin(time + uv.x - nn * 2.), cos(time + uv.y))*(.2 + nn *.1)) *.3;
  

    glFragColor = vec4(color, 1.0);
}

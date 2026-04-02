#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 getColor(float phase);

#define stripes 2.
#define k 4.
    vec2  surfacePos = (gl_FragCoord.xy - resolution.xy*.5) / resolution.y;
#define sx surfacePos.x
#define sy surfacePos.y

float PI = 4.*atan(1.);

void main(void) {
    vec3 c = getColor(time*0.7*PI);
    glFragColor = vec4(c, 1.0);

}

vec3 getColor(float phase) {
    float x = sx*2.3;
    float y = sy*2.3;
    float theta = atan(y, x) * 3.;
    float r = log(x*x + y*y) ;//(mouse.x*2.);
    float c = 0.;
    float tt;
    for (float t=0.; t<k; t++) {
        float tt = t * PI;
        c += cos((theta*cos(tt)*t - time + c + r*sin(t+c*0.05)*t) * stripes + phase);
    }
    //c = (c+k) / (k*2.);
    //c = c > 0.5 ? 1. : 0.;
    c/=3.;
    return vec3((c), c*c, -c);
    //return vec3(c, c, c);

}

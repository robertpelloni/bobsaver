#version 420

// original https://www.shadertoy.com/view/fdjGDc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define ITERS 267.
#define PI 3.1415926

vec2 rotate(vec2 v, float a) {
    float s = sin(a);
    float c = cos(a);
    mat2 m = mat2(c, -s, s, c);
    return m * v;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.y;
    vec2 frag = gl_FragCoord.xy;
    vec2 res = resolution.xy;
    uv -= 0.5;
    //uv = abs(uv);
    //uv = rotate(uv, PI * 0.25);
    //uv = abs(uv);

    

    float tz = 0.6 - 0.45*cos(0.115*time);
    float zoom = pow( 0.5, 13.0*tz );

    // -0.05 , 0.6805
    vec2 c = vec2(-0.04952,.6746265) + uv * zoom;
    vec2 z;
    float r = 20.;
    float r2 = r*r;
    float iter;
    vec2 zPrev;
    for(iter = 0.; iter < ITERS ; iter++) {
        zPrev = rotate(z, time * 4.);
        z = vec2(z.x * z.x - z.y * z.y, 2.*z.x*z.y) + c;
        if(dot(z, zPrev) > r2) break;
    }
    float angle = atan(z.y,z.x);
    if (iter == ITERS) {
        vec3 col = vec3(0.3,0.8,0.3);
        col *= sin(length(z)*25.)*0.3 + 1.;
        glFragColor = vec4(col, 1.0);
        return;
    }
    float dist = length(z);
    float fracIter = (dist-r) / (r2-r);
    fracIter = log(dist) / log(r) - 1.;
    iter += (fracIter + 3.) * (fracIter + 3.);
    
    float m  = sqrt(iter / ITERS);
    vec3 col =  0.5 * cos(vec3(PI / 20. + (sin(time * 0.15)*0.5 + 0.5) ,0.45,0.05) * m * 100.) + 0.5;
    
    col *= vec3(smoothstep(5.,0.,fracIter));
    
    col *= 1. + sin(angle * 2.)*0.2;
    
    glFragColor = vec4(col, 1.0);
}

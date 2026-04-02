#version 420

// original https://www.shadertoy.com/view/WttSzN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// NASA "The Worm" classic logo

#define W 0.18
#define B 0.01

#define DEG 3.141592653589793 / 180.
#define _S smoothstep

mat2 rotate(float rot) {
    return mat2(cos(rot), -sin(rot), sin(rot), cos(rot));
}

float line(vec2 uv, float len) {
    float col = 0.;
    if (abs(uv.y) <= len) {
        col = _S(-W/2.,-W/2.+B,uv.x) - _S(W/2.-B,W/2.,uv.x);
    }
    return col;
}

float arc(vec2 uv, float r, float r2, float angle) {
    float col = 0.;
    if (atan(uv.x/uv.y) < angle && uv.y >= 0.) {
        col = _S(r,r-B,length(uv))-_S(r2,r2-B,length(uv));
    }
    return col;
}

float N(vec2 uv) {
    float col = line((vec2(-.0345,.1)-uv*sign(uv.y))*rotate(-DEG*19.), .15);
    col += arc((vec2(-.221,.194)-uv*sign(uv.y))*rotate(DEG*-180.), .236, .066, DEG*71.);
    col += line((vec2(.367,.106)-uv*sign(uv.x+uv.y)), .3);
    return col;
}

float A(vec2 uv) {
    uv.x = abs(uv.x);
    float col = 0.;
    if (uv.y > -.29) {
        col = line((vec2(.28,.0)-uv)*rotate(DEG*-21.), .4);
        col += arc((vec2(0.,.321)-uv)*rotate(DEG*-90.), .236, .066, -DEG*21.);
    }
    return col;
}

float S(vec2 uv) {
    uv *= rotate(DEG * 90.);
    uv.x = -uv.x;
    float col = line((vec2(.0,.07)-uv*sign(uv.y)), .07);
    col += arc((vec2(-.166,0.14)-uv*sign(uv.y))*rotate(DEG*-180.), .256, .086, DEG*90.);
    col += line((vec2(.332,.105)-uv*sign(uv.x+uv.y)), .245);
    return col;
}

// Star copied from BigWIngs Starfield shader
// https://www.shadertoy.com/view/tlyGW3
float star(vec2 uv, float flare) {
    float d = length(uv);
    float m = .05/d;
    
    float rays = max(0., 1.-abs(uv.x*uv.y*1000.));
    m += rays*flare;
    uv *= rotate(DEG*45.);
    rays = max(0., 1.-abs(uv.x*uv.y*1000.));
    m += rays*.3*flare;
    
    m *= smoothstep(1., .2, d);
    return m;
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy) / resolution.y;
    uv *= 2.15; uv.x += .05; uv.y += .2;
        
    float logo = N(uv-vec2(-1.19,.13));
    logo += uv.x < .107 ? A(uv-vec2(-.31,0.)) : 0.;
    logo += uv.x > .107 || uv.y > 0. ? S(uv-vec2(.45,.125)) : 0.;
    logo += A(uv-vec2(1.25,0.));
    vec3 logoColor = vec3(logo,.0,.15*logo); 
    
    float star = star(rotate(time/10.)*(uv-vec2(1.,.7)), 1.);
    vec3 starColor = vec3(star*cos(time),.6*star,star*sin(time/.7));
    
    glFragColor = vec4(logoColor + starColor, 1.);
}

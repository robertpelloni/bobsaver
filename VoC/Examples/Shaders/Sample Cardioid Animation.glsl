#version 420

// original https://www.shadertoy.com/view/WtK3zy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float r = 0.2;
const vec2 h = vec2(0.01, 0.0);
const float pi = 3.141592;

float disttoline(vec2 a, vec2 b, vec2 p) {
     return abs( (b.y-a.y)*p.x - (b.x-a.x)*p.y + b.x*a.y-a.x*b.y ) / sqrt( dot(b-a, b-a) ) 
        * (length(a-p) + length(b-p) - length(a-b) < 0.001 ? 1.0 : 3000.0);   
}

float sq(float x) {
    return x*x;   
}
float f(vec2 uv) {
    return sq(dot(uv,uv)) + 4.0*r*uv.x*dot(uv,uv) - 4.0*sq(uv.y)*sq(r);  
}
vec2 fparam(float theta) {
    return 2.0*r*(1.0-cos(theta))*vec2(cos(theta), sin(theta));   
}
vec2 grad(vec2 uv) {
    return vec2(4.0*uv.x*uv.x*uv.x+4.0*uv.x*sq(uv.y)+12.0*r*sq(uv.x)+4.0*r*sq(uv.y),
                4.0*uv.y*uv.y*uv.y+4.0*uv.y*sq(uv.x)+8.0*r*uv.x*uv.y-8.0*sq(r)*uv.y);   
}

#define grad2d(uv, func) (vec2( func(uv+h.xy) - func(uv-h.xy), func(uv+h.yx) - func(uv-h.yx) ) / (2.0*h.x))

#define sdf2d(uv, g, func) ((func(uv)) / length(g))

void main(void)
{
    vec2 uv = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
    
    vec2 g = grad2d(uv, f);
    float de = sdf2d(uv, g, f);
    
    float theta = atan(uv.y, -uv.x) + pi;
    float thetamax = mod(-time, 2.0*pi);
    vec2 curvepoint = fparam(-thetamax);
    float factor = step(theta, thetamax);
    
    //account for retard gradients
    de += step(abs(uv.y), 0.017) * step(-0.03, uv.x) * step(uv.x, 0.0);// + mod(floor(theta*pi*50.),2.0);    
    
    vec3 color;
    vec3 bgcolor = vec3(0.9,0.8,0.6) * pow(2.0, -length(uv));
    color = mix( bgcolor, mix( vec3(0.3, 0.2, 0.4), bgcolor, factor ), smoothstep(0.01, 0.0, abs(de)) );
    vec2 centre1 = vec2(-r, 0.0);
    vec2 centre2 = 2.0*r*vec2(cos(time), sin(time)) - vec2(r, 0.0);
    color = mix(vec3(0.0, 0.0, 0.0), color, smoothstep(0.0, 0.01, abs(length(uv - centre1) - r)));
    vec3 color2 = vec3(1.0, 0.0, 0.0);
    color = mix(color2, color, smoothstep(0.0, 0.01, abs(length(uv - centre2) - r)));
    color = mix(vec3(0.0), color, smoothstep(0.02, 0.03, length(uv - curvepoint)));

    float linedist = disttoline(centre2, curvepoint, uv);
    color = mix(vec3(0.0), color, smoothstep(0.0, 0.01, linedist) * smoothstep(0.01, 0.02, length(uv - centre2)));
    
    color = mix(color, vec3(0.4, 0.07, 0.0), smoothstep(theta, theta-pi, thetamax) 
                            * smoothstep(0.0,-0.02,de)
                            * smoothstep(0.0, 0.02, (length(uv - centre1) - r))
                               * smoothstep(0.0, 0.01, (length(uv - centre2) - r))); 
    
    
    glFragColor = vec4(color,1.0);
}

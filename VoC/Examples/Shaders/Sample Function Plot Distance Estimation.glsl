#version 420

// original https://www.shadertoy.com/view/tsV3Dz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
    Distance estimation 
    http://iquilezles.org/www/articles/distance/distance.htm
    We take a function f(x) = y
    We compute the distance to the isosurface f(uv.x) - uv.y = 0, which will actually just plot the function f
*/
#define PI 3.14159265359
float scale = 6.;
float eps;

float rectangle(vec2 center, vec2 size, vec2 uv) {
    vec2 ceva;
    ceva = step(center - size, uv) - step(center + size, uv);
    return ceva.x * ceva.y;
}

mat2 rotate2d(float _angle){
    return mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle));
}

float frac(float x) {    //distance to closest integer
    return min(fract(x), fract(1. - x));   
}
vec2 frac(vec2 uv) {
     return min(fract(uv), fract(1. - uv));   
}

float random(float x) {
     return fract( sin(x) * 43758.545 );   
}

float smoothsaw(float x) {
     return smoothstep(0.0, 1.0, fract(x));   
}

float steprandom(float x) {
     return random(floor(x));
}

float randomsaw(float x) {
     return smoothsaw(x) * steprandom(x);   
}

float noise(float x) {
     return randomsaw(x) - randomsaw(x - 1.) + steprandom(x - 1.);   
}
float fractalnoise(float x) {
     return noise(x) + .5*noise(x/.5) + .25*noise(x/.25) + .125*noise(x/.125) + .0625*noise(x/.0625);
}

//Write your function here
float f(float x)                                 
{
    //return sin(5.0*x);
    //return -43.*pow(x,6.0)/322560. + 2071.*pow(x,5.)/161280.;
    return sin(8.*x + time) * cos(x);
}     

//analytical gradient, needs to be programmed for any particular function
vec2 grad1(float x)                                                 
{
    return vec2(1.0, cos(x)*sin(x*x) + 2.0*x*cos(x*x)*sin(x));
}

//central differences method: numerical gradient
vec2 grad2(float x) {
     float h = 0.00001;
    return vec2(1.0, (f(x+h) - f(x-h)) / (2.0*h));
}

//signed distance estimation
float sdf(vec2 uv, vec2 g) {
     float v = f(uv.x);
    float de = (v - uv.y)/length(g);
    return de;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    float aspect = resolution.x / resolution.y;
    //scale += mouse*resolution.xy.y / 10.;
    eps = scale / resolution.y;     //pixel size, for constant thickness independent of resolution
    
    uv.x *= aspect;
    uv -= vec2(aspect/2., .5);
    uv *= scale;
    //uv = rotate2d(sin(time) * PI) * uv;
    //uv.x += 2.*sin(time);
    
    vec2 g = grad2(uv.x);
    //vec2 g = mix(grad2(uv.x), vec2(1., 0.), mod(floor(fract(time / 3.) * 2.), 2.));
    float de = sdf(uv, g);
    vec3 color;
    color = mix(vec3(.9, .555, 0.54), 
                mix(vec3(.0), vec3(.9, .97, .8), 1. - smoothstep(-2.*eps, .0, de)),
                1. - smoothstep(.0, 2.*eps, de));
    //color = vec3(smoothstep(0., 2.*eps, abs(de)));
    
    color = mix(color, color * vec3(.1, .5, .6), smoothstep(-eps, 0., uv.x) - smoothstep(0., eps, uv.x));    
    color = mix(color, color * vec3(.1, .5, .6), smoothstep(-eps, 0., uv.y) - smoothstep(0., eps, uv.y));
    
    //grid
    
    //color = mix(color, color * vec3(.1, .5, .6), smoothstep(-1.*eps, 0., frac(uv.x)) - smoothstep(0., 1.*eps, frac(uv.x)));
    //color = mix(color, color * vec3(.1, .5, .6), smoothstep(-1.*eps, 0., frac(uv.y)) - smoothstep(0., 1.*eps, frac(uv.y)));
    
    //only ruler
    if(abs(uv.x) > 8. * eps || abs(uv.y) > 8. * eps) {    //dont draw in the origin
        color = mix(color, color * vec3(.1, .5, .6), rectangle(vec2(.0, round(uv.y)), vec2(5.*eps, eps), uv));
        color = mix(color, color * vec3(.1, .5, .6), rectangle(vec2(round(uv.x), .0), vec2(eps, 5.*eps), uv));
    }
    
    glFragColor = vec4(color, 1.0);
}

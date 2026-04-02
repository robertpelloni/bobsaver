#version 420

// original https://www.shadertoy.com/view/7t2yzR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159
#define s(v,l) smoothstep(l/R.y,0.,v) // AA
#define r(a) (mat2(cos(a),sin(a),-sin(a),cos(a))) // 2d rotation matrix
#define R resolution.xy

vec2 Mobius(vec2 p, vec2 z1, vec2 z2){

    z1 = p - z1; p -= z2;
    return vec2(dot(z1, p), z1.y*p.x - z1.x*p.y)/dot(p, p);
}

vec2 spiralZoom(vec2 p, vec2 offs, float n, float spiral, float zoom, vec2 phase){
    
    p -= offs;
    float a = atan(p.y, p.x)/6.283 - time*.1;
    float d = log(length(p));
    return vec2(a*n + d*spiral, a - d*zoom) + phase;
}

float circle (vec2 p, vec2 c, float r, float w){
    return abs(length(p-c)-r)-w;
}

vec3 pattern(vec2 u, vec3 col) {
    u*=30.;
    vec2 grid = floor(u);
    float id = grid.x;
    vec2 cent = u-grid-.5;
    cent = r(PI/2. * floor(id * 7.)) * cent;

    vec3 col1 = col;
    vec3 col2 = col;
    
    col = mix(col, vec3(1.,1.,.1), s(circle(cent, vec2(.5,-.5), .95, .09),3.));
    col = mix(col, vec3(1.,1.,.1), s(circle(cent, vec2(-.5,-.5), .95, .09),3.));
    col = mix(col, vec3(1.,1.,.1), s(circle(cent, vec2(-.5,.5), .95, .09),3.));
    col = mix(col, vec3(1.,1.,.1), s(circle(cent, vec2(.5,.5), .95, .09),3.));
  
    col = mix(col, col1, s(circle(cent, vec2(.5,-.5), .95, .06),3.));
    col = mix(col, col1, s(circle(cent, vec2(-.5,-.5), .95, .06),3.));
    col = mix(col, col1, s(circle(cent, vec2(-.5,.5), .95, .06),3.));
    col = mix(col, col1, s(circle(cent, vec2(.5,.5), .95, .06),3.));
    
    col1 = col;
    
    col = mix(col, col1, s(circle(cent, vec2(.5,-.5), 1., .01),3.));
    col = mix(col, col1, s(circle(cent, vec2(-.5,-.5), 1., .01),3.));
    col = mix(col, col1, s(circle(cent, vec2(-.5,.5), 1., .01),3.));
    col = mix(col, col1, s(circle(cent, vec2(.5,.5), 1., .01),3.));
    
    col = mix(col, vec3(1.), s(circle(cent, vec2(.5,-.5), .21, .06),3.));
    col = mix(col, vec3(1.), s(circle(cent, vec2(-.5,-.5), .21, .06),3.));
    col = mix(col, vec3(1.), s(circle(cent, vec2(-.5,.5), .21, .06),3.));
    col = mix(col, vec3(1.), s(circle(cent, vec2(.5,.5), .21, .06),3.));
    
    col = mix(col, col1, s(circle(cent, vec2(.5,-.5), .21, .03),3.));
    col = mix(col, col1, s(circle(cent, vec2(-.5,-.5), .21, .03),3.));
    col = mix(col, col1, s(circle(cent, vec2(-.5,.5), .21, .03),3.));
    col = mix(col, col1, s(circle(cent, vec2(.5,.5), .21, .03),3.));
    
    col = mix(col, vec3(1.), s(circle(cent, vec2(-.5,.5), .5, .08),3.));
    col = mix(col, vec3(1.), s(circle(cent, vec2(.5,-.5), .5, .08),3.));
    
    col = mix(col, col2, s(circle(cent, vec2(-.5,.5), .5, .06),3.));
    col = mix(col, col2, s(circle(cent, vec2(.5,-.5), .5, .06),3.));
    
    col = mix(col, vec3(1.), s(circle(cent, vec2(.5,-.5), .06, .01),3.));
    col = mix(col, vec3(1.), s(circle(cent, vec2(-.5,-.5), .06, .01),3.));
    col = mix(col, vec3(1.), s(circle(cent, vec2(-.5,.5), .06, .01),3.));
    col = mix(col, vec3(1.), s(circle(cent, vec2(.5,.5), .06, .01),3.));
    
    return col;
}

vec3 final_image(vec2 uv)
{

    vec3 col = vec3(max(1. - length(uv), 0.)*.025); 
    uv = Mobius(uv, vec2(-.75, cos(time)*.25), vec2(.5, sin(time)*.1));
    uv = spiralZoom(uv, vec2(0.), 2., 0., .4, vec2(-1, 1)*time*.1);
    col = pattern(uv.yx*.2, col);
    return col;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - R*.5)/resolution.y;
    vec3 col = final_image(uv);
    glFragColor = vec4(sqrt(col),1.0);
}

#version 420

// original https://www.shadertoy.com/view/WlVGRm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* Using https://www.iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm for the rhombus sdf, 
https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm for the repetition of the tiling
using rhombus tesselation functions from https://www.shadertoy.com/view/tlGGDR
spiral stuff based on http://isohedral.ca/escher-like-spiral-tilings/
*/

float tau = 6.28318530718;
float pi = 3.14159265358979;
float sqrt_2 = 1.41421356237;
float sqrt_half = 0.70710678118;

float ndot(vec2 a, vec2 b ) { return a.x*b.x - a.y*b.y; }

float sdRhombus( in vec2 p, in vec2 b ) 
{
    vec2 q = abs(p);
    float h = clamp((-2.0*ndot(q,b)+ndot(b,b))/dot(b,b),-1.0,1.0);
    float d = length( q - 0.5*b*vec2(1.0-h,1.0+h) );
    return d * sign( q.x*b.y + q.y*b.x - b.x*b.y );
}

vec2 rotatePoint(vec2 p, float theta){
    return vec2(p.x*cos(theta)-p.y*sin(theta),p.x*sin(theta)+p.y*cos(theta));
}

vec2 translatePoint(vec2 p, vec2 t){
    return p - t;
}

float tesselatedRhombiPos(float theta1, vec2 p){
    vec2 p_ = p;
    p_ = translatePoint(p_,vec2(0.5,0.5));
    p_ = rotatePoint(p_,-pi/4.0);
    float d = sdRhombus(p_, vec2(cos(pi/4.0),sin(pi/4.0)));
    p_ = p;
    p_ = translatePoint(p_,vec2(0.5+0.5*cos(theta1),1.0+0.5*sin(theta1)));
    p_ = rotatePoint(p_,-theta1/2.0);
    d = min(d,sdRhombus(p_, vec2(cos(theta1/2.0),sin(theta1/2.0))));
    p_ = p;
    p_ = translatePoint(p_,vec2(1.0+0.5*sin(theta1),0.5-0.5*cos(theta1)));
    p_ = rotatePoint(p_,(pi-theta1)/2.0);
    d = min(d,sdRhombus(p_, vec2(cos(theta1/2.0),sin(theta1/2.0))));
    p_ = p;
    p_ = translatePoint(p_,vec2(1.0 + sqrt_half*cos(theta1-pi/4.0),1.0 + sqrt_half*sin(theta1-pi/4.0)));
    p_ = rotatePoint(p_,-theta1-pi/4.0);
    d = min(d,sdRhombus(p_, vec2(cos(pi/4.0),sin(pi/4.0))));
    return d;
}

vec2 opRep( in vec2 p, in vec2 c)
{
    vec2 q = mod(p+0.5*c,c)-0.5*c;
    return q;
}

float getTesselatedRhombusVal(vec2 p, float theta1){
    vec2 a_vec = vec2(cos(theta1),1.0+sin(theta1));
    vec2 b_vec = vec2(1.0+sin(theta1),-cos(theta1));
    float angle = atan(a_vec.y,a_vec.x);
    float len = length(a_vec);
    vec2 offset = vec2(len,len);
    vec2 p_ = rotatePoint(p, -angle);
    p_ = opRep(p_, offset);
    float val = tesselatedRhombiPos(theta1,rotatePoint(p_, angle));
    val = min(val, tesselatedRhombiPos(theta1,rotatePoint(p_ + vec2(offset.x,0.0), angle)));
    val = min(val, tesselatedRhombiPos(theta1,rotatePoint(p_ - vec2(offset.x,0.0), angle)));
    val = min(val, tesselatedRhombiPos(theta1,rotatePoint(p_ + vec2(0.0,offset.y), angle)));
    val = min(val, tesselatedRhombiPos(theta1,rotatePoint(p_ - vec2(0.0,offset.y), angle)));
    val = min(val, tesselatedRhombiPos(theta1,rotatePoint(p_ + vec2(offset.x,offset.y), angle)));
    val = min(val, tesselatedRhombiPos(theta1,rotatePoint(p_ - vec2(offset.x,offset.y), angle)));
    val = min(val, tesselatedRhombiPos(theta1,rotatePoint(p_ + vec2(-offset.y,offset.y), angle)));
    val = min(val, tesselatedRhombiPos(theta1,rotatePoint(p_ - vec2(-offset.y,offset.y), angle)));
    return val;
}

float getFilteredRhombusVal(vec2 p, float theta1){
    float val = 0.6*getTesselatedRhombusVal(p, theta1);
    //basic filter to prevent aliasing crap
    val += 0.1*getTesselatedRhombusVal(p+vec2(0.01,0.0), theta1);
    val += 0.1*getTesselatedRhombusVal(p-vec2(0.01,0.0), theta1);
    val += 0.1*getTesselatedRhombusVal(p+vec2(0.0,0.01), theta1);
    val += 0.1*getTesselatedRhombusVal(p-vec2(0.0,0.01), theta1);
    return val;
}

float sdCircle( vec2 p, float r )
{
  return length(p) - r;
}

void main(void)
{
    float t = time/2.0;
    // Change these to any integer for more fun
    vec2 ab = vec2(7.0,5.0);
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv -= vec2(0.5,0.5);
    vec2 cart = uv * resolution.xy / resolution.x * 12.0;
    // cart /= length(ab);
    float angle = atan(cart.y,cart.x);
    float r = length(cart)/2.0;
    cart = vec2(angle,r);
    float rhombus_theta = mod(t,2.0)*pi/2.0;
    vec2 a_vec = vec2(cos(rhombus_theta),1.0+sin(rhombus_theta));
    vec2 b_vec = vec2(1.0+sin(rhombus_theta),-cos(rhombus_theta));
    vec2 ab_vec = ab.x*a_vec + ab.y*b_vec;
    float theta=atan(ab_vec.y,ab_vec.x);
    float l = length(ab_vec)/tau;
    
    vec2 p = vec2(cart.x*cos(theta)-cart.y*sin(theta),
                  cart.x*sin(theta)+cart.y*cos(theta))*l;
    vec2 offset_vec = (a_vec)*mod(t,2.0)/2.0;
    p = p - offset_vec;
    //p = p + vec2(offset_vec.x*cos(-theta)-offset_vec.y*sin(-theta), offset_vec.x*sin(-theta)+offset_vec.y*cos(-theta));
    vec3 col = vec3(1.0);
    float x_dist = min(abs(p.x-ceil(p.x)),abs(p.x-floor(p.x)));
    float y_dist = min(abs(p.y-ceil(p.y)),abs(p.y-floor(p.y)));
    float dist = min(x_dist,y_dist);
    x_dist = mod(p.x,1.0);
    y_dist = mod(p.y,1.0);
    float val = getFilteredRhombusVal(p, rhombus_theta);
    col = mix(col,vec3(0.0),0.5 + 0.5*cos(val*pi*8.0+t*5.0));
    /*float d = abs(abs(abs(sdCircle(vec2(x_dist,y_dist)-vec2(0.5,0.5),0.3))-0.19)-0.09)-(0.05+0.025*sin(t+r));
    if (d < 0.0){
        col = mix(col,vec3(0.0),1.0-(abs(d)/0.2));
    }*/
    // Output to screen
    glFragColor = vec4(col,1.0);
}

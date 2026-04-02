#version 420

// tweetfield

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float s, c;
#define rotate(p, a) mat2(c=cos(a), s=-sin(a), -s, c) * p
#define rotateTo(p, a) mat2(c=a.y, s=a.x, -s, c) * p

#define res resolution.xy

// hash without sine
// https://www.shadertoy.com/view/4djSRW
//#define MOD3 vec3(443.8975, 397.2973, 491.1871) // uv range
#define MOD3 vec3(.1031, .11369, .13787) // int range
#define MOD4 vec4(.1031, .11369, .13787, .09987) // int range
float hash11(float p) {
    vec3 p3  = fract(vec3(p) * MOD3);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}
float hash12(vec2 p) {
    vec3 p3  = fract(vec3(p.xyx) * MOD3);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}
float hash13(vec3 p3) {
    p3  = fract(p3 * MOD3);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}
vec2 hash21(float p) {
    vec3 p3 = fract(vec3(p) * MOD3);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract(vec2((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y));
}
vec2 hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * MOD3);
    p3 += dot(p3, p3.yzx+19.19);
    return fract(vec2((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y));
}
vec3 hash32(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * MOD3);
    p3 += dot(p3, p3.yxz+19.19);
    return fract(vec3((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y, (p3.y+p3.z)*p3.x));
}
// 4 out, 1 in...
vec4 hash41(float p) {
    vec4 p4 = fract(vec4(p) * MOD4);
    p4 += dot(p4, p4.wzxy+19.19);
    return fract(vec4((p4.x + p4.y)*p4.z, (p4.x + p4.z)*p4.y, (p4.y + p4.z)*p4.w, (p4.z + p4.w)*p4.x));
}
vec4 hash42(vec2 p) {
    vec4 p4 = fract(vec4(p.xyxy) * MOD4);
    p4 += dot(p4, p4.wzxy+19.19);
    return fract(vec4((p4.x + p4.y)*p4.z, (p4.x + p4.z)*p4.y, (p4.y + p4.z)*p4.w, (p4.z + p4.w)*p4.x));
}

float plane(vec2 p, vec2 n){ return dot(p, n); }

float ellipse(in vec2 p, float a, float r1, float r2) {
    float f;
    vec2 d = vec2(sin(a), cos(a));
    float pl1 = dot(p, d);
    float pl2 = dot(p, vec2(d.y, -d.x));
    return sqrt(pl1*pl1/r1+pl2*pl2/r2);
}

vec2 bird(in vec2 p, float t) {
    // initial transforms
    p.y -= 1.;
    p *= 4.;
    
    // inits
    float f = 1.;
    vec3 o = vec3(-1., 0., 1.);
    vec2 p2 = p + vec2(0., .4+.1*cos(5.4*t));
    
    // head
    f = min(f, ellipse(p2, 0., 1., 1.)-1.);
    
    // head tuft
    f = min(f, ellipse(p2-o.yz, 2.4, 1., .2)-.5);
    f = min(f, ellipse(p2-vec2(-.3, .9), 2., 1., .15)-.35);
    
    // beak cutout
    f = max(f, -ellipse(p2-o.zy*1.25, 0., 1., 1.)+.4);
    
    // beak
    f = min(f, ellipse(p2-.5*o.zy, 1.2+.2*cos(20.*t), 2., .1)-.75);
    f = min(f, ellipse(p2-.5*o.zy, 2.-.2*cos(20.*t), 2., .1)-.75);
    
    // neck
    f = min(f, ellipse(p2+1.1*o.yz, 0., 2., 2.)-.15);
    
    // body
    f = min(f, ellipse(p+2.75*o.yz, 0., 1., .5)-1.);
    f = min(f, ellipse(p+3.35*o.yz, 0., .75, 1.)-.8);
    
    // wings
    f = min(f, ellipse(p+vec2(.5, 1.9), 1.5+.25*cos(5.4*t), 1.5, .2)-.75);
    f = min(f, ellipse(p+vec2(-.5, 1.9), -1.5+-.25*cos(5.4*t), 1.5, .2)-.75);
    
    // feet
    f = min(f, ellipse(p+vec2(.35, 4.), -.2, .5, 1.)-.3);
    f = min(f, ellipse(p+vec2(-.35, 4.), .2, .5, 1.)-.3);
    
    // transfer majority of shape to mask
    float mask = f;
    
    // and clear f
    f = 0.;
    
    // eyes
    f = max(f, -ellipse(p2, 0., 1., 1.)+.45);
    f = min(f, ellipse(p2, 0., 1., 1.)-.2);
    f = max(f, -ellipse(p2-.17*o.yz, 0., 1., 1.)+.15);
    
    // aa-esque
    f = smoothstep(0., 32./res.y, f);
    mask = smoothstep(0., 64./res.y, mask);
    
    //f = .1 + .9*f;
    
    //f = clamp(f, 0., 1.);
    //mask = clamp(mask, 0., 1.);
    
    return vec2(f, mask);
}

vec2 birdstrip(in vec3 p, float time) {
    vec4 rv = hash42(floor(p.xz));
    
    // plane
    float pf = min(1., 1.5*p.y+.05);
    
    // repeat x
    p.x = fract(p.x) - .5;
    
    // random x offset
    p.x += .35*(.5-rv.z);
    
    // random flip left/right
    if(rv.x<.5) p.x *= -1.;
    
    // random size
    p *= 1.5*(1. - .2*rv.y);
    
    // return minimum of bird and plane
    return min(bird(p.xy, time+rv.x), vec2(1., pf));
    
    //return bird(p.xy, time+rv.x);
}

void main( void ) {
    // inits
    //vec2 res = iResolution.xy;
    vec2 p = (gl_FragCoord.xy-res/2.) / res.y;
    
    // initial transforms
    //p *= 2.;
    p.y += .35;
    
    
    // camera position & direction
    vec3 cpos = vec3( 0., 1.7, 0.);
    vec3 cdir = vec3(p-vec2(0., .95), 1.);
    
    // ofsset camera by time
    cpos.x += .3*time;
    
    // step through the planes!
    float f=0.;
    float alpha = 1.;
    const float I = 15.;
    for(float i = 1.; i<=I; i++) {
        // step camera position forward
        cpos += cdir;
        
        // offset x by random from z
        cpos.x += hash11(cpos.z);
        
        // shape: value and mask
        vec2 shape = birdstrip(cpos, time);
        
        // update alpha
        alpha -= 1.-shape.y;
        
        // break if alpha becomes useless
        if(alpha<0.) break;
        
        // blend in value
        f = mix(i/I+shape.x, max(f,shape.x), 1.-alpha);
    }
    
    f *= 1.5;
    
    // sanity checks
    //vec2 shape = birdstrip(vec3(p.xy*1.3, iTime), iTime);
    //shape=bird(p.xy*2., iTime);
     //f = mix(shape.x, .5, shape.y);
    
    
    glFragColor = vec4(vec3(f) * vec3(1.5, 1.25, 1.), 1.);
}

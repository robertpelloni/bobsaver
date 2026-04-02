#version 420

uniform float time;
uniform vec2         mouse;
uniform vec2         resolution;
uniform sampler2D     backbuffer;

out vec4 glFragColor;

//sphinx

#define timescale .05
#define aspect (resolution.x/resolution.y)
#define boundary gl_FragCoord.x <= 1. || gl_FragCoord.y <= 1. || gl_FragCoord.x >= resolution.x-1. || gl_FragCoord.y >= resolution.y-1.

vec4     pid(float p, float t, float e, float i);
float    line(vec2 p, vec2 a, vec2 b, float w);
float    hash(float v);
vec2    toworld(vec2 p);
vec3     hsv(vec3 v);

void    samplecross(vec2 uv, out vec4[5] s);
void    sampleneumann(vec2 uv, out vec4[5] s);

void main( void ) {
    vec2 uv     = gl_FragCoord.xy/resolution.xy;
    vec2 p         = toworld(uv);
    vec2 m         = toworld(uv-mouse+.5);
    
    //sample
    vec4 s[5];
    float ft    = time * timescale;
    if(hash(ft+uv.x)+hash(ft+uv.y)>.5)
    {
        sampleneumann(uv, s);
    }
    else
    {
        samplecross(uv, s);
    }
    
    
    for(int i = 0; i < 5; i++)
    {
        s[2] = mix(s[2], max(s[2], s[i]), .5);    
    }
    
    
    float t = min(s[2].x, s[2].y);
    //float t = s[2].w;
    
    
    //pid control
    vec4 c[4]; 
    c[0] = pid(s[1].x * 2. - .5, t, s[1].z, s[1].w); 
    c[1] = pid(s[3].x * 2. - .5, t, s[3].z, s[3].w); 
    c[2] = pid(s[0].y * 2. - .5, t, s[0].z, s[0].w); 
    c[3] = pid(s[4].y * 2. - .5, t, s[4].z, s[4].w); 

    vec3 ex        = mix(c[0].yzw, c[1].yzw, .5);
    vec3 ey        = mix(c[2].yzw, c[3].yzw, .5);
    vec2 e        = mix(ex.yz, ey.yz, vec2(ex.x, ey.x));
    e         = (e + .5) * .5;
    
    float dx    = min(c[0].x, c[1].x);
    float dy    = min(c[2].x, c[3].x);
    vec2 d        = vec2(dy, dx);
    
    d -= cos(d*2.5+time);
    
    //result
    vec4 r        = vec4(d, e);
    r         = mix(s[2], r, .01 - abs(ex.z-ey.z));
    r         = mix(s[2], r, .15);

    //reset button - bottom left
    r         = mouse.x < .01 && mouse.y     < .01 ? vec4(0.5) : r;
    
    //cursor
    float mc     = step(length(m), .015);
    r.zw         += mc;
    
    glFragColor    = r.yxzw;
}//sphinx

#define kp 1.5
#define ki 4.1
#define kd .5

vec4 pid(float p, float t, float e, float i){
    float error     = t - p;
    float integral    = i - error;
    float delta    = error - e;
    
    float result     = kp*error + ki*integral + kd*delta;
    return vec4(result, error, integral, delta);
}

float hash(float v)
{
    return fract(fract(cos(1234.5678*v+fract(sin(v)*43758.5453123))));
}

vec2 toworld(vec2 p){
    p = p * 2. - 1.;
    p.x *= aspect;
    return p;
}

vec3 hsv(vec3 v){
    return mix(vec3(1.),clamp((abs(fract(v.x+vec3(3.,2.,1.)/3.)*6.-3.)-1.),0.,1.),v.y)*v.z;
}

void sampleneumann(vec2 uv, out vec4[5] s){
    //bottom, left, center, right, top
    vec2 p  = 1./resolution.xy;
    vec3 o    = vec3(-1., 0., 1.);
    s[0]    = texture2D(backbuffer, uv + p * o.yx);
    s[1]    = texture2D(backbuffer, uv + p * o.xy);
    s[2]    = texture2D(backbuffer, uv);
    s[3]    = texture2D(backbuffer, uv + p * o.zy);
    s[4]    = texture2D(backbuffer, uv + p * o.yz);
}

void samplecross(vec2 uv, out vec4[5] s){
    //bottom left, top right, center, top left, bottom right
    vec2 p  = 1./resolution.xy;
    vec3 o    = vec3(-1., 0., 1.);
    s[0]    = texture2D(backbuffer, uv + p * o.zz);
    s[1]    = texture2D(backbuffer, uv + p * o.zx);
    s[2]    = texture2D(backbuffer, uv);
    s[3]    = texture2D(backbuffer, uv + p * o.xz);
    s[4]    = texture2D(backbuffer, uv + p * o.xx);
}

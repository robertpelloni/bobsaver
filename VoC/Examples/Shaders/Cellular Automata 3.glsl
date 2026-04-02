#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

//drag the cursor along the bottom for best effect
//note, the timescale affects the structure as well as growthrate, it's not one to one
//sphinx

#define timescale 129.
//#define denoise
#define aspect (resolution.x/resolution.y)

vec4     pid(float p, float t, float e, float i);
float    line(vec2 p, vec2 a, vec2 b, float w);
float    hash(float v);
float    noise(in vec2 v);
vec2    toworld(vec2 p);

void    samplecross(vec2 uv, out vec4[5] s);
void    sampleneumann(vec2 uv, out vec4[5] s);

void main( void ) {
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec4 bb = texture2D(backbuffer, uv);
    vec2 m     = toworld(uv-mouse+.5);
    
    //noise
    #ifndef denoise
    float t = time * .1;
    vec2 p     = toworld(uv) * 512.;
    vec2 n    = vec2(noise(p + vec2(t*12.)), noise(p + vec2(-t*12.)+vec2(213, 519.)))-.5;
    uv += n * .009;
    #endif
    
    //sample
    vec4 s[5];
    if(mod(64.*time*timescale, 2.)==0.)
    {
        samplecross(uv, s);
    }
    else
    {
        sampleneumann(uv, s);
    }
    
    float v = (s[0].w+s[1].w+s[2].w+s[3].w+s[4].w)/5.;
    
    //pid control - left right top bottom
    vec4 c[4]; 
    c[0] = pid(s[1].x * 2. - .5, v, s[1].z, s[1].w); 
    c[1] = pid(s[3].x * 2. - .5, v, s[3].z, s[3].w); 
    c[2] = pid(s[0].y * 2. - .5, v, s[0].z, s[0].w); 
    c[3] = pid(s[4].y * 2. - .5, v, s[4].z, s[4].w); 
    
    float dh    = max(c[0].x, c[1].x);
    float dv    = max(c[2].x, c[3].x);
    vec2 nd        = vec2(dh, dv)*.75;
    
    vec2 neh    = abs(min(c[0].zw, c[1].zw));
    vec2 nev    = abs(min(c[2].zw, c[3].zw));
    vec2 ne        = mix(neh, nev, vec2(dh, dv)) * 1.38;
    
    //result
    vec4 r        = vec4(nd.yx, ne);
    r         = mix(s[2], r, abs(r-s[2]));
    r         = mix(s[2], r, .1);
    r.z         *= 1.01;
    
    //reset button - bottom left
    r         = mouse.x < .01 && mouse.y < .01 ? vec4(1.) : r;
    r         = uv.x < .01 &&  uv.y/aspect < .01 ? vec4(1.) : r;

    //cursor
    float mc     = step(length(m), .05 );
    r.zw         += mc;
    
    glFragColor = r;
}//sphinx

#define kp -.5
#define ki -1.9
#define kd 3.25

vec4 pid(float p, float t, float e, float i){
    float error     = t - p;
    float integral    = i - error/5.;
    float delta    = error - e;
    
    float result     = kp*i*error + ki*integral + kd*delta;
    return vec4(result, error, integral, delta);
}

float line(vec2 p, vec2 a, vec2 b, float w){
    if(a==b)return(0.);
    float d = distance(a, b);
    vec2  n = normalize(b - a);
        vec2  l = vec2(0.);
    l.x = max(abs(dot(p - a, n.yx * vec2(-1.0, 1.0))), 0.0);
    l.y = max(abs(dot(p - a, n) - d * 0.5) - d * 0.5, 0.0);
    return smoothstep(w, 0., l.x+l.y);
}

float hash(float v)
{
    return fract(sin(v)*43758.5453123);
}

float noise(in vec2 v)
{
    vec2 p = floor(v);
    vec2 f = fract(v);
    f = f*f*(3.0-2.0*f);
    float n = p.x + p.y*57.0;
    p.x = mix(hash(n+ 0.), hash(n+  1.), f.x);
    p.y = mix(hash(n+57.), hash(n+ 58.), f.x);
    float res = mix(p.x, p.y, f.y);
    return res;
}

vec2 toworld(vec2 p){
    p = p * 2. - 1.;
    p.x *= aspect;
    return p;
}

void sampleneumann(vec2 uv, out vec4[5] s){
    //bottom, left, center, right, top
    vec2 p  = 1./resolution.xy;
    vec3 o    = vec3(-1., 0., 1.);
    uv    = fract(uv);
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
    uv    = fract(uv);
    s[0]    = texture2D(backbuffer, uv + p * o.xx);
    s[1]    = texture2D(backbuffer, uv + p * o.zz);
    s[2]    = texture2D(backbuffer, uv);
    s[3]    = texture2D(backbuffer, uv + p * o.xz);
    s[4]    = texture2D(backbuffer, uv + p * o.zx);
}

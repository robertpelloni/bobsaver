#version 420

// original https://www.shadertoy.com/view/7dSXDh

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Daily Shader | 013 5/04/2021 @byt3_m3chanic
//
// started playing with some tiling/hexagons
// and then tried to animated the truchets.
// Might be hacky - but this was mostly learning
////////////////////////////////////////////////////////
#define R          resolution
#define M          mouse*resolution.xy
#define T          time

#define PI         3.14159265359
#define PI2        6.28318530718
#define SQ3        1.732

mat2 rot(float a)
{
    return mat2(cos(a),sin(a),-sin(a),cos(a));
}

float hash21(vec2 p)
{
    return fract(sin(dot(p, vec2(27.609, 57.583)))*43758.5453);
}

vec3 hue(float t)
{ 
    vec3 d = vec3(0.573,0.725,0.153)*date.z;
    return .55 + .45*cos(PI2*t*(vec3(.85,.97,.98)*d)); 
}

vec4 hexGrid(vec2 uv, float scale)
{
    uv*=scale;
    const vec2 s = vec2(SQ3, 1.);
    vec4 hC = floor(vec4(uv, uv - vec2(1, .5))/s.xyxy) + .5;
    vec4 h4 = vec4(uv - hC.xy*s, uv - (hC.zw + .5)*s);
    return dot(h4.xy, h4.xy) < dot(h4.zw, h4.zw) ? vec4(h4.xy, hC.xy) : vec4(h4.zw, hC.zw + .5);
}

void main(void)
{
    vec3 C = vec3(0);
    vec2 uv = gl_FragCoord.xy/max(R.x,R.y);
    uv-=vec2(-T*.015,T*.0215);
    
    //change scale here
    vec4 hex = hexGrid(uv,8.);

    vec2 id = hex.zw;
    vec2 p  = hex.xy;
    
    float check = mod(id.y + id.x,2.) * 2. - 1.;
    float rnd = hash21(id);
    float dir =  -1.;
    
    if(rnd>.5) {
        p *= rot(60.*PI/180.);
        p.y=-p.y;
    } 
    
    float rdx = .2875;
    
    // set vectors
    vec2 p0 = p - vec2(-.5/SQ3, .5);
    vec2 p1 = p - vec2(.8660254*2./3., 0);
    vec2 p2 = p - vec2(-.5/SQ3, -.5);
    
    // find closest point
    vec3 d3 = vec3(length(p0), length(p1), length(p2));
    vec2 pp = vec2(0);

    if(d3.x>d3.y) pp = p1;
    if(d3.y>d3.z) pp = p2;
    if(d3.z>d3.x && d3.y>d3.x) pp = p0;

    // draw truchet path
    float circle = length(pp)-rdx;
    circle=abs(circle)-.1;
    float cntr = circle;
    cntr = smoothstep(.03,.02,cntr);
    circle=abs(circle)-.001;
    circle=smoothstep(.01,.00,circle);
    float amt = 12.;

    // hex background
    float tileform = max(abs(hex.x)*.8660254 + abs(hex.y)*.5, abs(hex.y)) - .5;
    
    float edges = abs(tileform);
    
    edges=abs(abs(edges)-.001)-.001;
    edges=smoothstep(.02, .01, edges);

    float cells=smoothstep(.051, .05, tileform);
    float cellshadow = (rnd>.5) ? 1.2-d3.x : d3.x; 
 
    //animation
    d3 = abs(d3 - SQ3/6.) - .125;
    vec3 a3=vec3(atan(p0.x, p0.y),atan(p1.x, p1.y),atan(p2.x, p2.y));
    
    vec2 da = vec2(0);
    if(d3.x>d3.y) da = vec2(d3.y, a3.y);
    if(d3.y>d3.z) da = vec2(d3.z, a3.z);
    if(d3.z>d3.x && d3.y>d3.x) da = vec2(d3.x, a3.x);
    
    float speed = -T;
    // make coords on truchet path
    float d = length(pp);
    float pathMotion = 200.+da.y/ PI2* (amt) + speed;
    float x =fract(pathMotion) - .5;
    float y = d-rdx;

    //fix id's for each ball
    vec2 cid = vec2(
       floor(d),
       floor(pathMotion)-.5
    );
    cid=mod(cid,4.);

    //vector and compress coords
    vec2 tu = vec2(x,y)*vec2(1.45,10.);
    float path = length(tu)-.34;
    if(mod(cid.y,4.)<3.)path=abs(path)-.001;
    path=smoothstep(.11,.1,path);

    // make stripe pattern
    vec2 vu =rot(.60)*uv;
    float sd = mod(floor(vu.y * 555.), 2.);
    vec3 stripe = (sd<1.) ? vec3(.9) : vec3(.75);
    
    //mixdowns and stuff
    vec3 topHue = hue(hash21(cid));
    
    C = mix(C, stripe*cellshadow, min(cells,1.-cntr));
    C = mix(C, vec3(.15),min(edges,1.-cntr)); 
    C = mix(C, vec3(stripe*.15), cntr);
    C = mix(C, vec3(.35), max(circle,-edges));
    C = mix(C, topHue,path);

    //output
    glFragColor = vec4(C,1.0);
}


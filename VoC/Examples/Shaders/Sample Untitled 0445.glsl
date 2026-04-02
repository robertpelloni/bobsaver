#version 420

// original https://www.shadertoy.com/view/wljSDD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float PI = 3.14159265;
vec2 path(float t){
    float x = sin(t) + cos(t / 2.) + sin(t / 4.);
    float y = sin(t) + sin(t/2.) + cos(t/4.);
    return vec2(x,y)/4.;
}
mat2 genRot(float val){
    return mat2(cos(val),-sin(val),sin(val),cos(val));
}
vec3 modCell(vec3 p,vec3 c){
    p.x = (fract(p.x / c.x + 0.5) - 0.5) * c.x;
    p.y = (fract(p.y / c.y + 0.5) - 0.5) * c.y;
    p.z = (fract(p.z / c.z + 0.5) - 0.5) * c.z;
    return p;
}

vec2 pmod(vec2 p,float c){
    p.xy *= genRot(PI/c);
    float at = atan(p.y/p.x);
    float r = length(p);
    at = mod(at,PI * 2. / c);
    vec2 re = vec2(cos(at) * r,sin(at) * r);
    re.xy *= genRot(-PI/c);
    return re;
}
float roomsize = 7.5;
vec2 map(vec3 p){
    p.xy += path(p.z);
    //p = modCell(p,vec3(roomsize));
    p = modCell(p,vec3(vec2(roomsize),2.0));
    p.xy *= genRot(time);
    p.xy = pmod(p.xy,12.);
    vec2 sp = vec2(length(p - vec3(3.0,0.,0.)) - 0.5,1.0);
    vec3 q = p;
    q.xz -= vec2(3.0,0.);
    q.xy *= genRot(time);
    float cyl = length(q.xz) - 0.25;
    cyl = max(cyl,-length(p.xy) + 1.);
    cyl = max(cyl,length(p.xy) - 3.00);
    cyl = min(cyl,length(p.xy - vec2(3.,0.)) - 0.1);
    return vec2(cyl,0.0);
}
vec2 trace(vec3 r,vec3 o){
    float t = 0.0;
    float id = -1.0;
    for(int i = 0; i < 128; i++){
        vec3 p = o + r * t;
        vec2 d = map(p);
        t += d.x * 0.5;
        id = d.y;
    }
    return vec2(t,id);
}

vec3 ray (vec2 uv,float z){
 vec3 r = normalize(vec3(uv,z));
    r.xz *= genRot(-PI/6.);
    r.yz *= genRot(-PI / 8.);
    r.xy *= genRot(time /1.);
    return r;
}
vec3 cam (float t){
    vec3 c = vec3(roomsize/2.,roomsize/2.,-6.5 + time * 8.0);
    return c;
}

vec3 getColor(vec3 r, vec3 o, vec2 data){
    float t = data.x;
    vec3 p = o + r * t;
    vec3 col1 = vec3(sin(p.x) * 0.5 + 0.75,sin(p.y) * 0.5 + 0.75,sin(p.z) * 0.5 + 0.75);
    vec3 col2 = vec3(cos(p.x) * 0.5 + 0.75,cos(p.y) * 0.5 + 0.75,cos(p.z) * 0.5 + 0.75);
    float fog = 1./(1. + t * t * 0.01);
    float a = sin(p.z - time * 4.) * 0.5 + 0.5;
    col1 = mix(col1,col2,a);
    col1 = mix(col1,vec3(sin(time) * 0.5 + 0.5),1. - fog);
    return col1;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy * 2. - resolution.xy)/resolution.y;
    vec3 o = cam(time);
    vec3 r = ray(uv,1.5);
    vec2 data = trace(r,o);
    
    // Time varying pixel color
    vec3 col =getColor(r,o,data);

    // Output to screen
    glFragColor = vec4(col,1.0);
}

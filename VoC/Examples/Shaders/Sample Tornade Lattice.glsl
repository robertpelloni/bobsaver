#version 420

// original https://www.shadertoy.com/view/3lSXRt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359
#define PI2 6.28318530718

int STEP = 64;
float NEAR = 2.0;
float REPEAT_UNIT = 500.0;

//transform function(inverse)
vec3 transform(vec3 pos, vec3 move, vec3 rot)
{
    vec4 p = vec4(pos.x, pos.y, pos.z, 1.0);
    mat4 m = mat4(
        1.0,    0.0,    0.0,    0.0,
        0.0,    1.0,    0.0,    0.0,
        0.0,    0.0,    1.0,    0.0,
        -move.x,    -move.y,    -move.z,    1.0
    );
    mat4 rx = mat4(
        1.0,    0.0,        0.0,            0.0,
        0.0,    cos(-rot.x), sin(-rot.x),    0.0,
        0.0,    -sin(-rot.x), cos(-rot.x),     0.0,
        0.0,    0.0,        0.0,            1.0
    );
    mat4 ry = mat4(
        cos(-rot.y),     0.0,    -sin(-rot.y), 0.0,
        0.0,            1.0,    0.0,        0.0,
        sin(-rot.y),    0.0,    cos(-rot.y), 0.0,
        0.0,            0.0,    0.0,        1.0
    );
    mat4 rz = mat4(
        cos(-rot.z), sin(-rot.z),    0.0,    0.0,
        -sin(-rot.z), cos(-rot.z),     0.0,    0.0,
        0.0,        0.0,            1.0,    0.0,
        0.0,        0.0,            0.0,    1.0
    );

    return (ry * rx * rz * m * p).xyz;
}

vec3 translate(vec3 pos, vec3 move)
{
    vec4 p = vec4(pos.x, pos.y, pos.z, 1.0);
    mat4 m = mat4(
        1.0,    0.0,    0.0,    0.0,
        0.0,    1.0,    0.0,    0.0,
        0.0,    0.0,    1.0,    0.0,
        -move.x,    -move.y,    -move.z,    1.0
    );
   
    return (m * p).xyz;
}

vec3 rotate(vec3 pos, vec3 rot)
{
    vec4 p = vec4(pos.x, pos.y, pos.z, 1.0);
    mat4 rx = mat4(
        1.0,    0.0,        0.0,            0.0,
        0.0,    cos(-rot.x), sin(-rot.x),    0.0,
        0.0,    -sin(-rot.x), cos(-rot.x),     0.0,
        0.0,    0.0,        0.0,            1.0
    );
    mat4 ry = mat4(
        cos(-rot.y),     0.0,    -sin(-rot.y), 0.0,
        0.0,            1.0,    0.0,        0.0,
        sin(-rot.y),    0.0,    cos(-rot.y), 0.0,
        0.0,            0.0,    0.0,        1.0
    );
    mat4 rz = mat4(
        cos(-rot.z), sin(-rot.z),    0.0,    0.0,
        -sin(-rot.z), cos(-rot.z),     0.0,    0.0,
        0.0,        0.0,            1.0,    0.0,
        0.0,        0.0,            0.0,    1.0
    );

    return (ry * rx * rz * p).xyz;
}

// distance functions
float sphere(vec3 p, float r)
{
    return length(p) - r;
}

float box(vec3 pos, vec3 size)
{
    vec3 d = abs(pos) - size;
    return length(max(d,0.0))+ min(max(d.x,max(d.y,d.z)),0.0);
}

float cylinder(vec3 pos, float r)
{
    return length(pos.xz) - r;
}

// mixing shapes
float nsUnion(float d1, float d2) {return min(d1, d2);}

float nsSubtraction(float d1, float d2) {return max(-d1, d2);}
float nsIntersection(float d1, float d2) {return max(d1, d2);}
float sUnion(float d1, float d2, float k){
    float h = clamp(0.5 + 0.5*(d2-d1)/k, 0.0, 1.0);
    return mix(d2, d1, h) - k*h*(1.0-h);
}
float sSubtraction(float d1, float d2, float k){
    float h = clamp(0.5 - 0.5*(d2+d1)/k, 0.0, 1.0);
    return mix(d2, -d1, h) + k*h*(1.0-h);
}
float sIntersection(float d1, float d2, float k){
    float h = clamp(0.5 - 0.5*(d2-d1)/k, 0.0, 1.0);
    return mix(d2, d1, h) + k*h*(1.0-h);
}

//mapping
float map(vec3 pos)
{
    pos = rotate(pos, vec3(0.0,0.0,pos.z / REPEAT_UNIT * PI2));
    
    vec3 m = vec3(REPEAT_UNIT / 40.0,REPEAT_UNIT / 40.0,REPEAT_UNIT / 40.0);
    pos = mod(pos,m) - m * 0.5;
    float c1 = cylinder(pos, 1.0);
    float c2 = cylinder(rotate(pos, vec3(PI/2.0,0.0,0.0)),1.0);
    float c3 = cylinder(rotate(pos, vec3(0.0,0.0,PI/2.0)),1.0);
    float s1 = sphere(pos,2.0);
    float r = nsUnion(c2,c3);
    r = nsUnion(c1, r);
    r += sin(pos.x*3.0)*sin(pos.y*3.0)*sin(pos.z*3.0)*0.25;
    
    r = nsUnion(s1, r);
    return r;
    
}

// calculating normal
vec3 calcNorm(vec3 pos)
{
    float d = 0.0001;
    float center = map(pos);
    vec3 grad = vec3(map(pos+vec3(d,0.0,0.0))-center, map(pos+vec3(0.0,d,0.0))-center, map(pos+vec3(0.0,0.0,d))-center);
    return normalize(grad / d);
}

// lambert model
vec4 lambert(vec3 pos, vec3 lightDir)
{
    vec3 n = calcNorm(pos);
    float b = max(0.0, dot(n, -normalize(lightDir)))*0.9+0.1;
    return vec4(b, b, b, 1.0);
}

vec4 visualizeNormal(vec3 pos)
{
    return vec4(calcNorm(pos),1.0)*0.8 + vec4(1.0,1.0,1.0,1.0)*0.2;
}

// raymarching
vec4 raymarch(vec2 fc)
{
    fc = (fc * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    vec3 ray = normalize(vec3(fc, NEAR));
    vec3 pos = vec3(fc, NEAR);
    
    //camera rotating
    float rx = mouse.x*resolution.xy.x/resolution.x*2.0 - 1.0;
    float ry = mouse.y*resolution.xy.y/resolution.y*2.0 - 1.0;
    pos = rotate(pos, vec3(ry,-rx,0.0));
    ray = rotate(ray, vec3(ry,-rx,0.0));
    
    // camera moving
    pos = translate(pos, vec3(0.0,0.0,mod(-time*20.0, REPEAT_UNIT)));
    
    
    float d = 0.0;
    
    for(int i=0;i<STEP;i++)
    {
        d = map(pos);
        if(d < 0.0001){
            return lambert(pos, vec3(1.0,-1.0,0.0));
            //return visualizeNormal(pos);
        }
        pos = pos + ray * d;
    }
    return vec4(0.0, 0.0, 0.0, 1.0);
}

void main(void)
{

    glFragColor = raymarch( gl_FragCoord.xy);
}

#version 420

// original https://neort.io/art/bobpmrk3p9fd1q8obd30

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

float pi = acos(-1.);
float pi2 = pi * 2.;

mat2 rot(float a)
{
    return mat2(cos(a),sin(a),-sin(a),cos(a));
}

//https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float gyro(vec3 p ,float shift)
{
    float o = 10.;
    p.yz *= rot(pi/2.);
    float rad = mod(time,pi);
    rad = clamp(rad *1.01,0.,pi);
    vec2  size = vec2(8.,.2)*1.1 ;
    for(int i = 0; i< 3; i++)
    {
        p.xy *= rot(rad);
        p.xz *= rot(pi/2.);
        o = min(sdTorus(p,size),o);
        size -= vec2(.1,.0) * 10.;
    }
    
    return o;
}

float map(vec3 p)
{
    float s = gyro(p , 0.0);
    return s;
}

float marching(vec3 cp,vec3 rd)
{
    float depth = 0.;
    for(int i = 0; i< 64 ; i++)
    {
        vec3 rp = cp + depth * rd;
        float d = map(rp);
        if(d < 0.0001 * depth)
        {
            return depth;
        }
        if(d > 30.){break;}
        depth += d;
    }
    
    return -1.;
}

vec3 calcNormal(vec3 p)
{
    vec2 e = vec2(.001,.0);
    return normalize(.00001 + map(p) - vec3(map(p-e.xyy),map(p-e.yxy),map(p-e.yyx)));
}

void main(void) {
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    
    vec3 cp = vec3(0.,0.,-23.);
    
    //cp.y += exp(sin(time))*7.;
    
    vec3 target = vec3(0.);
    vec3 cd = normalize(target - cp);
    vec3 cu = vec3(0.,1.,0.);
    vec3 cs = normalize(cross(cu,cd));
    cu = normalize(cross(cd,cs));
    
    float fov = 2.5;
    vec3 rd = normalize(vec3(p.x * cs + p.y * cu + fov * cd));
    vec3 color = normalize(vec3(0.2,0.3,0.9));
    
    float d = marching(cp,rd);
    if(d > 0.)
    {
        vec3 light = normalize(vec3(.8,.4,.2));
        vec3 normal = calcNormal(cp + d * rd);
        
        float diff = 0.5 + .5 * clamp(dot(light , normal),0.,1.);
        float sky  = clamp(dot(vec3(0.,1.,0.),normal),0.,1.);
        
        
        color = sky * color;
        color += diff * vec3(1.);
    }
    glFragColor = vec4(color, 1.0);
}

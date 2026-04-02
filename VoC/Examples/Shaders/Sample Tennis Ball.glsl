#version 420

// original https://www.shadertoy.com/view/4djSWz

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

struct Ray
{
    float t;
    int id;
};

struct Sphere
{
    vec3 pos;
       vec3 ambient;
       vec3 diffuse;
    vec3 angle;
    float radius;
} ball;

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 rotate(vec3 p, int axis, float angle)
{
     if(axis < 0 || axis > 2)
        return p;
    float c = cos(angle);
    float s = sin(angle);
    mat3 m;
    //X axis
    if(axis == 0)
    {
        m[0] = vec3(1.0,0.0,0.0);
        m[1] = vec3(0.0,c,s);
        m[2] = vec3(0.0,-s,c);
    }
    //Y axis
    else if (axis == 1)
    {
        m[0] = vec3(c,0.0,-s);
        m[1] = vec3(0.0,1.0,0.0);
        m[2] = vec3(s,0.0,c);
    }
    //Z axis
    else if (axis == 2)
    {
        m[0] = vec3(c,-s,0.0);
        m[1] = vec3(s,c,0.0);
        m[2] = vec3(0.0,0.0,1.0);
    }
    return m*p;
}

vec3 rotateAroundPoint(vec3 p, vec3 o, int axis, float angle)
{
     return rotate(p-o,axis,angle)+o;   
}

vec2 transform(vec2 p)
{
     p = -1.0+2.0*p/resolution.xy;
    p.x *= resolution.x/resolution.y;
    return p;
}

vec3 cSphere(vec3 pos, Sphere sph)
{
    vec3 col = sph.ambient;
    float a = atan(pos.z-sph.pos.z,pos.y-sph.pos.y);
    
    for(int i = 0; i < 2; i++)
        pos = rotateAroundPoint(pos,sph.pos,i,sph.angle[i]);

    float d = pos.x-sph.pos.x;
    float e = pos.y-sph.pos.y;

    vec3 p = pos-sph.pos;
    //Ball curve, not perfect but looks good
    bool b = abs(p.x*p.x - sin(p.z)*2.0 - p.y*p.y/3.0) < sph.radius*0.1;
    if(b)
        col = vec3(1.0);

    return col;
}

vec3 nSphere(vec3 pos, Sphere sph)
{
    return (pos-sph.pos)/sph.radius;
}

float iSphere(vec3 ro, vec3 rd, Sphere sph)
{
     vec3 oc = ro - sph.pos;
    float b = 2.0*dot(oc,rd);
    float c = dot(oc,oc) - sph.radius*sph.radius;
    float h = b*b - 4.0*c;
    if(h < 0.0) return -1.0;
    float t = (-b - sqrt(h))/2.0;
    return t;
}

vec3 nPlane(vec3 pos)
{
     return vec3(0.0,1.0,0.0);
}

float iPlane(vec3 ro, vec3 rd)
{
     return -ro.y/rd.y;
}

Ray intersect(vec3 ro,vec3 rd)
{
    Ray ray;
    ray.t = 1000.0;
    ray.id = -1;
    float id = -1.0;
     float tsph = iSphere(ro,rd, ball);
    float tpla = iPlane(ro,rd);

    if(tsph > 0.0)
    {
        ray.id = 1;
        ray.t = tsph;
    }
    if( tpla > 0.0 && tpla < ray.t)
    {
        ray.id = 2;
        ray.t = tpla;
    }

    return ray;
}

void main(void)
{

   
    ball.pos = vec3(0.0,6.0,5.0);
    ball.radius = 2.0;
    ball.diffuse = vec3(0.7,0.8,0.1);
    ball.ambient = vec3(0.4,0.6,0.1);
    ball.angle = vec3(time*1.35,time*3.0,time*0.5);
    
    vec3 light = normalize(vec3(0.57703));

    vec2 p = transform(gl_FragCoord.xy);

    ball.pos.x = 3.5*cos(time);
    ball.pos.y = ball.radius+abs(cos(time*2.5)*5.5);
    ball.pos.z = -3.0+6.5*sin(time);
    
    vec3 col = vec3(0.1, 0.3, 0.9);

    vec3 ro = vec3(0.0, 5.0, 12.0);
    vec3 rd = normalize(vec3(p, -1.0));

    float t;
    Ray ray = intersect(ro,rd);
    vec3 pos = ro + ray.t*rd;
    if( ray.id == 1)
    {

        vec3 nor = nSphere(pos, ball);
        float dif = clamp(dot(nor, light),0.0,1.0);
        float ao = 0.5 + 0.5*nor.y;
        vec3 amb = cSphere(pos, ball);
         col = ball.diffuse*dif + amb;
        col *= ao;
    }
    else if( ray.id == 2)
    {
        vec3 nor = nPlane(pos);
        float dif = clamp(dot(nor,light),0.0,1.0);
         float amb = smoothstep(0.0,ball.radius*ball.radius/ball.pos.y,length(pos.xz-ball.pos.xz));
        col = vec3(0.0,0.1,0.0)*amb;
    }
    col = sqrt(col);

    glFragColor = vec4(col,1.0);
}

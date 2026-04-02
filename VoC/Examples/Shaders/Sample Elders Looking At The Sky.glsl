#version 420

// original https://www.shadertoy.com/view/tdlBWH

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// maz 2020
// Experiment in creating a scene using layers of 2D distance functions

float noise1(vec2 p)
{
   return fract(sin(p.x*p.y)*1175.5453123);
}

float noise2(vec2 p)
{
   return fract(sin(p.x*p.y+5209.)*1175.5453123);
}

float noise3(vec2 p)
{
   return fract(sin(p.x*p.y+1103.)*1175.5453123);
}

// smooth "noise", not that noisy...
float noise(float t)
{
    return sin(t)*cos(t*4.0);
}

// rotate pos (x,y) by theta radians around the Z axis
vec2 rot(float theta, vec2 pos)
{
    vec2 R1 = vec2(cos(theta), -sin(theta));
    vec2 R2 = vec2(sin(theta),  cos(theta));
    return vec2(dot(R1, pos), dot(R2, pos));
}

// mirrors pos (x,y) around the Y axis
vec2 mirror(vec2 pos)
{
    return vec2(abs(pos.x), pos.y);
}

// operation "union"
// v1 and v2 are (distance, color index) pairs
// the union is determined by the pair with the smaller distance
vec2 opU(in vec2 v1, in vec2 v2)
{
    return v1.x < v2.x? v1 : v2;
}

// operation "front"
// v1 and v2 are (distance, color index) pairs
// v2 replaces the color of v1 if v1.x is a distance outside the shape
vec2 opF(in vec2 v1, in vec2 v2)
{
    return v1.x > 0.0? v2 : v1;
}

// returns negative distance to edge if inside; positive distance if outside
float sdCircle(in vec2 p, in vec2 center, in float radius)
{
    return length(p - center) - radius; 
}

// boundary test for super-ellipse
// returns -1.0 if inside the ellipse and 1.0 if outside
float bSuperEllipse(vec2 p, vec2 c, float a, float b, float n, float r)
{
    vec2 localp = p - c;
    float v = pow(abs(localp.x/a), n) + pow(abs(localp.y/b), n);
    float d = v - pow(r,n);
    return mix(1.0, -1.0, step(0.0, -d));
}

// https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float sdEllipse(vec2 p, vec2 r)
{
    float k0 = length(p/r);
    float k1 = length(p/(r*r));
    return k0*(k0-1.0)/k1;
}

float sdArc(in vec2 pos, in float rOuter, in float rInner, in float arcAngleRad)
{
    pos.x = abs(pos.x); // mirror about y-axis
    float theta = 0.5*(3.14 - arcAngleRad);
    vec2 sc = vec2(cos(theta),sin(theta)); 
    float k = pos.x * sc.y - sc.x * pos.y; // cross product
    float len = length(pos.xy); 
    float d = k < 0.? max(len - rOuter, -len + rInner) : 1e0;
    return d;
}

float stemFn(float x, float p)
{
    return (p*x*x);
}

vec2 elder(in float id, in vec2 pos)
{
    float w = 0.1;
    float wstems[5] = float[](0.4, 1.5, 0.05, -1.1, -0.2);
    float ystems[5] = float[](1.5, 0.9, 2.0, 1.0, 1.6); 

    float blossom = 1e10;
    float stem = 1e10;
    for (int i = 0; i < 5; i++)
    {
        float ws = wstems[i]+0.1*sin(time);
        float w1 = stemFn(pos.y, ws);
        float l1 = pos.y > 0.0 && pos.y < ystems[i]? max(w1-pos.x, pos.x - w1 - w) : 1e10; 

        vec2 center = vec2(stemFn(ystems[i], ws), ystems[i]);
        float s1 = sdCircle(pos, center, 0.3);
        float noise = 0.01*(sin(10.0*pos.y)+cos(10.0*pos.x));
        blossom = min(blossom, s1+noise);
        stem = min(l1, stem);
    }

    float e3 = sdEllipse(pos-vec2(0.0, 0.05), vec2(0.6, 0.3));

    float yoffset = 0.0;//0.05 * sin(time);
    vec2 result = vec2(1e10);
    result = opU(vec2(sdCircle(pos, vec2( 0.6 + yoffset,  0.6), 0.2),  2.0), result);
    result = opU(vec2(sdCircle(pos, vec2(-0.6 + yoffset,  0.8), 0.15), 2.0), result);
    result = opU(vec2(sdCircle(pos, vec2(-1.3 + yoffset,  0.4), 0.1),  2.0), result);
    result = opU(vec2(sdCircle(pos, vec2(-0.1 + yoffset,  1.4), 0.1),  2.0), result);
    result = opU(vec2(sdCircle(pos, vec2( 0.35 + yoffset, 1.2), 0.08), 2.0), result);
    result = opU(vec2(sdCircle(pos, vec2(-0.35 + yoffset, 0.4), 0.08), 2.0), result);
    result = opU(vec2(sdCircle(pos, vec2( 1.35 + yoffset, 0.4), 0.1),  2.0), result);
    result = opF(result, vec2(blossom, 2.0));
    result = opF(result, vec2(stem, 2.0));
    result = opF(result, vec2(e3, 2.0));

    float eye = sdCircle(mirror(pos), vec2(0.3, 0.1), 0.06);
    result = opF(vec2(eye, 0.0), result);
    
    float lid = sdArc(rot(3.14, mirror(pos)- vec2(0.3, 0.17)), 0.2, 0.17, 1.0);
    result = opF(vec2(lid, 0.0), result);

    float mouth = sdEllipse(pos, vec2(0.13, 0.05));
    result = opF(vec2(mouth, 0.0), result);

    return result;
}

// Returns a color based on an index
vec3 pallet(float id)
{
    vec3 colors[] = vec3[](
        vec3(0.0, 0.0, 0.0), // 0
        vec3(1.0, 1.0, 1.0), // 1
        vec3(0.8, 0.8, 0.4), // 2
        vec3(0.8, 0.6, 0.6), // 3
        vec3(0.6, 0.2, 0.2), // 4
        vec3(214.0, 228.0, 232.0)/255.0, // 5
        vec3(0x13, 0x24, 0x34)/255.0, // 6
        vec3(40.0, 75.0, 90.0)/255.0, // 7
        vec3(21.0, 50.0, 70.0)/255.0 // 8
    );

    return colors[int(id)];
}

vec4 layerElders( in vec2 pos )
{
    vec2 p[] = vec2[](
        pos + vec2( 0.0, -0.5),
        pos + vec2(-2.2, 1.5),
        pos + vec2(2.8, 3.0) 
        );

    float r[] = float[](0.1, 0.1, -0.05);

    vec2 res = vec2(1e10);
    for (int i = 0; i < 3; i++)
    {
        float id = float(i);
        float offset = 0.1*sin(id+time);
        vec2 p = rot(r[i]+offset, p[i]);
        res = opU(elder(id, p), res);
    }
 
    float base = 1e10;
    for (int i = 0; i < 3; i++)
    {
        float noise = 0.05*(sin(6.0*pos.y) + cos(6.0*pos.x));
        float val = p[i].y + p[i].x * p[i].x - 1.0;
        base = min(base, val+noise);
    }
    vec2 body = abs(mod(res.x, 0.35)) > 0.05? vec2(base, 4.0) : vec2(base, 3.0);
    res = opF(res, body);
    return vec4(pallet(res.y), 1.0-step(0.0, res.x)); 
}

vec4 layerMoon( in vec2 pos )
{
    vec2 moon = vec2(1e10,0.0);
    for (float i = 0.0; i < 10.0; i++)
    {
        float noise = 0.01*sin(6.0*pos.y) + 0.01*cos(6.0*pos.x);
        float d = sdCircle(pos, vec2(-3.5, 3.5), 0.6 + i + 0.5*sin(i)) + noise;
        float c = mix(5.0, mod(i,3.0)+6.0, step(1.0, i));
        moon = opF(moon, vec2(d, c));
    }
    return vec4(pallet(moon.y), 1.0);
}

vec4 motes(in vec2 pos)
{
    float cs = 0.9;
    vec2 cell = floor(pos/cs)*cs;
    float d = 1e10;
    float size = 1e10;
    for (float r = -1.0; r <= 1.0; r += 1.0 )
    {
      for (float c = -1.0; c <= 1.0; c += 1.0 )
      {
        vec2 offset = cs * vec2(r,c);
        vec2 bl = cell + offset;
        vec2 tr = cell + offset + vec2(cs,cs);
        vec2 vel = noise(bl.x) * vec2(0.05*sin(time), 0.15*sin(time*noise(bl.y)));
        vec2 center = mix(bl, tr, vec2(noise2(bl)+vel));
        float size = clamp(noise(bl.y), 0.3, 1.0)+sin(2.0*noise(bl.y)*time+noise(bl.x)*10.0)*0.15;
        
        float se = bSuperEllipse(pos, center, 1.0, 0.75, 0.3, size);
        d = min(d, se);
      }
    }
    return d < 0.0? vec4(pallet(5.0), 0.5) : vec4(0.0);
}

vec3 scene( in vec2 pos )
{
    vec4 background = vec4(0.0);
    vec4 l1 = layerMoon(pos); 
    vec4 l2 = motes(pos);
    vec4 l3 = layerElders(pos);

    vec3 color = mix(background.xyz, l1.xyz, l1.w);
    color = mix(color, l2.xyz, l2.w); 
    color = mix(color, l3.xyz, l3.w); 
    return color;
}

#define ZERO min(0, frames)
#define AA 1
// anti-aliasing+gamma correction from: 
// https://www.shadertoy.com/view/Xds3zN
void main(void)
{
    vec3 tot = vec3(0.0);
#if AA>1
    for( int m=ZERO; m<AA; m++ )
    for( int n=ZERO; n<AA; n++ )
    {
        // pixel coordinates to 2D world coordinates
        vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5;
        vec2 p = (2.0*(gl_FragCoord.xy+o)-resolution.xy)/resolution.y;
#else
        vec2 p = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
#endif

        float zPlane = 2.0;
        vec3 rd = normalize( vec3(p,0.5) );
        vec3 pos = rd*(zPlane/rd.z);
        vec3 col = scene(pos.xy);

        // gamma
        col = pow( clamp(col, 0.0, 1.0), vec3(0.4545) );
        tot += col;
#if AA>1
    }
    tot /= float(AA*AA);
#endif

    glFragColor = vec4( tot, 1.0 );
}


#version 420

// original https://www.shadertoy.com/view/7tVXDV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define DEBUG 0

#define PI 3.14159265
#define saturate(x) clamp(x, 0.0, 1.0)

float sdBox(vec2 p, vec2 b)
{
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

float sdSegment(vec2 p, vec2 a, vec2 b )
{
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}

float sdBoxL(vec2 p, vec2 b)
{
    p = abs(p)-b;
    return max(p.x, p.y);
}

float sdBoxOC(vec2 p, vec2 b)
{
    p = abs(p)-b;
    return min(p.x, p.y);
}

mat2 rot(float ang)
{
    return mat2(cos(ang), -sin(ang),
                sin(ang), cos(ang)); 
}

vec2 repeat(vec2 p, vec2 c)
{
    return mod(p + 0.5*c, c) - 0.5*c;
}
float repeat(float p, float c)
{
    return mod(p + 0.5*c, c) - 0.5*c;
}

//-------------
// RNG https://www.shadertoy.com/view/wltcRS
//-------------
uvec4 s0; 

void rng_initialize(vec2 p, int frame)
{
    s0 = uvec4(p, uint(frame), uint(p.x) + uint(p.y));
}

// https://www.pcg-random.org/
void pcg4d(inout uvec4 v)
{
    v = v * 1664525u + 1013904223u;
    v.x += v.y*v.w; v.y += v.z*v.x; v.z += v.x*v.y; v.w += v.y*v.z;
    v = v ^ (v>>16u);
    v.x += v.y*v.w; v.y += v.z*v.x; v.z += v.x*v.y; v.w += v.y*v.z;
}

float rand() { pcg4d(s0); return float(s0.x)/float(0xffffffffu);  }
vec2 rand2() { pcg4d(s0); return vec2(s0.xy)/float(0xffffffffu);  }
vec3 rand3() { pcg4d(s0); return vec3(s0.xyz)/float(0xffffffffu); }
vec4 rand4() { pcg4d(s0); return vec4(s0)/float(0xffffffffu);     }

#define mixSDF(a, b, t, r) mix(a, b, saturate(-t*r))

#define ratio resolution.x
#define cells 10.0
#define cellRatio (ratio/cells)

vec4 getCellRandomState(vec2 cell)
{
    rng_initialize(cell, 0);
    
    vec4 start = rand4();
    vec4 state = (sin(rand4()*10.0 + start + time*(0.5+rand4()*0.5)*0.5 )*0.5+0.5);
    state = 0.2 + state * 0.6;
    
    return vec4(state);
}

vec4 getCorrectedBounds(vec2 cell, vec2 iuv)
{
    vec4 bounds      = getCellRandomState(cell);    
    vec4 boundsUp    = getCellRandomState(cell + vec2(0.0, 1.0) );
    vec4 boundsRight = getCellRandomState(cell + vec2(1.0, 0.0) );
    
    bounds.z = boundsUp.x;
    bounds.w = boundsRight.y;   
    return bounds;
}

vec2 getBoxCell(vec2 cell, vec4 bounds, vec2 iuv)
{
    cell += float(iuv.y > bounds.w && iuv.x > bounds.z); 
    cell.x += float(iuv.x > bounds.x && iuv.y < bounds.w); 
    cell.y += float(iuv.x < bounds.z && iuv.y > bounds.y);
    return cell;
}

vec4 getBoxShape(vec2 ccell, vec2 iuv)
{
   
    vec4 ccellBounds     = getCorrectedBounds(ccell, iuv);
    vec4 ccellBoundsLeft = getCorrectedBounds(ccell - vec2(1.0, 0.0), iuv);
    vec4 ccellBoundsDown = getCorrectedBounds(ccell - vec2(0.0, 1.0), iuv);
    
    float xMin = -(1.0 - ccellBoundsLeft.x);
    float xMax = ccellBounds.x;
    float yMin = -(1.0 - ccellBoundsDown.y);
    float yMax = ccellBounds.y;

    vec2 center = vec2(xMin + xMax, yMin + yMax)*0.5;
    vec2 size = vec2(abs(xMin) + abs(xMax), abs(yMin) + abs(yMax))*0.5;
    
    return vec4(center, size);
}

vec2 getBoxUV(vec2 cell, vec2 ccell, vec2 iuv)
{
    vec2 cellDiff = cell - ccell;
    vec2 boxIuv = iuv;
    if (cellDiff.x < -0.5) boxIuv.x = -(1.0 - iuv.x);
    if (cellDiff.y < -0.5) boxIuv.y = -(1.0 - iuv.y);
    return boxIuv;
}

vec4 getBoxColor(vec2 ccell)
{
    rng_initialize(ccell, 0);
    return 0.25 + rand4()*0.5;
}

void main(void)
{
	vec2 pos = gl_FragCoord.xy;
	vec4 O = gl_FragColor;

    vec2 uv = pos/ratio;
    uv += time*0.021;
    
    
    vec2 cell = floor(uv * cells);
    vec2 iuv = (uv*cells - cell);
  
    vec4 bounds = getCellRandomState(cell);    
    vec4 nBounds = getCorrectedBounds(cell, iuv);
    vec2 ccell = getBoxCell(cell, nBounds, iuv);
    
    vec4 shape = getBoxShape(ccell, iuv);
    vec2 center = shape.xy;
    vec2 size = shape.zw;
    vec2 boxUV = getBoxUV(cell, ccell, iuv);
    
    
    vec4 displayBounds = nBounds;

    //color
    O = getBoxColor(ccell);
    
    //inner stripes
    {
       float r = 0.12;
       float c = 0.18;
       
       float d = -sdBox(boxUV - center, size + r*0.5);
       float t = -sdBox(boxUV - center, size);
       
       c = c*(1.0-t*0.7);
       r = r*(1.0-t*0.7);
       
       float dd = mod(d, c);
       dd = c-abs(dd - c*0.5);
       dd = dd - r;
       
       O = mixSDF(O, O*saturate(0.8+t*0.5), -dd, cellRatio);
    }

    //shadows
    {
        float h = getCellRandomState(ccell).z;
            
        float upH = getCellRandomState(ccell + vec2(0.0, 1.0)).z;
        vec4 up = getBoxShape(ccell + vec2(0.0, 1.0), iuv);
        vec2 upCenter = up.xy + vec2(0.0, 1.0);
        vec2 upSize = up.zw;
             
        float l = sdBoxL(boxUV - upCenter, upSize);
        float o = sdBoxOC(boxUV - upCenter, upSize);
        
        float hDiff = saturate(upH-h); 
        l = mix(l, 1.0, hDiff/0.6);

        float s = saturate(0.5+l*1.5);      
        O = mixSDF(O, O*s, o/(1.0+s*6.0), cellRatio);
    }
   
    //white
    {
        vec4 color = vec4(0.8);
        
        vec2 c = vec2(0.008);
        vec2 puv = uv*rot(PI*0.25);
        vec2 pp = repeat(vec2(puv.x, 0.0), c);
        float d = length(pp) - 0.002;
        
        color = mixSDF(color,color + 0.15, d, ratio);
    
        if (nBounds.z > nBounds.x && nBounds.w > nBounds.y
        && iuv.x > nBounds.x && iuv.x < nBounds.z
        && iuv.y > nBounds.y && iuv.y < nBounds.w)          
            O = color;
            
        if (nBounds.z < nBounds.x && nBounds.w < nBounds.y
        && iuv.x < nBounds.x && iuv.x > nBounds.z
        && iuv.y < nBounds.y && iuv.y > nBounds.w)          
            O = color;
    }
    //black
    {
        if (nBounds.z < nBounds.x && nBounds.w > nBounds.y
        && iuv.x < nBounds.x && iuv.x > nBounds.z
        && iuv.y > nBounds.y && iuv.y < nBounds.w)          
            O = vec4(0.0);
            
        if (nBounds.z > nBounds.x && nBounds.w < nBounds.y
        && iuv.x > nBounds.x && iuv.x < nBounds.z
        && iuv.y < nBounds.y && iuv.y > nBounds.w)          
            O = vec4(0.0);

    }

    //lines
    {
        vec4 color = vec4(1.0);
        float d = 0.0;
        float l = 0.015;
        float pixel = 1.0/cellRatio;
        
        l = max(l, pixel*1.25);

        d = min(d, sdSegment(iuv, vec2(0.0, nBounds.y), vec2(max(nBounds.x, nBounds.z), nBounds.y)) - l);
        d = min(d, sdSegment(iuv, vec2(1.0, nBounds.w), vec2(min(nBounds.x, nBounds.z), nBounds.w)) - l);
        d = min(d, sdSegment(iuv, vec2(nBounds.x, 0.0), vec2(nBounds.x, max(nBounds.y, nBounds.w))) - l);
        d = min(d, sdSegment(iuv, vec2(nBounds.z, 1.0), vec2(nBounds.z, min(nBounds.y, nBounds.w))) - l);
            
        O = mixSDF(O, color, d, cellRatio);
    }
    
#if DEBUG == 1
    //cell bounds
    {
        float d = 0.0;
        float l = 0.0125;
        float pixel = 1.0/cellRatio;
        
        l = max(l, pixel*1.0);
        if (length(boxUV) <= 0.15) l *= 1.75;
        
        vec2 yBox = repeat(abs(boxUV), vec2(1.0, 0.2));               
        vec2 xBox = repeat(abs(boxUV), vec2(0.2, 1.0));
        
        d = min(d, sdSegment(yBox, vec2(0.0), vec2(0.0, 0.1)) - l);
        d = min(d, sdSegment(xBox, vec2(0.0), vec2(0.1, 0.0)) - l);       
        
        O = mixSDF(O, O+0.25, d, cellRatio);
    }
    
    //dots
    {
        float a = distance(iuv, vec2(nBounds.x, 0.0));
        float b = distance(iuv, vec2(nBounds.z, 1.0));     
        float dx = min(a, b)-0.045;      
        O = mixSDF(O, 0.25 + vec4(1.0, 0.0, 0.0, 0.0)*0.75, dx, cellRatio);
        
        float c = distance(iuv, vec2(0.0, nBounds.y));
        float d = distance(iuv, vec2(1.0, nBounds.w));     
        float dy = min(c, d)-0.045;      
        O = mixSDF(O, 0.25 + vec4(0.0, 1.0, 0.0, 0.0)*0.75, dy, cellRatio);
        
    }
#endif
          
    glFragColor = pow(O, vec4(0.9));   
}

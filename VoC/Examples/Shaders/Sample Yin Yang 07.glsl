#version 420

// original https://www.shadertoy.com/view/Md2BzV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//////////////////////////////////////////////////////////////////////////////////
// Infinite Yin Yang Zoom - Copyright 2017 Frank Force
// Yin Yang based on code Created by inigo quilez - iq/2013 - https://www.shadertoy.com/view/ldX3Rr
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//////////////////////////////////////////////////////////////////////////////////

const float zoomSpeed            = 0.5;    // how fast to zoom (negative to zoom out)
const float zoomScale            = 0.1;    // how much to multiply overall zoom (closer to zero zooms in)
const int recursionCount        = 6;    // how deep to recurse
const float recursionSize         = 7.5;    // how much to scale recursion at each step
const float saturation            = 0.2;    // how much to scale saturation (0 == black and white)
    
// math stuff
const float pi = 3.14159265359;
const float e = 2.718281828459;
float RandFloat(int i) { return (fract(sin(float(i)) * 43758.5453)); }
vec2 Rotate(vec2 p, float theta)
{
    float c = cos(theta);
    float s = sin(theta);
    return vec2((p.x*c - p.y*s), (p.x*s + p.y*c));
}
vec4 HsvToRgb(vec4 c) 
{
    float s = c.y * c.z;
    float s_n = c.z - s * .5;
    return vec4(s_n) + vec4(s) * cos(2.0 * pi * (c.x + vec4(1.0, 0.6666, .3333, 1.0)));
}

// focus stuff
float GetFocusRotation(int i) { return 2.0*pi*RandFloat(i); }
vec2 GetFocusPos(int i) 
{ 
    bool side = (RandFloat(50+i) < 0.5);
    vec2 p = vec2(0.0, side? -0.5 : 0.5); 
    return Rotate(p, GetFocusRotation(i));
}

//////////////////////////////////////////////////////////////////////////////////

vec4 YinYang(vec2 p, int iterations)
{
    // recursive iteration
    float co = 0.0;
    for (int r = 0; r < recursionCount; ++r)
    {
        // apply rotation
          float theta = -GetFocusRotation(iterations + r);
        p = Rotate(p, theta);
        
         // adapted from iq's yinyang drawing formula
        float h = dot(p,p);
        float a = abs(p.y)-h;
        float b = h-1.00;
        float c = sign(a*b*(p.y+p.x + (p.y-p.x)*sign(a)));
        
        c = (h > 1.0)? co : c;    // outside edge
        
        if (a-0.23 < 0.0 || r == recursionCount)
        {
            float hue = 0.133*float(iterations + r);
            return vec4(hue, saturation*c, c, 1.0); // stop if outside or reached limit
        }

        // check if top or bottom
        co = (p.y > 0.0)? 1.0 : 0.0;
        p.y += mix(0.5, -0.5, co);
        
        p *= recursionSize;        // apply recursion scale
        p = Rotate(p, -theta);    // cancel out rotation
    }
}

void main(void)
{
    vec2 uv=gl_FragCoord.xy;
    // fixed aspect ratio
    vec2 p = (2.0*uv-resolution.xy)/min(resolution.y,resolution.x);
    vec2 p2 = p;
    
    // wander center
    p.x += 0.3*sin(0.2*time);
    p.y += 0.3*sin(0.211*time);
    
    // get time 
    float timePercent = time*zoomSpeed;
    int iterations = int(timePercent);
    timePercent -= floor(timePercent);
    
    // update zoom, apply pow to make rate constant
    const float recursionSizeLog = log(recursionSize);
    float zoom = pow(e, -recursionSizeLog*timePercent);
    zoom *= zoomScale;
    
    // get focus offset
    vec2 offset = GetFocusPos(iterations);
    for (int i = 0; i < 6; ++i)
        offset += (GetFocusPos(iterations+i+1) / recursionSize) * pow(1.0 / recursionSize, float(i));
    
    // apply zoom and offset
    p = p*zoom + offset;
    
    // make the yin yang
    vec4 color = YinYang(p, iterations);
    
    // color wander
    color.x += (0.1*p2.y + 0.1*p2.x + 0.05*time);
    
    // map to rgp space
    color = HsvToRgb(color);

    glFragColor=color;
}

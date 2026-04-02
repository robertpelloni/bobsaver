#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/wdcGz2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// numbers = [119, 18, 93, 91, 58, 107, 111, 82, 127, 123]
vec2 tl = vec2(-.5,  1); // top    left  corner
vec2 tr = vec2( .5,  1); // top    right corner
vec2 ml = vec2(-.5,  0); // mid    left  corner
vec2 mr = vec2( .5,  0); // mid    right corner
vec2 bl = vec2(-.5, -1); // bottom left  corner
vec2 br = vec2( .5, -1); // bottom right corner

float Manhattan( vec2 v )
{
    return abs(v.x) + abs(v.y);
}

float Line( vec2 a, vec2 b, vec2 p )
{
    vec2 pa = p - a;
    vec2 ba = b - a;
    float t = clamp(dot(pa, ba)/dot(ba,ba), 0.11, .89); // 0.11 and .89 for gaps
    return smoothstep(.1, .09, Manhattan(pa - ba*t));
}

int Encode( int n )
{
    n = int(mod(float(n), 10.0));
    switch(n)
    {
        case(0):
            return 119;
        case(1):
            return 18;
        case(2):
            return 93;
        case(3):
            return 91;
        case(4):
            return 58;
        case(5):
            return 107;
        case(6):
            return 111;
        case(7):
            return 82;
        case(8):
            return 127;
        case(9):
            return 123;
    }
    return 119;
}

float SegDisp( int key, vec2 p )
{
    float r = 0.0;
    if ((key & 64) == 64) { r += Line(tl, tr, p);}
    if ((key & 32) == 32) { r += Line(tl, ml, p);}
    if ((key & 16) == 16) { r += Line(tr, mr, p);}
    if ((key & 8 ) == 8 ) { r += Line(ml, mr, p);}
    if ((key & 4 ) == 4 ) { r += Line(ml, bl, p);}
    if ((key & 2 ) == 2 ) { r += Line(mr, br, p);}
    if ((key & 1 ) == 1 ) { r += Line(bl, br, p);}
    return r;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;

    vec3 col = vec3(0);
    
    float d = 0.0;
    float n = mod(time, 1000.0);
    d += SegDisp(Encode(int(mod(n/100.0, 10.0))), (uv+vec2(.5, 0))*3.0);
    d += SegDisp(Encode(int(mod(n/10.0 , 10.0))), uv*3.0);
    d += SegDisp(Encode(int(mod(n/1.0  , 10.0))), (uv-vec2(.5, 0))*3.0);
    d = smoothstep(-.5, 1.0, d);
    
    col = vec3(.8, 0.1, 0.2) * d;
    
    glFragColor = vec4(col,1.0);
}

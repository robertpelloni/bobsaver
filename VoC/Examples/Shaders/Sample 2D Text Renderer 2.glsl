#version 420

// SixteenSegmentDisplay.glsl
// 16 Segment Display Example v2
// rearranged source code by I.G.P.
//  Do you know further optimizations ?

vec2 uv;

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

const vec2 ch_size  = vec2(1.0, 2.0);              // character size
const vec2 ch_space = ch_size + vec2(0.7, 1.0);    // character distance  
const vec2 ch_start = vec2 (ch_space.x * -6., 1.); // start position
      vec2 ch_pos   = vec2 (0.0, 0.0);             // character position
      vec3 ch_color = vec3 (9.6, 9.7, 3.8);        // character color
const vec3 bg_color = vec3 (0.9, 3.0, 0.0);        // background color

 

/* 16 segment display...

Segment bit positions:

  __2__ __1__
 |\    |    /|
 | \   |   / |
 3  11 10 9  0
 |   \ | /   |
 |    \|/    |
  _12__ __8__
 |           |
 |    /|\    |
 4   / | \   7
 | 13 14  15 |
 | /   |   \ |
  __5__|__6__

15 12 11 8 7  4 3  0
 |  | |  | |  | |  |
 0000 0000 0000 0000

example: letter A

   12    8 7  4 3210
    |    | |  | ||||
 0001 0001 1001 1111

 binary to hex -> 0x119F
*/

#define n0 ddigit(0x22FF);
#define n1 ddigit(0x0281);
#define n2 ddigit(0x1177);
#define n3 ddigit(0x11E7);
#define n4 ddigit(0x5508);
#define n5 ddigit(0x11EE);
#define n6 ddigit(0x11FE);
#define n7 ddigit(0x2206);
#define n8 ddigit(0x11FF);
#define n9 ddigit(0x11EF);

#define A ddigit(0x119F);
#define B ddigit(0x927E);
#define C ddigit(0x007E);
#define D ddigit(0x44E7);
#define E ddigit(0x107E);
#define F ddigit(0x101E);
#define G ddigit(0x807E);
#define H ddigit(0x1199);
#define I ddigit(0x4466);
#define J ddigit(0x4436);
#define K ddigit(0x9218);
#define L ddigit(0x0078);
#define M ddigit(0x0A99);
#define N ddigit(0x8899);
#define O ddigit(0x00FF);
#define P ddigit(0x111F);
#define Q ddigit(0x80FF);
#define R ddigit(0x911F);
#define S ddigit(0x8866);
#define T ddigit(0x4406);
#define U ddigit(0x00F9);
#define V ddigit(0x2218);
#define W ddigit(0xA099);
#define X ddigit(0xAA00);
#define Y ddigit(0x4A00);
#define Z ddigit(0x2266);
#define _ ch_pos.x += ch_space.x;
#define s_dot     ddigit(0);
#define s_minus   ddigit(0x1100);
#define s_plus    ddigit(0x5500);
#define s_greater ddigit(0x2800);
#define s_less    ddigit(0x8200);
#define s_sqrt    ddigit(0x0C02);
#define nl1 ch_pos = ch_start;  ch_pos.y -= 3.0;
#define nl2 ch_pos = ch_start;  ch_pos.x = 13.0;
#define nl3 ch_pos = ch_start;    ch_pos.y -= 3.0;

float dseg(vec2 p0, vec2 p1)
{
    vec2 dir = normalize(p1 - p0);
    vec2 cp = (uv - ch_pos - p0) * mat2(dir.x, dir.y,-dir.y, dir.x);
    return distance(cp, clamp(cp, vec2(0), vec2(distance(p0, p1), 0)));   
}

bool bit(int n, int b)
{
    return mod(floor(float(n) / exp2(floor(float(b)))), 2.0) != 0.0;
}

float d = 1e6;

void ddigit(int n)
{
    float v = 1e6;    
    vec2 cp = uv - ch_pos;
    if (n == 0)     v = min(v, dseg(vec2(-0.505, -1.000), vec2(-0.500, -1.000)));
    if (bit(n,  0)) v = min(v, dseg(vec2( 0.500,  0.063), vec2( 0.500,  0.937)));
    if (bit(n,  1)) v = min(v, dseg(vec2( 0.438,  1.000), vec2( 0.063,  1.000)));
    if (bit(n,  2)) v = min(v, dseg(vec2(-0.063,  1.000), vec2(-0.438,  1.000)));
    if (bit(n,  3)) v = min(v, dseg(vec2(-0.500,  0.937), vec2(-0.500,  0.062)));
    if (bit(n,  4)) v = min(v, dseg(vec2(-0.500, -0.063), vec2(-0.500, -0.938)));
    if (bit(n,  5)) v = min(v, dseg(vec2(-0.438, -1.000), vec2(-0.063, -1.000)));
    if (bit(n,  6)) v = min(v, dseg(vec2( 0.063, -1.000), vec2( 0.438, -1.000)));
    if (bit(n,  7)) v = min(v, dseg(vec2( 0.500, -0.938), vec2( 0.500, -0.063)));
    if (bit(n,  8)) v = min(v, dseg(vec2( 0.063,  0.000), vec2( 0.438, -0.000)));
    if (bit(n,  9)) v = min(v, dseg(vec2( 0.063,  0.063), vec2( 0.438,  0.938)));
    if (bit(n, 10)) v = min(v, dseg(vec2( 0.000,  0.063), vec2( 0.000,  0.937)));
    if (bit(n, 11)) v = min(v, dseg(vec2(-0.063,  0.063), vec2(-0.438,  0.938)));
    if (bit(n, 12)) v = min(v, dseg(vec2(-0.438,  0.000), vec2(-0.063, -0.000)));
    if (bit(n, 13)) v = min(v, dseg(vec2(-0.063, -0.063), vec2(-0.438, -0.938)));
    if (bit(n, 14)) v = min(v, dseg(vec2( 0.000, -0.938), vec2( 0.000, -0.063)));
    if (bit(n, 15)) v = min(v, dseg(vec2( 0.063, -0.063), vec2( 0.438, -0.938)));
    ch_pos.x += ch_space.x;
    d = min(d, v);
}

vec2 wobble(vec2 uv, float amplitude, float frequence, float speed)
{
  float offset = amplitude*sin(uv.y*frequence+time*speed);
  return vec2(uv.x+offset,uv.y);    
}

void main( void ) 
{
    vec2 aspect = resolution.xy / resolution.y;
    uv = 4.*( gl_FragCoord.xy / resolution.xy )  ;
    
    float amplitude = 0.0080;
    float frequence = 75.00;
    float speed = 10.0;
    uv += wobble(uv*5.,amplitude*6.,frequence*10.,speed/2.);

    ch_pos = ch_start + vec2(1.,1.5+abs(sin(time)*8.));  // set start position

        H E L L O _ _ _ S O F T O L O G Y _  nl2 
     
     
    
    vec3 color = mix(ch_color, bg_color, 2.0- (0.08 / d));  // shading
    glFragColor = vec4(color+(0.5*length(uv-vec2(12.0,5.5))), 1.0);
}

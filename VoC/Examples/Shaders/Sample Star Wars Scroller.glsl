#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//3x5 digit sprites stored in "15 bit" numbers
/*
███     111
  █     001
███  -> 111  -> 111001111100111 -> 29671
█       100
███     111
*/
/*
        000
        000
     -> 000  -> 000000000000010 -> 2
        000
 █      010
*/
/*
        000
 █      010
███  -> 111  -> 000010111010000 -> 1488
 █      010
        000
*/
/*
        000
        000
███  -> 111  -> 000000111000000 -> 448
        000
        000
*/

float c_0 = 31599.0;
float c_1 = 9362.0;
float c_2 = 29671.0;
float c_3 = 29391.0;
float c_4 = 23497.0;
float c_5 = 31183.0;
float c_6 = 31215.0;
float c_7 = 29257.0;
float c_8 = 31727.0;
float c_9 = 31695.0;

float c_colon = 1040.0;
float c_scolon = 1044.0;
float c_period = 2.0;
float c_comma = 10.0;
float c_exclam = 9346.0;

float c_plus  = 1488.0;
float c_minus = 448.0;
float c_lparen = 5265.0;
float c_rparen = 17556.0;
float c_lbrack = 13587.0;
float c_rbrack = 25686.0;
float c_undersc = 7.0;
float c_equal = 3640.0;

float c_a = 31725.;
float c_b = 31663.;
float c_c = 31015.;
float c_d = 27502.;
float c_e = 31143.;
float c_f = 31140.;
float c_g = 31087.;
float c_h = 23533.;
float c_i = 29847.;
float c_j = 4719.;
float c_k = 23469.;
float c_l = 18727.;
float c_m = 24429.;
float c_n = 27501.;
float c_o = 31599.;
float c_p = 31716.;
float c_q = 31609.;
float c_r = 27565.;
float c_s = 31183.;
float c_t = 29842.;
float c_u = 23407.;
float c_v = 23402.;
float c_w = 23421.;
float c_x = 23213.;
float c_y = 23186.;
float c_z = 29351.;

const float lineOffset = -64.0;
const float charWidth = 4.0;
const float charHeight = 8.0;

#define NL cpos.x = lineOffset; cpos.y += charHeight;

#define _ cpos.x += charWidth;
#define CM c += Sprite3x5(c_comma,floor(p-cpos)); cpos.x += charWidth;
#define PE c += Sprite3x5(c_period,floor(p-cpos)); cpos.x += charWidth;
#define EX c += Sprite3x5(c_exclam,floor(p-cpos)); cpos.x += charWidth;
#define LP c += Sprite3x5(c_lparen,floor(p-cpos)); cpos.x += charWidth;
#define RP c += Sprite3x5(c_rparen,floor(p-cpos)); cpos.x += charWidth;
#define LB c += Sprite3x5(c_lbrack,floor(p-cpos)); cpos.x += charWidth;
#define RB c += Sprite3x5(c_rbrack,floor(p-cpos)); cpos.x += charWidth;
#define RB c += Sprite3x5(c_rbrack,floor(p-cpos)); cpos.x += charWidth;
#define US c += Sprite3x5(c_undersc,floor(p-cpos)); cpos.x += charWidth;
#define EQ c += Sprite3x5(c_equal,floor(p-cpos)); cpos.x += charWidth;
#define CO c += Sprite3x5(c_colon,floor(p-cpos)); cpos.x += charWidth;
#define SC c += Sprite3x5(c_scolon,floor(p-cpos)); cpos.x += charWidth;

#define A c += Sprite3x5(c_a,floor(p-cpos)); cpos.x += charWidth;
#define B c += Sprite3x5(c_b,floor(p-cpos)); cpos.x += charWidth;
#define C c += Sprite3x5(c_c,floor(p-cpos)); cpos.x += charWidth;
#define D c += Sprite3x5(c_d,floor(p-cpos)); cpos.x += charWidth;
#define E c += Sprite3x5(c_e,floor(p-cpos)); cpos.x += charWidth;
#define F c += Sprite3x5(c_f,floor(p-cpos)); cpos.x += charWidth;
#define G c += Sprite3x5(c_g,floor(p-cpos)); cpos.x += charWidth;
#define H c += Sprite3x5(c_h,floor(p-cpos)); cpos.x += charWidth;
#define I c += Sprite3x5(c_i,floor(p-cpos)); cpos.x += charWidth;
#define J c += Sprite3x5(c_j,floor(p-cpos)); cpos.x += charWidth;
#define K c += Sprite3x5(c_k,floor(p-cpos)); cpos.x += charWidth;
#define L c += Sprite3x5(c_l,floor(p-cpos)); cpos.x += charWidth;
#define M c += Sprite3x5(c_m,floor(p-cpos)); cpos.x += charWidth;
#define N c += Sprite3x5(c_n,floor(p-cpos)); cpos.x += charWidth;
#define O c += Sprite3x5(c_o,floor(p-cpos)); cpos.x += charWidth;
#define P c += Sprite3x5(c_p,floor(p-cpos)); cpos.x += charWidth;
#define Q c += Sprite3x5(c_q,floor(p-cpos)); cpos.x += charWidth;
#define R c += Sprite3x5(c_r,floor(p-cpos)); cpos.x += charWidth;
#define S c += Sprite3x5(c_s,floor(p-cpos)); cpos.x += charWidth;
#define T c += Sprite3x5(c_t,floor(p-cpos)); cpos.x += charWidth;
#define U c += Sprite3x5(c_u,floor(p-cpos)); cpos.x += charWidth;
#define V c += Sprite3x5(c_v,floor(p-cpos)); cpos.x += charWidth;
#define W c += Sprite3x5(c_w,floor(p-cpos)); cpos.x += charWidth;
#define X c += Sprite3x5(c_x,floor(p-cpos)); cpos.x += charWidth;
#define Y c += Sprite3x5(c_y,floor(p-cpos)); cpos.x += charWidth;
#define Z c += Sprite3x5(c_z,floor(p-cpos)); cpos.x += charWidth;

#define _0 c += Sprite3x5(c_0,floor(p-cpos)); cpos.x += charWidth;
#define _1 c += Sprite3x5(c_1,floor(p-cpos)); cpos.x += charWidth;
#define _2 c += Sprite3x5(c_2,floor(p-cpos)); cpos.x += charWidth;
#define _3 c += Sprite3x5(c_3,floor(p-cpos)); cpos.x += charWidth;
#define _4 c += Sprite3x5(c_4,floor(p-cpos)); cpos.x += charWidth;
#define _5 c += Sprite3x5(c_5,floor(p-cpos)); cpos.x += charWidth;
#define _6 c += Sprite3x5(c_6,floor(p-cpos)); cpos.x += charWidth;
#define _7 c += Sprite3x5(c_7,floor(p-cpos)); cpos.x += charWidth;
#define _8 c += Sprite3x5(c_8,floor(p-cpos)); cpos.x += charWidth;
#define _9 c += Sprite3x5(c_9,floor(p-cpos)); cpos.x += charWidth;

    
//returns 0/1 based on the state of the given bit in the given number
float getBit(float num,float bit)
{
    num = floor(num);
    bit = floor(bit);
    
    return float(mod(floor(num/pow(2.,bit)),2.) == 1.0);
}

float Sprite3x5(float sprite,vec2 p)
{
    p.y = 4.0-p.y;
    float bounds = float(all(lessThan(p,vec2(3,5))) && all(greaterThanEqual(p,vec2(0,0))));
    
    return getBit(sprite,(2.0 - p.x) + 3.0 * p.y) * bounds;
}

float debugPrint(vec2 p) {
    float c = 0.0;

    //Mouse X position
    vec2 cpos = vec2(lineOffset,0);
    
    H E L L O _ W O R L D EX NL
    T H I S _ I S _ A _ N E W _ L I N E PE NL
    NL
    V O I D _ M A I N LP V O I D RP LB NL
    _ _ G L US F R A G C O L O R _ EQ _ V E C _4 LP _1 CM _0 PE _5 CM _0 PE _2 _5 CM _1 RP SC NL
    RB NL
    
    
    return c;
}

void main( void ) {
    vec2 p = (( gl_FragCoord.xy / resolution.xy ) - vec2(0.5, 1.0)) * vec2(256,128);
    float py = p.y;
    p.x /= -py * 0.012 + 0.2;
    p.y = -py/128.0;
    p.y = 1.0-p.y;
    p.y = -pow(p.y + 0.8, 4.0) * 20.0;
    p.y += time * 10.0;
    
    if (p.y < -8.0) {p.y = 0.0;}
    p.y = mod(p.y+6.0, 70.0);

    float c = debugPrint(p) * 1.2 * pow(-(py/128.0), 0.6);

    glFragColor = vec4( c, c, 0.0, 1.0 );
}

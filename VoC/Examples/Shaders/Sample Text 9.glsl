#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/ftS3Rw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// GPU printf
// Inspired by https://www.shadertoy.com/view/Mt2GWD
// Thanks to morimea for spotting bug/suggestion.
//
// Usage: see drawText() for quick-start and API section for all available functions

// Options
#define GPF_MACROS                1        // use macros to ease writing text/numbers
#define GPF_SCALE                2.0        // scale the font
#define GPF_MAX_INT_DIGITS        10
#define GPF_MAX_DECIMAL_DIGITS    6

///////////////////////////////////////////////////////////////
// Data
///////////////////////////////////////////////////////////////

// Automatically generated from the 8x12 font sheet here:
// http://www.massmind.org/techref/datafile/charset/extractor/charset_extractor.htm

vec4 gpf_digits[10] = vec4[]
(
    vec4(0x007CC6,0xD6D6D6,0xD6D6C6,0x7C0000), // 0
    vec4(0x001030,0xF03030,0x303030,0xFC0000), // 1
    vec4(0x0078CC,0xCC0C18,0x3060CC,0xFC0000), // 2
    vec4(0x0078CC,0x0C0C38,0x0C0CCC,0x780000), // 3
    vec4(0x000C1C,0x3C6CCC,0xFE0C0C,0x1E0000), // 4
    vec4(0x00FCC0,0xC0C0F8,0x0C0CCC,0x780000), // 5
    vec4(0x003860,0xC0C0F8,0xCCCCCC,0x780000), // 6
    vec4(0x00FEC6,0xC6060C,0x183030,0x300000), // 7
    vec4(0x0078CC,0xCCEC78,0xDCCCCC,0x780000), // 8
    vec4(0x0078CC,0xCCCC7C,0x181830,0x700000)  // 9
);

// ascii table starting from 32
vec4 ch_spc = vec4(0x000000,0x000000,0x000000,0x000000); // (space)
vec4 ch_exc = vec4(0x003078,0x787830,0x300030,0x300000); // !
vec4 ch_quo = vec4(0x006666,0x662400,0x000000,0x000000); // "
vec4 ch_hsh = vec4(0x006C6C,0xFE6C6C,0x6CFE6C,0x6C0000); // #
vec4 ch_dol = vec4(0x30307C,0xC0C078,0x0C0CF8,0x303000); // $
vec4 ch_pct = vec4(0x000000,0xC4CC18,0x3060CC,0x8C0000); // %
vec4 ch_amp = vec4(0x0070D8,0xD870FA,0xDECCDC,0x760000); // &
vec4 ch_apo = vec4(0x003030,0x306000,0x000000,0x000000); // '
vec4 ch_lbr = vec4(0x000C18,0x306060,0x603018,0x0C0000); // (
vec4 ch_rbr = vec4(0x006030,0x180C0C,0x0C1830,0x600000); // )
vec4 ch_ast = vec4(0x000000,0x663CFF,0x3C6600,0x000000); // *
vec4 ch_crs = vec4(0x000000,0x18187E,0x181800,0x000000); // +
vec4 ch_com = vec4(0x000000,0x000000,0x000038,0x386000); // ,
vec4 ch_dsh = vec4(0x000000,0x0000FE,0x000000,0x000000); // -
vec4 ch_per = vec4(0x000000,0x000000,0x000038,0x380000); // .
vec4 ch_lsl = vec4(0x000002,0x060C18,0x3060C0,0x800000); // /
vec4 ch_0   = vec4(0x007CC6,0xD6D6D6,0xD6D6C6,0x7C0000); // 0
vec4 ch_1   = vec4(0x001030,0xF03030,0x303030,0xFC0000); // 1
vec4 ch_2   = vec4(0x0078CC,0xCC0C18,0x3060CC,0xFC0000); // 2
vec4 ch_3   = vec4(0x0078CC,0x0C0C38,0x0C0CCC,0x780000); // 3
vec4 ch_4   = vec4(0x000C1C,0x3C6CCC,0xFE0C0C,0x1E0000); // 4
vec4 ch_5   = vec4(0x00FCC0,0xC0C0F8,0x0C0CCC,0x780000); // 5
vec4 ch_6   = vec4(0x003860,0xC0C0F8,0xCCCCCC,0x780000); // 6
vec4 ch_7   = vec4(0x00FEC6,0xC6060C,0x183030,0x300000); // 7
vec4 ch_8   = vec4(0x0078CC,0xCCEC78,0xDCCCCC,0x780000); // 8
vec4 ch_9   = vec4(0x0078CC,0xCCCC7C,0x181830,0x700000); // 9
vec4 ch_col = vec4(0x000000,0x383800,0x003838,0x000000); // :
vec4 ch_scl = vec4(0x000000,0x383800,0x003838,0x183000); // ;
vec4 ch_les = vec4(0x000C18,0x3060C0,0x603018,0x0C0000); // <
vec4 ch_equ = vec4(0x000000,0x007E00,0x7E0000,0x000000); // =
vec4 ch_grt = vec4(0x006030,0x180C06,0x0C1830,0x600000); // >
vec4 ch_que = vec4(0x0078CC,0x0C1830,0x300030,0x300000); // ?
vec4 ch_ats = vec4(0x007CC6,0xC6DEDE,0xDEC0C0,0x7C0000); // @
vec4 ch_A   = vec4(0x003078,0xCCCCCC,0xFCCCCC,0xCC0000); // A
vec4 ch_B   = vec4(0x00FC66,0x66667C,0x666666,0xFC0000); // B
vec4 ch_C   = vec4(0x003C66,0xC6C0C0,0xC0C666,0x3C0000); // C
vec4 ch_D   = vec4(0x00F86C,0x666666,0x66666C,0xF80000); // D
vec4 ch_E   = vec4(0x00FE62,0x60647C,0x646062,0xFE0000); // E
vec4 ch_F   = vec4(0x00FE66,0x62647C,0x646060,0xF00000); // F
vec4 ch_G   = vec4(0x003C66,0xC6C0C0,0xCEC666,0x3E0000); // G
vec4 ch_H   = vec4(0x00CCCC,0xCCCCFC,0xCCCCCC,0xCC0000); // H
vec4 ch_I   = vec4(0x007830,0x303030,0x303030,0x780000); // I
vec4 ch_J   = vec4(0x001E0C,0x0C0C0C,0xCCCCCC,0x780000); // J
vec4 ch_K   = vec4(0x00E666,0x6C6C78,0x6C6C66,0xE60000); // K
vec4 ch_L   = vec4(0x00F060,0x606060,0x626666,0xFE0000); // L
vec4 ch_M   = vec4(0x00C6EE,0xFEFED6,0xC6C6C6,0xC60000); // M
vec4 ch_N   = vec4(0x00C6C6,0xE6F6FE,0xDECEC6,0xC60000); // N
vec4 ch_O   = vec4(0x00386C,0xC6C6C6,0xC6C66C,0x380000); // O
vec4 ch_P   = vec4(0x00FC66,0x66667C,0x606060,0xF00000); // P
vec4 ch_Q   = vec4(0x00386C,0xC6C6C6,0xCEDE7C,0x0C1E00); // Q
vec4 ch_R   = vec4(0x00FC66,0x66667C,0x6C6666,0xE60000); // R
vec4 ch_S   = vec4(0x0078CC,0xCCC070,0x18CCCC,0x780000); // S
vec4 ch_T   = vec4(0x00FCB4,0x303030,0x303030,0x780000); // T
vec4 ch_U   = vec4(0x00CCCC,0xCCCCCC,0xCCCCCC,0x780000); // U
vec4 ch_V   = vec4(0x00CCCC,0xCCCCCC,0xCCCC78,0x300000); // V
vec4 ch_W   = vec4(0x00C6C6,0xC6C6D6,0xD66C6C,0x6C0000); // W
vec4 ch_X   = vec4(0x00CCCC,0xCC7830,0x78CCCC,0xCC0000); // X
vec4 ch_Y   = vec4(0x00CCCC,0xCCCC78,0x303030,0x780000); // Y
vec4 ch_Z   = vec4(0x00FECE,0x981830,0x6062C6,0xFE0000); // Z
vec4 ch_lsb = vec4(0x003C30,0x303030,0x303030,0x3C0000); // [
vec4 ch_rsl = vec4(0x000080,0xC06030,0x180C06,0x020000); // right slash
vec4 ch_rsb = vec4(0x003C0C,0x0C0C0C,0x0C0C0C,0x3C0000); // ]
vec4 ch_pow = vec4(0x10386C,0xC60000,0x000000,0x000000); // ^
vec4 ch_usc = vec4(0x000000,0x000000,0x000000,0x00FF00); // _
vec4 ch_a   = vec4(0x000000,0x00780C,0x7CCCCC,0x760000); // a
vec4 ch_b   = vec4(0x00E060,0x607C66,0x666666,0xDC0000); // b
vec4 ch_c   = vec4(0x000000,0x0078CC,0xC0C0CC,0x780000); // c
vec4 ch_d   = vec4(0x001C0C,0x0C7CCC,0xCCCCCC,0x760000); // d
vec4 ch_e   = vec4(0x000000,0x0078CC,0xFCC0CC,0x780000); // e
vec4 ch_f   = vec4(0x00386C,0x6060F8,0x606060,0xF00000); // f
vec4 ch_g   = vec4(0x000000,0x0076CC,0xCCCC7C,0x0CCC78); // g
vec4 ch_h   = vec4(0x00E060,0x606C76,0x666666,0xE60000); // h
vec4 ch_i   = vec4(0x001818,0x007818,0x181818,0x7E0000); // i
vec4 ch_j   = vec4(0x000C0C,0x003C0C,0x0C0C0C,0xCCCC78); // j
vec4 ch_k   = vec4(0x00E060,0x60666C,0x786C66,0xE60000); // k
vec4 ch_l   = vec4(0x007818,0x181818,0x181818,0x7E0000); // l
vec4 ch_m   = vec4(0x000000,0x00FCD6,0xD6D6D6,0xC60000); // m
vec4 ch_n   = vec4(0x000000,0x00F8CC,0xCCCCCC,0xCC0000); // n
vec4 ch_o   = vec4(0x000000,0x0078CC,0xCCCCCC,0x780000); // o
vec4 ch_p   = vec4(0x000000,0x00DC66,0x666666,0x7C60F0); // p
vec4 ch_q   = vec4(0x000000,0x0076CC,0xCCCCCC,0x7C0C1E); // q
vec4 ch_r   = vec4(0x000000,0x00EC6E,0x766060,0xF00000); // r
vec4 ch_s   = vec4(0x000000,0x0078CC,0x6018CC,0x780000); // s
vec4 ch_t   = vec4(0x000020,0x60FC60,0x60606C,0x380000); // t
vec4 ch_u   = vec4(0x000000,0x00CCCC,0xCCCCCC,0x760000); // u
vec4 ch_v   = vec4(0x000000,0x00CCCC,0xCCCC78,0x300000); // v
vec4 ch_w   = vec4(0x000000,0x00C6C6,0xD6D66C,0x6C0000); // w
vec4 ch_x   = vec4(0x000000,0x00C66C,0x38386C,0xC60000); // x
vec4 ch_y   = vec4(0x000000,0x006666,0x66663C,0x0C18F0); // y
vec4 ch_z   = vec4(0x000000,0x00FC8C,0x1860C4,0xFC0000); // z
vec4 ch_lpa = vec4(0x001C30,0x3060C0,0x603030,0x1C0000); // {
vec4 ch_bar = vec4(0x001818,0x181800,0x181818,0x180000); // |
vec4 ch_rpa = vec4(0x00E030,0x30180C,0x183030,0xE00000); // }
vec4 ch_tid = vec4(0x0073DA,0xCE0000,0x000000,0x000000); // ~
vec4 ch_lar = vec4(0x000000,0x10386C,0xC6C6FE,0x000000); // DEL

///////////////////////////////////////////////////////////////
// API
///////////////////////////////////////////////////////////////

// globals
vec2 gpf_gRes      = vec2(0); // by default init to top-left
vec2 gpf_gPrintPos = vec2(0);
vec2 gpf_gUV       = vec2(0);

vec2  gpf_char_size()                   { return vec2(8, 12); }
float gpf_char_size_x()                 { return gpf_char_size().x; }
float gpf_char_size_y()                 { return gpf_char_size().y; }
vec2  gpf_char_spacing()                { return vec2(8, 12); }
float gpf_char_spacing_x()              { return gpf_char_spacing().x; }
float gpf_char_spacing_y()              { return gpf_char_spacing().y; }
void  gpf_reset_pos()                   { gpf_gPrintPos = vec2(0.0, gpf_gRes.y - gpf_char_spacing_y()); }
void  gpf_set_pos(float x, float y)     { gpf_gPrintPos = vec2(x, y); }
void  gpf_newline()                     { gpf_gPrintPos.x = 0.0; gpf_gPrintPos.y -= gpf_char_spacing_y(); }
void  gpf_init(vec2 res, vec2 scrcoord) { gpf_gRes = res / GPF_SCALE; gpf_reset_pos(); gpf_gUV = floor(scrcoord.xy / GPF_SCALE); }
float gpf_char(vec4 ch);
float gpf_print_number(float number);
float gpf_print_integer(float number, int zeros);

///////////////////////////////////////////////////////////////
// Implementation
///////////////////////////////////////////////////////////////

// Extracts bit b from the given number.
// Shifts bits right (num / 2^bit) then ANDs the result with 1 (mod(result,2.0)).
float _gpf_extract_bit(float n, float b)
{
    b = clamp(b,-1.0,24.0);
    return floor(mod(floor(n / pow(2.0,floor(b))),2.0));   
}

// Returns the pixel at uv in the given bit-packed _gpf_sprite.
float _gpf_sprite(vec4 spr, vec2 size, vec2 uv)
{
    uv = floor(uv);
    
    //Calculate the bit to extract (x + y * width) (flipped on x-axis)
    float bit = (size.x-uv.x-1.0) + uv.y * size.x;
    
    //Clipping bound to remove garbage outside the _gpf_sprite's boundaries.
    bool bounds = all(greaterThanEqual(uv,vec2(0))) && all(lessThan(uv,size));
    
    float pixels = 0.0;
    pixels += _gpf_extract_bit(spr.x, bit - 72.0);
    pixels += _gpf_extract_bit(spr.y, bit - 48.0);
    pixels += _gpf_extract_bit(spr.z, bit - 24.0);
    pixels += _gpf_extract_bit(spr.w, bit - 00.0);
    
    return bounds ? pixels : 0.0;
}

// Returns the digit _gpf_sprite for the given number.
vec4 _gpf_get_digit(int index)
{
    return 0 <= index && index < 10 ? gpf_digits[index] : gpf_digits[0];
}

// value >= 0
int _gpf_count_digits(int value, int maxDigits)
{
    int count = 1;
    
    for (int i=0; i<maxDigits; i++)
    {        
        value /= 10;
        if (value == 0)
            break;
        count++;
    }
    
    return count;
}

// value >= 0
// NOTE: modifies value
ivec2 _gpf_count_decimal_digits(inout int value, int maxDigits)
{
    int zeros = 0;
    for (int i=0; i<maxDigits; i++)
    {
        if (value == 0)
            break;
        if (value % 10 > 0)
            break;
        value /= 10;
        zeros++;
    }
    return ivec2(_gpf_count_digits(value, maxDigits), zeros);
}

// draw from last digit to first
float _gpf_int_positive(int value, int digitCount)
{
    float result = 0.0;
    
    gpf_gPrintPos.x += gpf_char_spacing_x() * float(digitCount - 1);

    for (int i=0; i<digitCount; i++)
    {
        result += gpf_char(_gpf_get_digit(value % 10));
        value /= 10;
        gpf_gPrintPos.x -= 2.0 * gpf_char_spacing_x();
    }
    gpf_gPrintPos.x += gpf_char_spacing_x() * float(digitCount + 1);

    return result;
}

// Prints a character and moves the print position forward by 1 character width.
float gpf_char(vec4 ch)
{
    vec2 uv = gpf_gUV;
    
    float px = _gpf_sprite(ch, gpf_char_size(), uv - gpf_gPrintPos);
    gpf_gPrintPos.x += gpf_char_spacing_x();
    return px;
}

float gpf_int(int value)
{
    float result = 0.0;
    
    if (value == -2147483648)
    {
        result += gpf_char(ch_dsh);
        result += gpf_char(ch_2);
        result += gpf_char(ch_1);
        result += gpf_char(ch_4);
        result += gpf_char(ch_7);
        result += gpf_char(ch_4);
        result += gpf_char(ch_8);
        result += gpf_char(ch_3);
        result += gpf_char(ch_6);
        result += gpf_char(ch_4);
        result += gpf_char(ch_8);        
    }
    else
    {
        if (value < 0)
        {
            result += gpf_char(ch_dsh); // add -
            value = -value;
        }

        int digitCount = _gpf_count_digits(value, GPF_MAX_INT_DIGITS);
        result += _gpf_int_positive(value, digitCount);
    }
        
    return result;
}

int _gpf_int_pow(int a, int b)
{
    int ret = 1;
    for (int i=0; i<b; i++)
        ret *= a;
    return ret;
}

float _gpf_float_frac(float value, int maxDecimalDigits)
{
    float result = 0.0;       
    
    int decimalValue = int(fract(abs(value)) * float(_gpf_int_pow(10, maxDecimalDigits)));
    if (decimalValue == 0)
    {
        result += gpf_char(ch_0);
    }
    else
    {
        ivec2 decimalDigits = _gpf_count_decimal_digits(decimalValue, maxDecimalDigits);
        int lzeros = maxDecimalDigits - decimalDigits.x - decimalDigits.y;
        for (int i=0; i<lzeros; i++)
            result += gpf_char(ch_0);
        result += _gpf_int_positive(decimalValue, decimalDigits.x);
    }    
    
    return result;
}

float gpf_float(float value, int maxDecimalDigits)
{
    float result = 0.0;
    
    if (isnan(value))
    {
        result += gpf_char(ch_N);
        result += gpf_char(ch_a);
        result += gpf_char(ch_N);
    }    
    else if (isinf(value))
    {
        result += gpf_char(ch_I);
        result += gpf_char(ch_n);
        result += gpf_char(ch_f);
    }
    else
    {
        result += gpf_int(int(value));
        result += gpf_char(ch_per); // .
        result += _gpf_float_frac(value, maxDecimalDigits);
    }
    
    return result;
}

///////////////////////////////////////////////////////////////
// Macros
///////////////////////////////////////////////////////////////
#if GPF_MACROS
    #define _a    col += gpf_char(ch_a);
    #define _b    col += gpf_char(ch_b);
    #define _c    col += gpf_char(ch_c);
    #define _d    col += gpf_char(ch_d);
    #define _e    col += gpf_char(ch_e);
    #define _f    col += gpf_char(ch_f);
    #define _g    col += gpf_char(ch_g);
    #define _h    col += gpf_char(ch_h);
    #define _i    col += gpf_char(ch_i);
    #define _j    col += gpf_char(ch_j);
    #define _k    col += gpf_char(ch_k);
    #define _l    col += gpf_char(ch_l);
    #define _m    col += gpf_char(ch_m);
    #define _n    col += gpf_char(ch_n);
    #define _o    col += gpf_char(ch_o);
    #define _p    col += gpf_char(ch_p);
    #define _q    col += gpf_char(ch_q);
    #define _r    col += gpf_char(ch_r);
    #define _s    col += gpf_char(ch_s);
    #define _t    col += gpf_char(ch_t);
    #define _u    col += gpf_char(ch_u);
    #define _v    col += gpf_char(ch_v);
    #define _w    col += gpf_char(ch_w);
    #define _x    col += gpf_char(ch_x);
    #define _y    col += gpf_char(ch_y);
    #define _z    col += gpf_char(ch_z);
    #define _A    col += gpf_char(ch_A);
    #define _B    col += gpf_char(ch_B);
    #define _C    col += gpf_char(ch_C);
    #define _D    col += gpf_char(ch_D);
    #define _E    col += gpf_char(ch_E);
    #define _F    col += gpf_char(ch_F);
    #define _G    col += gpf_char(ch_G);
    #define _H    col += gpf_char(ch_H);
    #define _I    col += gpf_char(ch_I);
    #define _J    col += gpf_char(ch_J);
    #define _K    col += gpf_char(ch_K);
    #define _L    col += gpf_char(ch_L);
    #define _M    col += gpf_char(ch_M);
    #define _N    col += gpf_char(ch_N);
    #define _O    col += gpf_char(ch_O);
    #define _P    col += gpf_char(ch_P);
    #define _Q    col += gpf_char(ch_Q);
    #define _R    col += gpf_char(ch_R);
    #define _S    col += gpf_char(ch_S);
    #define _T    col += gpf_char(ch_T);
    #define _U    col += gpf_char(ch_U);
    #define _V    col += gpf_char(ch_V);
    #define _W    col += gpf_char(ch_W);
    #define _X    col += gpf_char(ch_X);
    #define _Y    col += gpf_char(ch_Y);
    #define _Z    col += gpf_char(ch_Z);
    #define _0    col += gpf_char(ch_0);
    #define _1    col += gpf_char(ch_1);
    #define _2    col += gpf_char(ch_2);
    #define _3    col += gpf_char(ch_3);
    #define _4    col += gpf_char(ch_4);
    #define _5    col += gpf_char(ch_5);
    #define _6    col += gpf_char(ch_6);
    #define _7    col += gpf_char(ch_7);
    #define _8    col += gpf_char(ch_8);
    #define _9    col += gpf_char(ch_9);
    #define _    col += gpf_char(ch_spc);
    
    #define _newline_    gpf_newline();    
    #define println_i(x)   col += gpf_int(x); _newline_
    #define println_f(x)   col += gpf_float(x, GPF_MAX_DECIMAL_DIGITS); _newline_
    #define print_i(x)     col += gpf_int(x)
    #define print_f(x)     col += gpf_float(x, GPF_MAX_DECIMAL_DIGITS)
#endif // #if GPF_MACROS

float drawText(vec2 screenCoord)
{
    gpf_init(resolution.xy, screenCoord.xy);
    
    float col = 0.0f;
            
    ///////////////////////////////////////////////////
    // using GPF_MACROS
    ///////////////////////////////////////////////////
    _H _e _l _l _o _ _W _o _r _l _d _newline_
    println_i(-2147483648);
    println_i(0);
    println_i(2147483647);
    println_f(-1.52);
    println_f( 0.0);
    println_f( 0.05);
    println_f(0.234);
    println_f( 123459.1);
    println_f(1.0/0.0);
    println_f(0.0/0.0);
    
    
    ///////////////////////////////////////////////////
    // manual
    ///////////////////////////////////////////////////
    gpf_newline();
    col += gpf_char(ch_H);
    col += gpf_char(ch_e);
    col += gpf_char(ch_l);
    col += gpf_char(ch_l);
    col += gpf_char(ch_o);
    
    // Integers
    gpf_newline();
    col += gpf_int(-1);
    gpf_newline();
    col += gpf_int(12);
    
    gpf_newline();
    
    // Symbols
    col += gpf_char(ch_spc); col += gpf_char(ch_exc); col += gpf_char(ch_quo); col += gpf_char(ch_hsh);
    col += gpf_char(ch_dol); col += gpf_char(ch_pct); col += gpf_char(ch_amp); col += gpf_char(ch_apo);
    col += gpf_char(ch_lbr); col += gpf_char(ch_rbr); col += gpf_char(ch_ast); col += gpf_char(ch_crs);
    col += gpf_char(ch_com); col += gpf_char(ch_dsh); col += gpf_char(ch_per); col += gpf_char(ch_lsl);
    col += gpf_char(ch_col); col += gpf_char(ch_scl); col += gpf_char(ch_les); col += gpf_char(ch_equ);
    col += gpf_char(ch_grt); col += gpf_char(ch_que); col += gpf_char(ch_ats); col += gpf_char(ch_lsb);
    col += gpf_char(ch_rsl); col += gpf_char(ch_rsb); col += gpf_char(ch_pow); col += gpf_char(ch_usc);
    col += gpf_char(ch_lpa); col += gpf_char(ch_bar); col += gpf_char(ch_rpa); col += gpf_char(ch_tid);
    col += gpf_char(ch_lar);
        
    return col;
}

void main(void)
{
    float pixel = drawText(gl_FragCoord.xy);
    glFragColor = vec4(vec3(pixel), 1.0);
}

#version 420

// original https://www.shadertoy.com/view/MljGWG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//-------------------------------------------------------------------------
// general utilities

// workaround for "index expression must be constant"
float vec4ItemAt(vec4 v, int i)
{
    for(int x = 0; x < 4; ++ x)
        if(x == i) return v[x];
    return v[3];
}
float rshift(float val, float amt)
{
    return floor(val / pow(2.0, amt));
}
// returns 0.0 or 1.0
float extractBit(float fv, float bitIndex)
{
    fv = floor(fv / pow(2., bitIndex));// shift right bitIndex and remove unwanted bits to the right
    fv /= 2.;// shift one more to put our value into decimal portion
    fv = fract(fv);// our value is now isolated. fv is now exactly 0.0 or approx.0.5
    return sign(fv);
}

// gl_FragCoord to uv coords. you specify y-dimension min & viewport size
// x is then aspect-corrected
vec2 getuv(vec2 Coord, float ymin, float ysize)
{
    vec2 ret = vec2(Coord.x, resolution.y - Coord.y) / resolution.y * ysize;
    return ret + vec2(ymin * resolution.x / resolution.y, ymin);
}

vec4 gridOverlay(vec4 inpColor, vec2 uv)
{
    if(length(uv) < 0.03)// origin
        return vec4(1.0,0.,0.,1.);
    if(length(mod(uv, 0.125)) < 0.02)// minor
    {
        // blue = negative
        if(uv.x < 0. && uv.y < 0.) return vec4(.2,.2,.9,1.);
        // red = positive
        if(uv.x > 0. && uv.y > 0.) return vec4(0.9,0.2,.2,1.);
        return vec4(0.7,0.7,.7,1.);// gray
    }
    if(length(mod(uv.x, 1.)) < 0.007)// major x
        return vec4(1.0,0.7,0.7,1.);
    return inpColor;
}

//-------------------------------------------------------------------------
// font drawing code ...

// too bad this can't be const :(
const int glyphCount = 38;
vec4 glyphData[glyphCount];

void initFont()
{
    // each 16-bit unsigned value here represents 2 scanlines (8 bits each).
    // each glyph is 8 scanlines, which means each glyph takes 4 values,
    // so this is why we use vec4. if glsl supported unsigned integers
    // or double-precision floats, we could do it using 2 components.
    // but it really doesn't matter much.
    // i generated this manually using an excel spreadsheet :x
    glyphData[0] = vec4(0x183C, 0x667E, 0x6666, 0x6600);// A
    glyphData[1] = vec4(0x7C66, 0x667C, 0x6666, 0x7C00);// B
    glyphData[2] = vec4(0x3C66, 0x6060, 0x6066, 0x3C00);// C
    glyphData[3] = vec4(0x786C, 0x6666, 0x666C, 0x7800);// D
    glyphData[4] = vec4(0x7E60, 0x6078, 0x6060, 0x7E00);// E
    glyphData[5] = vec4(0x7E60, 0x6078, 0x6060, 0x6000);// F
    glyphData[6] = vec4(0x3C66, 0x606E, 0x6666, 0x3C00);// G
    glyphData[7] = vec4(0x6666, 0x667E, 0x6666, 0x6600);// H
    glyphData[8] = vec4(0x3C18, 0x1818, 0x1818, 0x3C00);// I
    glyphData[9] = vec4(0x1E0C, 0x0C0C, 0x0C6C, 0x3800);// J
    glyphData[10] = vec4(0x666C, 0x7870, 0x786C, 0x6600);// K
    glyphData[11] = vec4(0x6060, 0x6060, 0x6060, 0x7E00);// L
    glyphData[12] = vec4(0x6377, 0x7F6B, 0x6363, 0x6300);// M
    glyphData[13] = vec4(0x6676, 0x7E6E, 0x6666, 0x6600);// N
    glyphData[14] = vec4(0x3C66, 0x6666, 0x6666, 0x3C00);// O
    glyphData[15] = vec4(0x7C66, 0x6666, 0x7C60, 0x6000);// P
    glyphData[16] = vec4(0x3C66, 0x6666, 0x663C, 0x0E00);// Q
    glyphData[17] = vec4(0x7C66, 0x667C, 0x786C, 0x6600);// R
    glyphData[18] = vec4(0x3C66, 0x603C, 0x0666, 0x3C00);// S
    glyphData[19] = vec4(0x7E18, 0x1818, 0x1818, 0x1800);// T
    glyphData[20] = vec4(0x6666, 0x6666, 0x6666, 0x3C00);// U
    glyphData[21] = vec4(0x6666, 0x6666, 0x663C, 0x1800);// V
    glyphData[22] = vec4(0x6363, 0x636B, 0x7F77, 0x6300);// W
    glyphData[23] = vec4(0x6666, 0x3C18, 0x3C66, 0x6600);// X
    glyphData[24] = vec4(0x6666, 0x663C, 0x1818, 0x1800);// Y
    glyphData[25] = vec4(0x7E06, 0x0C18, 0x3060, 0x7E00);// Z
    glyphData[26] = vec4(0x3C66, 0x6E76, 0x6666, 0x3C00);// 0
    glyphData[27] = vec4(0x1818, 0x3818, 0x1818, 0x7E00);// 1
    glyphData[28] = vec4(0x3C66, 0x060C, 0x3060, 0x7E00);// 2
    glyphData[29] = vec4(0x3C66, 0x061C, 0x0666, 0x3C00);// 3
    glyphData[30] = vec4(0x060E, 0x1E66, 0x7F06, 0x0600);// 4
    glyphData[31] = vec4(0x7E60, 0x7C06, 0x0666, 0x3C00);// 5
    glyphData[32] = vec4(0x3C66, 0x607C, 0x6666, 0x3C00);// 6
    glyphData[33] = vec4(0x7E66, 0x0C18, 0x1818, 0x1800);// 7
    glyphData[34] = vec4(0x3C66, 0x663C, 0x6666, 0x3C00);// 8
    glyphData[35] = vec4(0x3C66, 0x663E, 0x0666, 0x3C00);// 9
    glyphData[36] = vec4(0x0000, 0x0000, 0x0018, 0x1800);// .
    glyphData[37] = vec4(0x0066, 0x3CFF, 0x3C66, 0x0000);// *
}

// workaround for "index expression must be constant"
vec4 getGlyphData(int i)
{
    for(int x = 0; x < glyphCount; ++ x)
        if(x == i) return glyphData[x];
    return glyphData[0];
}

// stringIndex lets you use the same pos for a string of chars, just incrementing stringIndex.
// this is pretty fast, but is binary. a prettier version might return a distance function but will suffer perf problems because of the complex geometry.
vec4 drawCharacter(vec4 inpColor, vec4 glyphColor, vec2 uv, vec2 pos, vec2 charSize, float stringIndex, int glyph)
{
    vec2 element = floor(((uv - pos) / (charSize / 8.)));// convert uv to pixel indices
    element.x -= stringIndex * 8.0;
    element.x = 7.0 - element.x;// flip X. maybe my encoding method is wrong?
    // bounds check; most of the time uv will not land on the character so important to optimize this.
    if(element.y < 0. || element.y > 7.) return inpColor;
    if(element.x < 0. || element.x > 7.) return inpColor;
    vec4 gd = getGlyphData(glyph);// contains 4 elements of 2 scanlines each
    int gdi = int(element.y / 2.0);// which element/doublescanline?
    float doubleScanlineData = vec4ItemAt(gd, gdi);
    float scanlineI = extractBit(element.y + 1.0, 0.);// scanline index is even/odd
    float byteData = rshift(doubleScanlineData, scanlineI * 8.0);
    float a = extractBit(byteData, element.x);
    return vec4(mix(inpColor.rgb, glyphColor.rgb, a * glyphColor.a), inpColor.a);
}

//-------------------------------------------------------------------------
vec4 hardRect(vec4 inpColor, vec4 rectColor, vec2 uv, vec2 tl, vec2 br)
{
    if(uv.x < tl.x)
        return inpColor;
    if(uv.x > br.x)
        return inpColor;
    if(uv.y < tl.y)
        return inpColor;
    if(uv.y > br.y)
        return inpColor;
    return rectColor;
}

float rand(vec2 co)
{
    float a = 12.9898;
    float b = 78.233;
    float c = 43758.5453;
    float dt= dot(co.xy ,vec2(a,b));
    float sn= mod(dt,3.14);
    return fract(sin(sn) * c);
}

void main(void)
{
    vec2 uv = getuv(gl_FragCoord.xy, 0.0, 2.6);
    //uv = getuv(gl_FragCoord, -2., 4.);

    // subtle distortion by drmelon, from https://www.shadertoy.com/view/4dBGzK#
    float magnitude = 0.0009;
    uv.x = uv.x + rand(vec2(time*0.004,uv.y*0.002)) * 0.004;
    uv.x += sin(time*9.0)*magnitude;
    
    initFont();
    
    vec4 darkBlue = vec4(0.21,0.16,0.47,1.0);
    vec4 lightBlue = vec4(0.42,0.37,0.71,1.0);

    // main background
    glFragColor = darkBlue;
    
    // border
    vec2 charAreaTL = vec2(0.6, 0.3);
    if(uv.x < charAreaTL.x)
        glFragColor = lightBlue;
    if(uv.y < charAreaTL.y)
        glFragColor = lightBlue;

    // ready.
    vec4 charColor = lightBlue;
    vec2 charSize = vec2(0.2);
    charSize.x *= 0.936;// c64 aspect ratio
    vec2 stringPos = charAreaTL + vec2(0, 1.0 * charSize.y);// line 1
    glFragColor = drawCharacter(glFragColor, charColor, uv, stringPos, charSize, 4., 37);// *
    glFragColor = drawCharacter(glFragColor, charColor, uv, stringPos, charSize, 5., 37);// *
    glFragColor = drawCharacter(glFragColor, charColor, uv, stringPos, charSize, 6., 37);// *
    glFragColor = drawCharacter(glFragColor, charColor, uv, stringPos, charSize, 7., 37);// *

    glFragColor = drawCharacter(glFragColor, charColor, uv, stringPos, charSize, 9., 2);// C
    glFragColor = drawCharacter(glFragColor, charColor, uv, stringPos, charSize, 10., 14);// O
    glFragColor = drawCharacter(glFragColor, charColor, uv, stringPos, charSize, 11., 12);// M
    glFragColor = drawCharacter(glFragColor, charColor, uv, stringPos, charSize, 12., 12);// M
    glFragColor = drawCharacter(glFragColor, charColor, uv, stringPos, charSize, 13., 14);// O
    glFragColor = drawCharacter(glFragColor, charColor, uv, stringPos, charSize, 14., 3);// D
    glFragColor = drawCharacter(glFragColor, charColor, uv, stringPos, charSize, 15., 14);// O
    glFragColor = drawCharacter(glFragColor, charColor, uv, stringPos, charSize, 16., 17);// R
    glFragColor = drawCharacter(glFragColor, charColor, uv, stringPos, charSize, 17., 4);// E

    glFragColor = drawCharacter(glFragColor, charColor, uv, stringPos, charSize, 19., 32);// 6
    glFragColor = drawCharacter(glFragColor, charColor, uv, stringPos, charSize, 20., 30);// 4
    
    stringPos = charAreaTL + vec2(0, 3.0 * charSize.y);// line 3
    glFragColor = drawCharacter(glFragColor, charColor, uv, stringPos, charSize, 1., 32);// 6
    glFragColor = drawCharacter(glFragColor, charColor, uv, stringPos, charSize, 2., 30);// 4
    glFragColor = drawCharacter(glFragColor, charColor, uv, stringPos, charSize, 3., 10);// K
    glFragColor = drawCharacter(glFragColor, charColor, uv, stringPos, charSize, 5., 17);// R
    glFragColor = drawCharacter(glFragColor, charColor, uv, stringPos, charSize, 6., 0);// A
    glFragColor = drawCharacter(glFragColor, charColor, uv, stringPos, charSize, 7., 12);// M

    glFragColor = drawCharacter(glFragColor, charColor, uv, stringPos, charSize, 9., 18);// S
    glFragColor = drawCharacter(glFragColor, charColor, uv, stringPos, charSize, 10., 24);// Y
    glFragColor = drawCharacter(glFragColor, charColor, uv, stringPos, charSize, 11., 18);// S
    glFragColor = drawCharacter(glFragColor, charColor, uv, stringPos, charSize, 12., 19);// T
    glFragColor = drawCharacter(glFragColor, charColor, uv, stringPos, charSize, 13., 4);// E
    glFragColor = drawCharacter(glFragColor, charColor, uv, stringPos, charSize, 14., 12);// M
    
    glFragColor = drawCharacter(glFragColor, charColor, uv, stringPos, charSize, 17., 29);// 3
    glFragColor = drawCharacter(glFragColor, charColor, uv, stringPos, charSize, 18., 34);// 8
    glFragColor = drawCharacter(glFragColor, charColor, uv, stringPos, charSize, 19., 35);// 9
    glFragColor = drawCharacter(glFragColor, charColor, uv, stringPos, charSize, 20., 27);// 1
    glFragColor = drawCharacter(glFragColor, charColor, uv, stringPos, charSize, 21., 27);// 1
    
    stringPos = charAreaTL + vec2(0, 5.0 * charSize.y);// line 5
    glFragColor = drawCharacter(glFragColor, charColor, uv, stringPos, charSize, 0., 17);// R
    glFragColor = drawCharacter(glFragColor, charColor, uv, stringPos, charSize, 1., 4);// E
    glFragColor = drawCharacter(glFragColor, charColor, uv, stringPos, charSize, 2., 0);// A
    glFragColor = drawCharacter(glFragColor, charColor, uv, stringPos, charSize, 3., 3);// D
    glFragColor = drawCharacter(glFragColor, charColor, uv, stringPos, charSize, 4., 24);// Y
    glFragColor = drawCharacter(glFragColor, charColor, uv, stringPos, charSize, 5., 36);// .
    
    if(mod(time, 1.) < 0.5)
    {
        vec2 tl = vec2(stringPos.x, stringPos.y + charSize.y);
        glFragColor = hardRect(glFragColor, charColor, uv, tl, tl + charSize);
    }
    
//    glFragColor = gridOverlay(glFragColor, uv);
}


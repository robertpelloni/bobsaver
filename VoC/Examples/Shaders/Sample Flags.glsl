#version 420

// original https://www.shadertoy.com/view/tdtSzn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

int flags = 10;
float flagTime = 2.0;

float triangleArea(vec2 a, vec2 b, vec2 c) 
{ 
   a = round(a * 10000.0); b = round(b * 10000.0); c = round(c * 10000.0);
   return abs((a.x * (b.y - c.y) + b.x * (c.y - a.y) + c.x * (a.y - b.y)) / 2.0); 
}

vec4 lerpCol(vec4 a, vec4 b, float t)
{
    return (1.0 - t) * a + t * b;
}

bool insideRect(vec2 a, vec2 b, vec2 pt)
{
    return pt.x >= a.x && pt.y >= a.y && pt.x <= b.x && pt.y <= b.y;
}

bool insideTri(vec2 a, vec2 b, vec2 c, vec2 pt) 
{    
   float A = triangleArea(a, b, c); 
   float A1 = triangleArea(pt, b, c); 
   float A2 = triangleArea(a, pt, c); 
   float A3 = triangleArea(a, b, pt); 
   return A == A1 + A2 + A3;
}

bool insideCircle(vec2 c, float r, vec2 pt)
{
    float aspect = resolution.x / resolution.y;
    return pow(r, 2.0) >= pow((pt.x - c.x) * aspect, 2.0) + pow(pt.y - c.y, 2.0);
}

bool insideStar(vec2 i, float x, vec2 test)
{   
    float aspect = resolution.x / resolution.y;
    float y = sqrt(pow(x, 2.0) / 3.0);
    float h = sqrt(pow(x + y, 2.0) + pow(2.0 * y, 2.0));
    float l = 2.0 * x + 2.0 * y;
    float z = (l - 4.0 * y) / 2.0;
    
    float a = i.x * aspect;
    float b = i.y;
    test = vec2(test.x * aspect, test.y);
    
    if(test.y < b || test.x < a || test.x > a + l || test.y > b + 5.0 * y)
        return false;
    
    vec2 pt1 = vec2(a + z, b);
    vec2 pt2 = vec2(a + x + y, b + y);
    vec2 pt3 = vec2(a + (l - z), b);
    vec2 pt4 = vec2(a + 2.0 * y, b + 2.0 * y);
    vec2 pt5 = vec2(a + (l - 2.0 * y), b + 2.0 * y);
    vec2 pt6 = vec2(a, b + 3.0 * y);
    vec2 pt7 = vec2(a + x, b + 3.0 * y);
    vec2 pt8 = vec2(a + (l - x), b + 3.0 * y);
    vec2 pt9 = vec2(a + l, b + 3.0 * y);
    vec2 pt10 = vec2(a + x + y, b + 5.0 * y);
    vec2 pt11 = vec2(a, b + 5.0 * y);
    vec2 pt12 = vec2(a + l, b + 5.0 * y);
    vec2 pt13 = vec2(a + l, b);
    
    if(!insideTri(i, pt1, pt6, test) &&
       !insideTri(pt1, pt4, pt6, test) &&
       !insideTri(pt1, pt2, pt3, test) &&
       !insideTri(pt3, pt5, pt9, test) &&
       !insideTri(pt3, pt9, pt13, test) &&
       !insideTri(pt6, pt10, pt11, test) &&
       !insideTri(pt6, pt7, pt10, test) &&
       !insideTri(pt8, pt9, pt10, test) &&
       !insideTri(pt9, pt10, pt12, test))
        return true;
    return false;
}

bool isInterval(float flag)
{
    float capTime = mod(time, float(flags) * flagTime);
    return capTime < flagTime * flag;
}

vec4 austria(vec2 coord)
{
    if(coord.y > 0.3333 && coord.y < 0.6666)
        return vec4(1,1,1,1);
    else
        return vec4(0.95,0,0.15,0);
}

vec4 bahamas(vec2 coord)
{
    vec2 a = vec2(0, 0), b = vec2(0.4, 0.5), c = vec2(0, 1);
    if(insideTri(a, b, c, coord))
        return vec4(0,0,0,1);
    else if(coord.y > 0.3333 && coord.y < 0.6666)
        return vec4(1,1,0,1);
       else
        return vec4(0,0.7,1,1);
}

vec4 botswana(vec2 coord)
{
    if(coord.y > 0.4 && coord.y < 0.6)
    {
        if(coord.y < 0.425 || coord.y > 0.575)
            return vec4(1,1,1,1);
        else
            return vec4(0,0,0,1);
    }
    else
        return vec4(0.35,0.6,1,1);
}

vec4 palau(vec2 coord)
{
    if(insideCircle(vec2(0.4, 0.5), 0.3, coord))
        return vec4(1,1,0,1);
    else
        return vec4(0,0.7,1,1);
}

vec4 guyana(vec2 coord)
{
    if(insideTri(vec2(1, 0.5), vec2(0, -0.04), vec2(0, 1.04), coord))
    {
        if(insideTri(vec2(0.94, 0.5), vec2(0, 0), vec2(0, 1), coord))
        {
            if(insideTri(vec2(0, 0), vec2(0.5, 0.5), vec2(0, 1), coord))
            {
                if(insideTri(vec2(0, 0.94), vec2(0, 0.06), vec2(0.44, 0.5), coord))
                    return vec4(1,0,0,1);
                else
                    return vec4(0,0,0,1);
            }
            else
                return vec4(1,1,0,1);
        }
        else
            return vec4(1,1,1,1);
    }
    else
        return vec4(0,0.7,0,1);
}

vec4 chile(vec2 coord)
{
    if(insideRect(vec2(0, 0.5), vec2(1.0 / 3.0, 1.0), coord))
    {
        if(insideStar(vec2(0.07, 0.6), 0.1, coord))
            return vec4(1,1,1,1);
        else
            return vec4(0.25,0.4,0.8,1);
    }
    else if(coord.y > 0.5)
        return vec4(1,1,1,1);
    else
        return vec4(0.9,0.2,0.2,1);
    
}

vec4 greece(vec2 coord)
{
    if(insideRect(vec2(0, 0.444), vec2(1.0 / 3.0, 1.0), coord))
    {
        if((coord.y - 0.45 < 0.345 && coord.y - 0.45 > 0.229) || (coord.x < 0.21 && coord.x > 0.14))
            return vec4(1,1,1,1);
        else
            return vec4(0.7,0.8,1,1);
    }
    else if(sin(coord.y * 27.0 - 12.0) > 0.0)
        return vec4(0.7,0.8,1,1);
    else
        return vec4(1,1,1,1);
}

vec4 indonesia(vec2 coord)
{
    if(coord.y > 0.5)
        return vec4(1,0,0,1);
    else
        return vec4(1,1,1,1);
}

vec4 japan(vec2 coord)
{
    if(insideCircle(vec2(0.5, 0.5), 0.32, coord))
        return vec4(1,0,0,1);
    else
        return vec4(1,1,1,1);
}

vec4 maldives(vec2 coord)
{
    if(insideRect(vec2(0.12, 0.18), vec2(0.9, 0.83), coord))
    {
        if(insideCircle(vec2(0.5, 0.5), 0.25, coord))
        {
            if(insideCircle(vec2(0.565, 0.5), 0.25, coord))
                return vec4(0,0.8,0.4,1);
            else
                return vec4(1,1,1,1);
        }
        else
            return vec4(0,0.8,0.4,1);
    }
    else
        return vec4(1,0.1,0.1,1);
}

vec4 getFlag(int id, vec2 coord)
{
    switch(id)
    {
        case 1: return austria(coord);
        case 2: return bahamas(coord);
        case 3: return botswana(coord);
        case 4: return palau(coord);
        case 5: return guyana(coord);
        case 6: return chile(coord);
        case 7: return greece(coord);
        case 8: return indonesia(coord);
        case 9: return japan(coord);
        case 10: return maldives(coord);
    }
}

void main(void)
{
    vec2 percent = gl_FragCoord.xy / resolution.xy;
    vec2 lin = gl_FragCoord.xy / resolution.xy;
    
    float powAmt = pow(percent.x * 2.0 + 0.5, 2.0) / 5.0 + 0.2;
    float sinAmt = (sin(time * 4.0 + percent.x + powAmt * 12.0) / 50.0) * powAmt;
    float shadSin = sin(time * 4.0 + (percent.x + 2.0) * 12.0) / 7.5;
    float sinAmtZero = (sin(time * 4.0 + powAmt * 12.0) / 50.0) * powAmt;
    
    percent = vec2(percent.x * 2.0 - 0.5, (percent.y + (sinAmt - sinAmtZero)) * 2.0 - 0.5);
    glFragColor -= vec4(shadSin, shadSin, shadSin, 0);
    
    if(percent.y > 1.0 || percent.y < 0.0 || percent.x > 1.0 || percent.x < 0.0)
    {
        float actualY = (gl_FragCoord.y / resolution.y) * 2.0 - 0.5;
        if(percent.x < 0.0 && percent.x > -0.1 && actualY < 1.1)
        {
            float xVal = (1.0 - percent.x / -0.1) / 2.0 + 0.25;
            glFragColor = vec4(xVal,xVal,xVal,0);
        }
        else
        {
            vec4 bCol = vec4(0.9,0.9,0.9,1);
            vec4 tCol = vec4(0.2,0.4,1.0,1);
            glFragColor = lerpCol(bCol, tCol, lin.y - lin.x / 4.0);
        }
    }
    else
    {
        for(int i = 1; i <= flags; i++)
        {
            if(isInterval(float(i)))
            {
                glFragColor += getFlag(i, percent);
                break;
            }
        }
    }
}

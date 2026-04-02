#version 420

// original https://www.shadertoy.com/view/wt3yzf

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

struct Line
{
    vec2 a;
    vec2 b;
    float thickness;
    float l;
};
Line newLine(vec2 a, vec2 b, float t)
{
    Line l;
    l.a = a;
    l.b = b;
    l.thickness = t;
    l.l = length(a-b);
    return l;
}
float dstToLine(Line l, vec2 c)
{
    float s1 = -l.b.y + l.a.y;
    float s2 = l.b.x - l.a.x;
    return abs((c.x - l.a.x) * s1 + (c.y - l.a.y) * s2) / sqrt(s1*s1 + s2*s2);
}

bool inLine(Line l, vec2 p)
{
    return (p.x-l.thickness < max(l.a.x,l.b.x) && p.x+l.thickness > min(l.a.x,l.b.x) && p.y-l.thickness < max(l.a.y,l.b.y) && p.y+l.thickness > min(l.a.y,l.b.y) && dstToLine(l,p) < l.thickness);
}
void DrawLine(inout vec3 col, vec2 p, Line l, vec3 c)
{
    if (inLine(l, p))
    {
        col = c;
    }
}

struct Display
{
    Line lines[7];
    /*
    middle
    upper
    lower
    
    upper left
    upper right
    lower left
    lower right
    */
};
Display newDisplay(vec2 middle, float t, float size)
{
    Display d;
    d.lines[0] = newLine(vec2(middle.x-size,middle.y), vec2(middle.x+size, middle.y), t);
    d.lines[1] = newLine(vec2(middle.x-size,middle.y+size*2.0f), vec2(middle.x+size, middle.y+size*2.0f), t);
    d.lines[2] = newLine(vec2(middle.x-size,middle.y-size*2.0f), vec2(middle.x+size, middle.y-size*2.0f), t);
    
    d.lines[3] = newLine(vec2(middle.x-size,middle.y+size*2.0f), vec2(middle.x-size,middle.y), t);
    d.lines[4] = newLine(vec2(middle.x+size,middle.y+size*2.0f), vec2(middle.x+size,middle.y), t);
    d.lines[5] = newLine(vec2(middle.x-size,middle.y-size*2.0f), vec2(middle.x-size,middle.y), t);
    d.lines[6] = newLine(vec2(middle.x+size,middle.y-size*2.0f), vec2(middle.x+size,middle.y), t);
    
    return d;
}

struct TwoDigitDisplay
{
    Display ones;
    Display tens;
};
TwoDigitDisplay newTwoDigitDisplay(vec2 middle, float t, float size)
{
    TwoDigitDisplay td;
    vec2 offset = vec2(size + 10.0f,0);
    td.tens = newDisplay(middle-offset, t, size);
    td.ones = newDisplay(middle+offset, t, size);
    return td;
}

void DrawDisplay(inout vec3 col, vec2 p, Display d, bool table[7], vec3 c)
{
    for (int i = 0; i < 7; i++)
    {
        if (table[i])
        {
            DrawLine(col,p,d.lines[i],c);
        }
    }
}
void DrawTDDisplay(inout vec3 col, vec2 p, TwoDigitDisplay t, bool a[7], bool b[7], vec3 co)
{
    DrawDisplay(col, p, t.tens, a, co);
    DrawDisplay(col, p, t.ones, b, co);
}
struct Numbers
{
    bool num[7];
};
Numbers newN(bool n[7])
{
    Numbers a;
    a.num = n;
    return a;
}
bool zero[7] = bool[7](false,true,true,true,true,true,true);

vec2 GetDigits(float value)
{
    return vec2(floor(value/10.0f), value - (floor(value/10.0f) * 10.0f));
}

void main(void)
{
    Numbers n[10] = Numbers[10]
    (
        newN(bool[7](false,true,true,true,true,true,true)), //0
        newN(bool[7](false,false,false,false,true,false,true)), //1
        newN(bool[7](true,true,true,false,true,true,false)), //2
        newN(bool[7](true,true,true,false,true,false,true)), //3
        newN(bool[7](true,false,false,true,true,false,true)), //4
        newN(bool[7](true,true,true,true,false,false,true)), //5
        newN(bool[7](true,true,true,true,false,true,true)), //6
        newN(bool[7](false,true,false,false,true,false,true)), //7
        newN(bool[7](true,true,true,true,true,true,true)), //8
        newN(bool[7](true,true,true,true,true,false,true)) //9
    );
    
    
    float hours = floor(date.w/60.0f/60.0f);
    vec2 hourD = GetDigits(hours);
    
    float mins = floor(date.w /60.0f- (hours*60.0f));
    vec2 minD = GetDigits(mins);
    
    float seconds = floor(date.w - (hours*60.0f*60.0f) - (mins*60.0f));
    vec2 secondD = GetDigits(seconds);
    
    
    
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 middle = resolution.xy / 2.0f;
    float size = resolution.y * 0.1f;

    // Time varying pixel color
    vec3 col = vec3(1,1,1);
    
    vec2 offset = vec2(200,0) * size * 0.02f;
    
    
    TwoDigitDisplay hourDis = newTwoDigitDisplay(middle-(1.5f*offset), 5.0f, size);
    DrawTDDisplay(col, gl_FragCoord.xy, hourDis, n[int(hourD.x)].num, n[int(hourD.y)].num, vec3(1,0,0));
    
    TwoDigitDisplay minDis = newTwoDigitDisplay(middle, 5.0f, size);
    DrawTDDisplay(col, gl_FragCoord.xy, minDis, n[int(minD.x)].num, n[int(minD.y)].num, vec3(0,1,0));
    
    TwoDigitDisplay secondDis = newTwoDigitDisplay(middle+(offset*1.5f), 5.0f, size);
    DrawTDDisplay(col, gl_FragCoord.xy, secondDis, n[int(secondD.x)].num, n[int(secondD.y)].num, vec3(0,0,1));
    
    
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}

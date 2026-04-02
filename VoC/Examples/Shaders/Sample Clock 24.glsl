#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/Wstyzl

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// port of:  https://www.shadertoy.com/view/MdVcRd
//
// I expanded this code in an effort to understand how it worked
// how its drew segments, how it layed out graphic elements, etc
// this is just the original with the preprocessor macros converted into functions
// and some extra explorative comments

vec4 manhattan_distance(float i, float j, int b, vec2 R)
{
    // Computes a smooth-edged diamond pixel value (Manhattan distance)
    return vec2(.1, b).xyxy * smoothstep(0., 9. / R.y, .1 - abs(i) - abs(j));
}

vec4 segment_value(float i, float j, int b, vec2 R)
{
    // Computes a segment value (length = 0.5)
    return manhattan_distance(i - clamp(i, 0., .5), j, b & 1, R);
}

void colon_render(float y, ivec4 i, vec2 R, inout float x, inout vec4 O, inout int t)
{
// Colon render

    x += .5;
    O += 
    manhattan_distance(
        x, 
        y + .3, 
        i.w / 50, 
        R
   ) 
   + manhattan_distance(
       x, 
       y - .3, 
       i.w / 50, 
       R
    );
    t /= 60;
}

vec4 s7_horrizontal(float i, float j, int b, float x, float y, vec2 R)
{
    // Computes the horizontal and vertical segments based on a denary digit
    return segment_value(x - i, y - j, b, R);
}

vec4 s7_vertical(float i, float j, int b, float x, float y, vec2 R)
{
    return segment_value(y - j, x - i, b, R);
}

void s7_segment(int n, inout vec4 O, inout float x, float y, vec2 R)
{
    // investigated with python:
    // {i: [bool((j>>i) & 1) for j in [892, 1005, 877, 881, 927, 325, 1019]] for i in range(10)}
    ++x; 
    O += segment_value(x, y, 892>>n, R)        // (1<<2 | 1<<3 | 1<<5 | 1 << 6 | 1<<8 | 1<<9)
                                               // 0b1101111100: true for 2,3,4,5,6,8,9
    + s7_horrizontal(0., .7, 1005>>n, x, y, R) // 0b1111101101: true for 0,2,3,5,6,7,8,9
    + s7_horrizontal(0., -.7, 877>>n, x, y, R) // 0b1101101101: true for 0,2,3,5,6,8,9
    + s7_vertical(-.1, .1, 881>>n, x, y, R)    // 0b1101110001: true for 0,4,5,6,8,9
    + s7_vertical(.6, .1, 927>>n, x, y, R)     // 0b1110011111: true for 0,1,2,3,4,7,8,9
    + s7_vertical(-.1, -.6, 325>>n, x, y, R)   // 0b0101000101: truw for 0,2,6,8
    + s7_vertical(.6, -.6, 1019>>n, x, y, R);  // 0b1111111011: truw for 0,1,3,4,5,6,7,8,9
                                               //    |   |   |
                                               //    |   |   \ zero
                                               //    |   |  \ one
                                               //    |   | \ two
                                               //    |   |\ three
                                               //    |   \ four
                                               //    |  \ five
                                               //    | \ six
                                               //    |\ seven
                                               //    \ eight
                                               //   \ nine
}

void two_digit_render(int n, inout vec4 O, inout float x, float y, vec2 R)
{
    // Two-digit render
    s7_segment(n % 10, O, x, y, R);
    s7_segment(n / 10, O, x, y, R);
}
    

void main(void)
{
    vec2 U = gl_FragCoord.xy;
    vec4 O = glFragColor;
    
    vec2 R = resolution.xy;
    U += U - R;
    U /= R.y / 3.; // Global scaling with aspect ratio correction
    O-=O; // Zero the pixel

    float x = U.x - U.y * .2 - 2.8, // Slight skew to slant the digits
          y = --U.y;
    ivec4 i = ivec4(date); // Convert everything to integers
    int t = i.w;
    i.w = int(date.w * 100.) % 100; // Replace with centiseconds
    
    // Seconds (preceded by a colon)
    two_digit_render(t % 60, O, x, y, R);
    colon_render(y, i, R, x, O, t);
    
    // Minutes (preceded by a colon)
    two_digit_render(t % 60, O, x, y, R);
    colon_render(y, i, R, x, O, t);
    
    // Hours
    two_digit_render(t, O, x, y, R);

    // Smaller digits
    x /= .6;
    y /= .6;
    R *= .6;

    // Centiseconds
    x -= 14.;
    y += .53;
    two_digit_render(i.w, O, x, y, R);

    // Day (preceded by a hyphen)
    x -= .8;
    y += 3.;
    two_digit_render(i.z, O, x, y, R);
    ++x; O += segment_value(x, y, 1, R);

    // Month (preceded by a hyphen)
    two_digit_render((i.y + 1), O, x, y, R); // Is it a bug in shadertoy that we have to add one?
    ++x; O += segment_value(x, y, 1, R);

    // Year
    two_digit_render(i.x % 100, O, x, y, R);
    two_digit_render(i.x / 100, O, x, y, R);

    glFragColor = O;
}

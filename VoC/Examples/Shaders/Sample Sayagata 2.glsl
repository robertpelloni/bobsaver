#version 420

// original https://www.shadertoy.com/view/3dtBz4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Sayagata Pattern by EisernSchild
//
//
// based on following Shaders :
// Sayagata by coposuke                 : https://www.shadertoy.com/view/wl3XRH
// Asanoha by Catzpaw                   : https://www.shadertoy.com/view/tsVyDt
// Simple vignette effect by Ippokratis : https://www.shadertoy.com/view/lsKSWR

// params
const float step_x = 0.65;
const float step_a = 0.5;
const float step_b = 0.58;
const vec3 color1 = vec3(0.5, 0.2, 0.3);
const vec3 color2 = vec3(0.4, 0.2, 0.2);
const vec3 color3 = vec3(1.0, 0.6, 0.7);

// original pattern from https://www.shadertoy.com/view/wl3XRH
const int pattern[100] = int[](
    1,0,0,0,0,0,0,0,0,0,
    1,0,1,1,1,1,1,1,1,0,
    1,0,0,1,0,1,0,1,0,0,
    1,0,1,0,0,1,0,0,1,0,
    1,1,1,1,0,1,0,1,1,1,
    0,0,0,0,0,1,0,0,0,0,
    1,1,1,1,0,1,0,1,1,1,
    1,0,1,0,0,1,0,0,1,0,
    1,0,0,1,0,1,0,1,0,0,
    1,0,1,1,1,1,1,1,1,0
);

// outline pattern
// 0 - empty
// 1 - cross
// 2 - vertical
// 3 - horizontal
// 4 - top left
// 5 - top right
// 6 - bottom left
// 7 - bottom right
const int pattern_outline[100] = int[](
    2,5,3,3,3,3,3,3,4,2,
    2,7,4,5,4,5,4,5,6,2,
    2,5,1,6,2,2,7,1,4,2,
    7,6,7,4,2,2,5,6,7,6,
    3,3,3,6,2,2,7,3,3,3,
    3,3,3,4,2,2,5,3,3,3,
    5,4,5,6,2,2,7,4,5,4,
    2,7,1,4,2,2,5,1,6,2,
    2,5,6,7,6,7,6,7,4,2,
    2,7,3,3,3,3,3,3,6,2
);

// 0/1 pattern
int pat(vec2 uv)
{
    int ix = int(mod(floor(mod(uv.x, 10.)) + floor(mod(uv.y, 10.)) * 10.0,100.));
    return pattern[ix];
}
// outline pattern
int pat_o(vec2 uv)
{
    int ix = int(mod(floor(mod(uv.x, 10.)) + floor(mod(uv.y, 10.)) * 10.0,100.));
    return pattern_outline[ix];
}

void main(void)
{
    // aspect / scale / rotate
    vec2 uv = (gl_FragCoord.xy-.5)/resolution.y;
    float scale = 30. + 10. * sin(time);
    uv *= scale;
    float rot = sin(time*.02)*13.;
    uv=uv*mat2(cos(rot), sin(rot), sin(rot), -cos(rot));
        
    // set additional uv for vignette later
    vec2 uv1 = gl_FragCoord.xy / resolution.xy;
    uv1 *= (1.0 - uv1.yx);
    
    // adjust smoothstep by distance
    float step_bb = step_b + (scale *.005);
    
    // get contour shape
    int ix = pat_o(uv);
    float al = 0.;
    if (ix == 0)
    {
        // empty
    }
    else if (ix == 1)
    {
        // 1 - cross
        al = max(smoothstep(step_a, step_bb, step_x-abs(fract(uv.x)-.5)),
            smoothstep(step_a, step_bb, step_x-abs(fract(uv.y)-.5)));
    }
    else if (ix == 2)
    {
        // 2 - vertical
        al = smoothstep(step_a, step_bb, step_x-abs(fract(uv.x)-.5));
    }
    else if (ix == 3)
    {
        // 3 - horizontal
        al = smoothstep(step_a, step_bb, step_x-abs(fract(uv.y)-.5));
    }
    else if (ix == 4)
    {
        // 4 - top left
        float x = step_x-abs(fract(uv.x)-.5);
        if (fract(uv.y)  < 0.5) x -= -(fract(uv.y)-.5);
        float y = step_x-abs(fract(uv.y)-.5);
        if (fract(uv.x)  > 0.5) y -= (fract(uv.x)-.5);
        al = max(smoothstep(step_a, step_bb, x),
            smoothstep(step_a, step_bb, y));
    }
    else if (ix == 5)
    {
        // 6 - top right
        float x = step_x-abs(fract(uv.x)-.5);
        if (fract(uv.y)  < 0.5) x -= -(fract(uv.y)-.5);
        float y = step_x-abs(fract(uv.y)-.5);
        if (fract(uv.x)  < 0.5) y -= -(fract(uv.x)-.5);
        al = max(smoothstep(step_a, step_bb, x),
            smoothstep(step_a, step_bb, y));
    }
    else if (ix == 6)
    {
        // 6 - bottom left
        float x = step_x-abs(fract(uv.x)-.5);
        if (fract(uv.y)  > 0.5) x -= (fract(uv.y)-.5);
        float y = step_x-abs(fract(uv.y)-.5);
        if (fract(uv.x)  > 0.5) y -= (fract(uv.x)-.5);
        al = max(smoothstep(step_a, step_bb, x),
            smoothstep(step_a, step_bb, y));
    }
    else if (ix == 7)
    {
        // 7 - bottom right
        float x = step_x-abs(fract(uv.x)-.5);
        if (fract(uv.y)  > 0.5) x -= (fract(uv.y)-.5);
        float y = step_x-abs(fract(uv.y)-.5);
        if (fract(uv.x)  < 0.5) y -= -(fract(uv.x)-.5);
           al = max(smoothstep(step_a, step_bb, x),
            smoothstep(step_a, step_bb, y));
    }
 
    // background coloring
    float al1 = float(pat(uv+vec2(.5)));
    vec3 col = mix(color1, color2, al1);
    // outline color
    col = mix(col, color3, sqrt(al));
        
    // set color + vignette
    glFragColor = vec4(col,1.0);
    float vig = uv1.x*uv1.y * 15.0;
    glFragColor.xyz*=pow(vig, 0.25);
}

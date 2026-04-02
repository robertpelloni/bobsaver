#version 420

// original https://www.shadertoy.com/view/3d2yWh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Author: https://www.shadertoy.com/user/andretugan
// Creative Commons Attribution-NonCommercial 3.0 Unported License
// https://creativecommons.org/licenses/by-nc/3.0

#define NUM_CHORDS 32

#define M_PI 3.14159265358
#define M_2_PI (2. * 3.14159265358)

#define FADE_INNER_RADIUS 0.8
#define FADE_OUTER_RADIUS 1.1
#define LINE_WIDTH 4.

// Function from Inigo Quilez
// https://www.shadertoy.com/view/MsS3Wc
vec3 hsv2rgb( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );

    rgb = rgb*rgb*(3.0-2.0*rgb); // cubic smoothing    

    return c.z * mix( vec3(1.0), rgb, c.y);
}

float DrawLine(vec2 uv, vec2 origin, vec2 dir_not_normed) {
    float proj = dot(uv - origin, dir_not_normed) / dot(dir_not_normed, dir_not_normed);
    vec2 perp = origin + proj * dir_not_normed - uv;
    float dist2 = dot(perp, perp);
    
    float line_width = LINE_WIDTH / resolution.y;        
                                
    float val = smoothstep(line_width * line_width, line_width * line_width * 0.5, dist2);        
    val *= smoothstep(FADE_OUTER_RADIUS * FADE_OUTER_RADIUS, FADE_INNER_RADIUS * FADE_INNER_RADIUS, dot(uv, uv));        
    return val;
}

void main(void)
{           
    vec2 uv = (2.*gl_FragCoord.xy - resolution.xy)/resolution.y;
    float uv2 = dot(uv, uv);
    if (dot(uv, uv) > FADE_OUTER_RADIUS * FADE_OUTER_RADIUS) { 
        glFragColor = vec4(0.0,0.0,0.0,1.0);
        return;
    }
               
    float focus_radius = 0.4 + 0.4 * sin(time * 0.23) * cos(time * 0.17);
    float focus_angle = M_PI + M_PI * sin(time * 0.29) * cos(time * 0.19);
    vec2 focus = vec2(focus_radius * cos(focus_angle), focus_radius * sin(focus_angle));
    
          
    float val = 0.;

    for (int i = 0; i < NUM_CHORDS; ++i) {
        float angle = M_2_PI / float(NUM_CHORDS) * float(i);
        
        vec2 point = vec2(cos(angle), sin(angle));                                   
        vec2 diff = point - focus;
        vec2 perp = vec2(diff.y, -diff.x);
        
        vec2 mid = 0.5 * (point + focus);
       
        val += DrawLine(uv, point, diff);
        val += DrawLine(uv, mid, perp);        
    }
    
    val *= 10. / float(NUM_CHORDS);
    val = pow(val, 0.5);
    
    float hue = sin(time * 0.02 + uv2 * 0.3);             
    glFragColor = vec4(hsv2rgb(vec3(hue, 1. - 0.8 * uv2, val)),1.0);
}

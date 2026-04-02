#version 420

// original https://www.shadertoy.com/view/fstfWH

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* Draw an arbitrary line given a start and end vector
    uv = uv coord - 0 to 1
    start = the starting vector in UV space
    end = the ending vector in UV space
    thickness = the thickness of the line
*/
vec3 line(vec2 uv, vec2 start, vec2 end, float thickness) {
    vec2 v = end - start + vec2(0., 0.000001);
    float len = length(v);
    
    float angle = -sign(v.y) * acos( dot( vec2(1., 0.), normalize(v) ) );
    mat2 r = mat2( cos(angle), -sin(angle), sin(angle), cos(angle) );
    
    vec2 rUv = (uv - start) * r + start;
    
    vec2 l = step(start, rUv) * 1. - step(start + vec2(len, thickness), rUv);
    
    return vec3(l.x * l.y);
}

/* Equals operator (int) */
int eqi(int a, int b) {
    return a == b ? 1 : 0;
}

/* Not equals operator (int) */
int neqi(int a, int b) {
    return a != b ? 1 : 0;
}

/* Draw a digit 
    uv = uv coord - 0 to 1
    n = the digit to render
    trs = Translation, rotation and scale
*/
vec3 digit(vec2 uv, int n) {
    const float opacity = 0.1;
    
    vec3 seg1 = max(float(eqi(n,0) | eqi(n,2) | eqi(n,6) | eqi(n,8)), opacity) * 
        line(uv, vec2(.03, .05), vec2(.03, .23), .03);
        
    vec3 seg2 = max(float(eqi(n,0) | eqi(n,4) | eqi(n,5) | eqi(n,6) | eqi(n,8) | eqi(n,9)), opacity) * 
        line(uv, vec2(.03, .28), vec2(.03, .48), .03);
        
    vec3 seg3 = max(float(neqi(n,1) & neqi(n,4)), opacity) * 
        line(uv, vec2(.03, .48), vec2(.13, .48), .05);
        
    vec3 seg4 = max(float(neqi(n,5) & neqi(n,6)), opacity) * 
        line(uv, vec2(.13, .48), vec2(.13, .28), .03);
    
    vec3 seg5 = max(float(neqi(n,0) & neqi(n,1) & neqi(n,7)), opacity) * 
        line(uv, vec2(.03, .23), vec2(.13, .23), .05);
        
    vec3 seg6 = max(float(neqi(n,2)), opacity) * 
        line(uv, vec2(.13, .23), vec2(.13, .05), .03);
    
    vec3 seg7 = max(float(neqi(n,1) & neqi(n,4) & neqi(n,7) & neqi(n,9)), opacity) * 
        line(uv, vec2(.03, .0), vec2(.13, .0), .05);
    
    return vec3(seg1 + seg2 + seg3 + seg4 + seg5 + seg6 + seg7);
}

vec3 dots(vec2 uv, vec2 pos) {
    //     |    make them flash   |   |         first dot                    |   |              second dot                             |
    return step(mod(time, 2.), 1.) * (line(uv, pos, pos + vec2(0., .06), .05) + line(uv, pos + vec2(0., .2), pos + vec2(0., .26), .05));
}

void main(void)
{
    float time = mod(date.w, 86400.);  // Resets the clock when above 23:59:59
    
    // Specify the rotation, scale and translation
    float rotation = 0.;
    float scale = .5;
    vec2 translation = vec2(.75, .35);
    
    // Convert these to a 3x3 matrix
    mat3 s = mat3(
        1./scale, 0., 0.,
        0., 1./scale, 0.,
        0., 0., 1./scale);
        
    mat3 t = mat3(
        1., 0., -translation.x,
        0., 1., -translation.y,
        0., 0., 1.);
        
    mat3 r = mat3(
        cos(rotation), -sin(rotation), 0.,
        sin(rotation), cos(rotation), 0.,
        0., 0., 1.);
        
    mat3 m = t * r * s;   // combined matrix
    
    vec2 uv = (vec3(gl_FragCoord.xy/resolution.xy, 1.) * m).xy;

    vec3 digit1 = digit(uv + vec2(1.2, 0.), int(mod(time / 36000., 3.)));  // hours (tens)
    vec3 digit2 = digit(uv + vec2(1., 0.), int(mod(time / 3600., 10.)));    // hours (units)
    vec3 dots1 = dots(uv, vec2(-.75, .12));
    vec3 digit3 = digit(uv + vec2(.7, 0.), int(mod(time / 600., 6.0)));    // minutes (tens)
    vec3 digit4 = digit(uv + vec2(.5, 0.), int(mod(time / 60., 10.0)));    // minutes (units)
    vec3 dots2 = dots(uv, vec2(-.25, .12));
    vec3 digit5 = digit(uv + vec2(.2, 0.), int(mod(time / 10., 6.0)));     // tens
    vec3 digit6 = digit(uv, int(mod(time, 10.0)) );                        // units

    // Output to screen
    glFragColor = vec4(digit1 + digit2 + dots1 + digit3 + digit4 + dots2 + digit5 + digit6, 1.0);
}

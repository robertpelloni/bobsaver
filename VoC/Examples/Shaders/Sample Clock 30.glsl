#version 420

// original https://www.shadertoy.com/view/sssyRB

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define S smoothstep

mat2 Rotate(float angle) {
    float s = sin(angle), c = cos(angle);
    return mat2(c, -s, s, c);

}

float line(vec2 uv, float len, float width) {
    
    float d = length(uv - vec2(0, clamp(uv.y, 0.0, len))) ;
    float w = mix(width, 0.001, S(0.0, 0.45, uv.y));
    d = S(0.005, 0.0, d-w);
    return d;
}

float divs(vec2 uv, float len) {

    float d = length(uv - vec2(0, clamp(uv.y, 0.45-len, 0.45))) ;
    d = S(0.005, 0.0, d);
    return  d;

}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy - 0.5*resolution.xy)/resolution.y;
    

    // Time varying pixel color
    
    float board = 0.;
    
    for (float i = 0.; i < 2.0*3.141927; i += 2.0*3.141927/60.) {
        board = max(board, divs(uv*Rotate(i), 0.03));        
    }
    
    for (float i = 0.; i < 2.0*3.141927; i += 2.0*3.141927/12.) {
        board = max(board, divs(uv*Rotate(i), 0.05));        
    }

    
    
    float s = floor(date.w)/60.*2.0*3.1415927;
    float arrowS = line(uv*Rotate(s), 0.45, 0.01);

    float m = date.w/3600.*2.0*3.1415927;
    float arrowM = line(uv*Rotate(m), 0.40, 0.02)*0.9;

    float h = date.w/3600./12.*2.0*3.1415927;
    float arrowH = line(uv*Rotate(h), 0.35, 0.03)*0.8;

    float arrow = max(arrowS, arrowM);
    arrow = max(arrow, arrowH);
    
    
    vec3 col = vec3(max(arrow,board));

    // Output to screen
    glFragColor = vec4(col, 1.0);
}

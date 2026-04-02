#version 420

// original https://www.shadertoy.com/view/WdBGzV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 r2(float angle) { return mat2(cos(angle), -sin(angle), sin(angle), cos(angle)); }
#define R resolution.xy
#define Iterations 10.
void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (2.*gl_FragCoord.xy-R)/resolution.y;
    vec3 col = vec3(0);
    float s = time/16. * cos(time/32.);

    // https://www.shadertoy.com/view/Mss3Wf
    for(float i=0.; i < Iterations; i++) {
        uv = abs(uv) - s; 
        uv.xy *= r2(time/16. + 2.);
        uv *= 1.08;
    }
    
    float dist = length(fract(2.*uv));
    vec3 rainbow = cos(vec3(0,2,4) + time + 2.*uv.xyx);
    col = dist*rainbow;
    
    float gridSize = 3.;
    float gridWidth = 0.04;
    vec2 grid = smoothstep(gridWidth, 0., abs(fract(gridSize*uv)-gridWidth));
    col = mix(col, vec3(1), clamp(grid.x + grid.y, 0., 1.)); 

    // Output to screen
    glFragColor = vec4(col,1.0);
}

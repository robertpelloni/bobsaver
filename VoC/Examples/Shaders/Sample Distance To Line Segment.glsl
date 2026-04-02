#version 420

// original https://www.shadertoy.com/view/llcfR7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    /*
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    // Time varying pixel color
    vec3 col = 0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4));

    // Output to screen
    glFragColor = vec4(col,1.0);
    */
    //vec2 p1 = vec2 (50, 50);
    /*vec2 p1 = mouse*resolution.xy.xy;
       vec2 p2 = vec2 (300, 80);*/
    vec2 p1 = vec2 (.5 + .3 * cos (time * .5), .5 + .3 * sin (time * .7)) * resolution.xy;
       vec2 p2 = vec2 (.5 + .2 * cos (time * 1.1), .5 + .2 * sin (time * .9)) * resolution.xy;
    
    vec4 colA = vec4(clamp (5.0 - length (gl_FragCoord.xy - p1), 0.0, 1.0));
    vec4 colB = vec4(clamp (5.0 - length (gl_FragCoord.xy - p2), 0.0, 1.0));
    
    vec2 a_p1 = gl_FragCoord.xy - p1;
    vec2 p2_p1 = p2 - p1;
    float h = clamp (dot (a_p1, p2_p1) / dot (p2_p1, p2_p1), 0.0, 1.0);
    float d = length (a_p1 - p2_p1 * h);
    
    vec4 colC = clamp (vec4(.5 - 5.0 * cos ((d - time * 10.0) * 3.1415926 / 20.0)), 0.0, 1.0) * vec4 (1.0, .73, .0, .0);
    vec4 colD = vec4(clamp (2.5 - d, 0.0, 1.0));
    
    glFragColor = max (max (colA, colB), max (colC, colD));
}

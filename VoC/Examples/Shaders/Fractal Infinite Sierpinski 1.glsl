#version 420

// original https://www.shadertoy.com/view/MdfGR8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    float direction = 0.5; // -1.0 to zoom out
    ivec2 sectors;
    vec2 coordOrig = gl_FragCoord.xy / resolution.xy - 0.5;
    coordOrig.y *= resolution.y / resolution.x;
    const int lim = 6;

    vec2 coordIter = coordOrig / exp(mod(direction*time, 1.1));
    
    for (int i=0; i < lim; i++) {
        sectors = ivec2(floor(coordIter.xy * 3.0));
        if (sectors.x == 1 && sectors.y == 1) {
            // make a hole
            glFragColor = vec4(0.0);

            return;
        } else {
            // map current sector to whole carpet
            coordIter.xy = coordIter.xy * 3.0 - vec2(sectors.xy);
        }
    }

    glFragColor = vec4(coordOrig.x + 0.5, 0.5, coordOrig.y + 0.5, 1.0) + 0.05*(1.1 - mod(direction*time, 1.1));
}

#version 420

// original https://www.shadertoy.com/view/Wdt3Rn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float random (in vec2 _st) {
    return fract(sin(dot(_st.xy,
                         vec2(12.246334,78.34534)))*
        4346.23643);
}

void main(void)
{
    float gridSize = 100.;
    vec2 st = gl_FragCoord.xy/ gridSize;
    
    float diag = mod(floor(st).x + floor(st).y, 2.);

    st.x += time * (random(floor(st) )- 0.75) * 0.5;
    st.y += 1.2 + random(floor(st) );

    vec2 ipos = floor(st);  // get the integer coords
    
    st = fract(st);

    // Assign a random value based on the integer coord
    vec3 color = vec3(mix(random(ipos), random(ipos + 1.0), smoothstep(0.,1.,st.y)));

    glFragColor = vec4(mix(vec3(0.0, 0.1255, 0.1098),vec3(0.9529, 0.8667, 0.8392),color),1.0);
}

#version 420

// original https://www.shadertoy.com/view/4lycDc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = 140. * (gl_FragCoord.xy-resolution.xy/2.)/(resolution.y);

    float minkowskiDistanceOrder = pow(2., 4.); 
       vec2 p = pow(abs(uv), vec2(minkowskiDistanceOrder));
    float d = pow(p.x + p.y, 2. / minkowskiDistanceOrder);
    
    float color = sin(d - time);
    
    // Output to screen
    glFragColor = vec4(color, color, color, 1.0);
}

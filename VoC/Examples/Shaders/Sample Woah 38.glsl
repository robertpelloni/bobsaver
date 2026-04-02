#version 420

// original https://www.shadertoy.com/view/mdByzd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void) {
    vec2 u = gl_FragCoord.xy;
    vec2  R = resolution.xy, 
          p = (u+u - R) / R.y;
        
    glFragColor = vec4(
            sin(
                1e2 
                * length(
                    length(p)
                    * cos(
                        mod(
                            atan(p.x, p.y) 
                            + cos(time * 2.), 
                            1.256
                        )
                        - .6
                        + vec2(0, 11)
                    ) - vec2(1.73, 0))));
}
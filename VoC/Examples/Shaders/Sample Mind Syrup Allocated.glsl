#version 420

// original https://www.shadertoy.com/view/XdKfzW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    float mx = resolution.x / resolution.y;
    vec2 uv = gl_FragCoord.xy/resolution.xy;

      
    vec2 st = uv;
    st *= 2.0;
    st -= 1.0;
    st.x *= mx;
    
    uv *= 30.0;
    uv = fract(uv);
    uv *= 2.0;
    uv -= 1.0;
    uv.x *= mx;
       
    vec3 c;
    float t = time;
    for (int i = 0; i < 3; i++) {
        t -= 10.0 * sin(10. * float(i) + time * sin(time));
        float col = (0.6 + .5 * sin(10. * atan(st.y, st.x) + t + length(st * 5.))
                    
                    *
                     sin(-t + -10. * atan(st.y, st.x) + t + length(st * 5.))
                    ) / length(uv);
        c[i] = 0.1 / col;
    }    
     
    
    
    vec3 color = vec3(c);
    
    // Output to screen
    glFragColor = vec4(color,1.0);
}

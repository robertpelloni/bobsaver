#version 420

// original https://www.shadertoy.com/view/4lGXzG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    float time = time * 1.;                                    // adjust time
    vec2 p = (-resolution.xy + 2.0*gl_FragCoord.xy)/resolution.x;        // center coordinates
        
    ////////////////////////////////////
    // deform technique from iq: https://www.shadertoy.com/view/Xdf3Rn
    float r2 = dot(p,p);
    float r = sqrt(r2);
    vec2 uv = p/r2;    
    // animate    
    uv += 10.0 * cos( vec2(0.6,0.3) + vec2(0.1,0.13) * 2. * sin(time) );
    // uv = p; // switch back to normal coords to test drawing
    ////////////////////////////////////
    
    // custom drawing
    uv += vec2(0., 2. * cos(uv.y * 8.));                                    // warp coordinates a little more
    uv = abs(sin(uv * 0.3));                                                // draw horizontal stripes
    float color = smoothstep(0.2, 0.8, abs(sin(time + uv.y * 3.)));
    color = min(color, smoothstep(0.1, 0.95, abs(sin(time + uv.y * 4.))) );
    color += 0.75;                                                            // brighten everything
    vec3 col = vec3(                                                        // oscillate color components
        0.6 + 0.1 * cos(time + color * 1.), 
        0.5 * color, 
        0.9 + 0.2 * sin(time + color * 1.1)
    );
    // reverse vignette
    col *= r*1.5 * color;
    col += pow(length(p)/2., 2.);
    glFragColor = vec4( col, 1.0 );
}

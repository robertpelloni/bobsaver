#version 420

// original https://www.shadertoy.com/view/mljGRy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalize with a single constant instead of two to ensure
    // the squares are square in all resolutions
    vec2 uv = gl_FragCoord.xy/resolution.y;
    // The recorded center is then offset on the x axis by 
    // the ratio of the constant w/ the true x-resolution
    vec2 center = vec2(resolution.x/resolution.y * 0.5, 0.5);
    
    
    mat2 rotation = mat2(cos(time) ,-sin(time),sin(time),cos(time));
    //rotation = mat2(cos(time * 0.7853+ vec4(0,33,11,0)));
    mat2 inverted = mat2(cos(-time) ,-sin(-time),sin(-time),cos(-time));
    
    uv= fract((uv - (center) ) * 3.0 * rotation);
    uv = (uv - 0.5) * inverted ;
    
    // Time varying pixel color
    vec3 hue = vec3(0.2,1.2,2.);
    hue = cos(hue + uv.y * 5.0 - 1.0);
    
    //hue = vec3(uv.y + 0.2);

    // Output to screen
    glFragColor = vec4(hue,1.0);
}

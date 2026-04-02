#version 420

// original https://www.shadertoy.com/view/wd3cWl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 blobLayer(vec2 uv, vec2 timeOffset)
{
    vec3 col = vec3(0.);
    uv += time * timeOffset;
    
    float r = (sin(uv.x)/(2. + abs(4.*sin(time))) + cos(uv.y)/(2. + abs(4.*cos(time))));
    float g = (sin(uv.x)/(2. + abs(2.2*sin(time))) + cos(uv.y)/(2.523 + abs(4.*cos(time))));
    float b = (sin(uv.x)/(2. + abs(3.14*cos(time))) + cos(uv.y)/(2. + abs(4.*cos(time))));
    
    col += abs (vec3(r,g,b) / 3.);
    
    return col;   
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-0.*resolution.xy)/resolution.y;

    float size = 20.;
    
    uv *= size;
    
    
    vec2 gv = fract(uv * size);
    vec2 id = floor(uv * size) / size;
    
    vec3 col = vec3(0.);
    col += blobLayer(uv, vec2(-0.2, 0.3));
    col += blobLayer(uv, vec2(1));
    col += blobLayer(uv, vec2(1.4, -2.321));
    
    col.z = (col.z + 0.5) / 2.;
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}

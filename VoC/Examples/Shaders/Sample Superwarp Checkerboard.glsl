#version 420

// original https://www.shadertoy.com/view/3llXRr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    const float PI = 3.14159265;
    
    // teh number of centers
    const float numcenters = 6.0;
    
    const float incr = PI*2.0/numcenters;
    const float maxx = PI*2.0-0.01;
    
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy/resolution.xy);
    
    float x = gl_FragCoord.x;
    float y = gl_FragCoord.y;
    
    float cx = resolution.x/2.0;
    float cy = resolution.y/2.0;
    
    float w = resolution.x;
    float h = resolution.y;
    
    // Time varying pixel color
    vec3 col = vec3(0.0, 0.0, 0.0);
    float a = 0.0;
    float b = 0.0;
    for (float d=0.0; d<=maxx; d+=incr) {
        float _r = distance(mouse*resolution.xy.xy, vec2(cx, cy))/resolution.x;
        float _t = atan(mouse.y*resolution.xy.y-cy, mouse.x*resolution.xy.x-cx);
        float r = resolution.x*20.0*25.0*sin(_t-PI/3.0)*sin(_t-PI/3.0)/distance(
            gl_FragCoord.xy,
            vec2(cx+cos(d-_t)*w*_r, cy-sin(d-_t)*w*_r)
           )+time*26.0;
        b += r;
        r = floor(r/255.0*2.0)*255.0/2.0;
        a += r;
    }
    // c = floor(c/255*2)*255/2;
    b *= 2.0/numcenters;
    a = mod(a, 255.0);
    b = mod(b, 255.0);
    a *= 2.0;
    
    // black/blue/cyan/white gradient pattern
    col = vec3(min(a, b)/255.0, a/255.0, max(a, b)/255.0);
    
    // classic black/white crisp checkerboard pattern
    // col = vec3(a/255.0, a/255.0, a/255.0);
    
    // Output to screen
    glFragColor = vec4(col,1.0);
    

}


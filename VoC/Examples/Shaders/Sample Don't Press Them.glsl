#version 420

// original https://www.shadertoy.com/view/stBcDW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Draw a circle
float circle(in vec2 uv, in vec2 c, float r)
{
    return step(distance(uv, c), r);
}

//Modified box to make cylinder easier
// x is goes left + right of center
// y is goes bottom of center
float box (in vec2 uv, in vec2 c, float x, float y)
{
    return (step(uv.x, c.x - x) - step(uv.x, c.x + x)) * (step(uv.y, c.y) - step(uv.y, c.y + y));
}

//Cylinder drawing, just a base circle + rectangle and circle to act as the top
float cylinder( in vec2 uv, in vec2 c, float r, float h)
{
    float top = circle(uv, c + vec2(0,h), r);
    float rim = .65 * max(circle(uv, c, r), box(uv, c, r, h));
    
    return max(top, rim);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
    float size = sin(time * .02) + 6.;
    vec2 displace = vec2(time, sin(time*.1)*5.);
    
    uv = uv * size + displace;
    
    vec2 big = fract(uv);
    vec2 i = floor(uv);

    // Time varying pixel color
    float pct = cylinder(big, vec2(.5, .04*sin(time+i.x*3.+i.y*9.)+.4), .3, .2*abs(sin(time*5.+i.x*18.+i.y*13.)));
    vec3 col = vec3(pct) * vec3(1, 0.3,0.3);

    // Output to screen
    glFragColor = vec4(col,1);
}

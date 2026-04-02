#version 420

// original https://www.shadertoy.com/view/ttyXRd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 rotate(vec2 xy, float theta)
{
    return vec2(xy.x*cos(theta) - xy.y*sin(theta),
               xy.x*sin(theta) + xy.y*cos(theta));
}

//  1 out, 1 in...
float hash11(float p)
{
    p = fract(p * .1031);
    p += cos(time*0.001);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

void main(void)
{
    // where 0.0 is the center
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;

    uv *= 10.0;
    //uv.y *= 0.55;
    
    float floored = floor(length(uv));
    
    uv = rotate(uv, time*floored*0.3);
    
    
    
    // Time varying pixel color
    
    float value = -1.0 + 2.0*mod(floor(uv.x) + floor(uv.y), 2.0);
    //vec3 col = 0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4));

    
    vec3 col = vec3(value);
    
    col.r *= hash11(floored)*0.4 + 0.3;
    col.g *= hash11(floored + 7.39)*0.8 + 0.4;
    col.b *= hash11(floored + 9.12)*0.3 + 0.6;
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}

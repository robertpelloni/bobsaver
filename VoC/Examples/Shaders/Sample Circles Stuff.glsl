#version 420

// original https://www.shadertoy.com/view/NsBcDd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 Hash12(float t)
{
    float x = fract(sin(t * 674.3) * 453.2);float y = fract(sin(t * 2674.3) * 453.2);
    return vec2(x,y);
}

vec2 rotate(vec2 pos, float angle)
{
    float c = cos(angle);
    float s = sin(angle);
    
    return mat2(c,s,-s,c) * pos;

}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy-.5 * resolution.xy)/resolution.y;
   
    uv *= 1.522222f;
   
    uv.x = abs(uv.x) - .5;
    uv.x -= .15;
    
    uv = rotate(uv, time + uv.x * sin(time + uv.y));
    
    
    
    // Time varying pixel color
    vec3 col = vec3(0.0);
    
    for(float i = 0.; i < 125.0; i++)
    {
        
        vec2 dir= Hash12(i) - .5;
        float t = dir.x +(abs(sin(time * .125)) + dir.x) * 1.5;
        float d = length(uv+dir*(2.5 *sin(dir.x * cos(dir.y)))*t);
        d -= length(uv-dir*t *  cos(time)) *  3.1566;
        d  = abs(d * .17);
        float brightness = 0.0005 * (abs(sin(uv.x)) + .5);
        
        col+= vec3(brightness / d) * vec3(abs(sin(i)) * .55, abs(sin(i * i)), abs(cos(i)));
        
    
    }
    col.r += Hash12(uv.x * abs(sin(uv.y))).x * .05;
  //  col = vec3(Hash12(12.).x);
    // Output to screen
    glFragColor = vec4(col,1.0);
}

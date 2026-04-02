#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rotate(float a)
{
    float c = cos(a);
    float s = sin(a);
    return mat2(c, s, -s, c);
}

float hash(vec2 p)
{
    return fract(4346.45 * sin(dot(p, vec2(45.45, 757.5))));
}

void main()
{
    vec2 uv = (2. * gl_FragCoord.xy - resolution) / resolution.y;
    
    vec2 uv2 = uv;
    uv2 *= rotate(-time*0.5+sin(uv.y));
    float v = 1.0-abs(uv2.x-uv2.y);
    
    
    vec3 col = vec3(1.0);
    
    uv *= 9. + sin(time*0.7)*4.0;
    
    uv *= rotate(time*0.1);
    uv += time*4.0;
    
    vec2 i = floor(uv);
    vec2 f = fract(uv) - .5;
    
    
    f *= rotate(floor(hash(i) * 18.) * 3.14 / 2.);
    
    
    float d = dot(f, vec2(1.0));
    col += smoothstep(.015, .0, d);
    
    col.b *= hash(i);
    col.g *= hash(i*2.0);
    col.r *= hash(i*4.0);
    
    
    col*=v;
    
    glFragColor = vec4(col, 1.);
}

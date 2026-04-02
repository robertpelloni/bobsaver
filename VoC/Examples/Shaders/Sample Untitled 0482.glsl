#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float df(vec2 p, vec2 dir)
{
    float a = atan(dir.x, dir.y);
    p *= mat2(cos(a), -sin(a), sin(a), cos(a));
    p *= 4.; p.y *= -0.5;
    float r = dot(p,p) * 0.02 * cos(time * 40.);
    p *= mat2(cos(r), -sin(r), sin(r), cos(r));
    return max(abs(p.x)+p.y, abs(p.y*p.x)) + length(p)*0.3;
}

vec2 move(vec2 g, vec2 p, float t)
{
    return sin( t * 2. + 9. * fract(sin((floor(g)+p)*mat2(2,7,2,5)*mat2(7,-2,2,5))));
}

void main()
{
    vec2 g = gl_FragCoord.xy;
    float d = 1.;
    vec2 p = g /= resolution.y / 8., ac,al; 
           
    for(int x=-1;x<=1;x++)
    for(int y=-1;y<=1;y++)
        p = vec2(x,y),
        al = move(g,p, time-0.1),
        ac = move(g,p, time),
        p += .5 + .5 * ac - fract(g),
        d = min(d, df(p,ac-al));
    
        
        d = 1.0-d;
    glFragColor = vec4(d*1.1,d*0.8,d*0.5,1.0);
    glFragColor.a = 1.;

}

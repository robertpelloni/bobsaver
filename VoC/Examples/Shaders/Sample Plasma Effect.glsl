#version 420

// original https://www.shadertoy.com/view/4tdGWX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    float time = time;
    vec2 a = vec2(resolution.x /resolution.y, 1);
    vec2 c = gl_FragCoord.xy / resolution.xy * a * 4. + time * .3;

    float k = .1 + cos(c.y + sin(.148 - time)) + 2.4 * time;
    float w = .9 + sin(c.x + cos(.628 + time)) - 0.7 * time;
    float d = length(c);
    float s = 7. * cos(d+w) * sin(k+w);
    
    glFragColor = vec4(.5 + .5 * cos(s + vec3(.2, .5, .9)), 1);
    //shiny effect    
glFragColor *= vec4(1, .7, .4, 1)*pow(max(normalize(vec3(length(dFdx(glFragColor)), length(dFdy(glFragColor)), .5/resolution.y)).z, 0.), 2.) + .75;        
}

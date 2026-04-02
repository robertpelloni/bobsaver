#version 420

// original https://www.shadertoy.com/view/XtByRt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
    --------------------------------
    After Effects / Displacement Map
    --------------------------------

    Mimic the After Effects "Displacement Map" effect, where a input texture is used to displace another one.
    Note :
        - Input textures are not linerarized !
        - The natural behaviour of an UV Offest mimic the "wrap pixels" option in After Effects

    - Mid-gray: has no effect.
    - Darker values: push pixel in one direction
    - Brighter values: push pixel in the other direction

    ==> Change the "DispStrenght" to a lower value to reduce the effect

    Francois 'CoyHot' Grassard - 2017
*/

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv -= 0.5;
    uv /= vec2(resolution.y / resolution.x, 1);
    
    uv.y /= sin(((uv.x+time)*10.0)*0.5);

    vec4 p1 = vec4(0.0);
 
    p1.x = ((cos((uv.x+time/10.)*50.)/(uv.y*sin(time))/25.)*(sin((uv.x+time/10.)*50.)/uv.y*cos(time*7.)/25.));
    p1.y = ((cos((uv.x+time/9.)*50.)/(uv.y*sin(time))/20.)*(sin((uv.x+time/11.)*50.)/uv.y*cos(time*6.)/25.));
    p1.z = ((cos((uv.x+time/8.)*50.)/(uv.y*sin(time))/15.)*(sin((uv.x+time/12.)*50.)/uv.y*cos(time*5.)/25.));
    
    glFragColor = p1;
}

#version 420

// original https://www.shadertoy.com/view/Wl3SDf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    uv += vec2(0.,1.);
    uv *= .5;
    float t = time/3.;
    
    float gradient = uv.y+.025;
    
    vec3 orange = pow(vec3(.64448,.392529,.14877),vec3(.1/gradient));
    vec3 blue = pow(vec3(.14902,.4,.643137),vec3(5.*gradient));
    vec3 ozone = mix(vec3(1.),vec3(.206081,.115623,.522522),gradient);
    
    uv += .5*vec2(cos(t),sin(t)+1.1);
    float light = 5.*pow(2.71828,-5.*length(uv));

    vec3 col = orange*blue*ozone*light;

    glFragColor = vec4(pow(col,vec3(.4545)),1.0);
}

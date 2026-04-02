// original https://www.shadertoy.com/view/3lySW3

#version 420

// https://twitter.com/AndrewM_Webb/status/1236274167437197320

// original shader by https://www.reddit.com/user/slackermanz
// see here for more information https://softologyblog.wordpress.com/2018/03/31/more-explorations-with-multiple-neighborhood-cellular-automata/

uniform float time;
uniform vec2 resolution;
uniform vec2 mouse;
uniform int frames;
uniform sampler2D backbuffer;

out vec4 glFragColor;

// https://stackoverflow.com/a/4275343
float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void main(void)
{
    if (frames < 10) {
        float r = floor(3. * rand(gl_FragCoord.xy));
        glFragColor = vec4(float(r == 0.), float(r == 1.), float(r == 2.), 0.);
        return;
    }
        
    vec4 old = texelFetch(backbuffer, ivec2(gl_FragCoord.xy), 0);
    
    vec4 neighbours = vec4(0);
    neighbours += texelFetch(backbuffer, ivec2(gl_FragCoord.xy) + ivec2(-1, -1), 0);
    neighbours += texelFetch(backbuffer, ivec2(gl_FragCoord.xy) + ivec2(-1,  0), 0);
    neighbours += texelFetch(backbuffer, ivec2(gl_FragCoord.xy) + ivec2(-1,  1), 0);
    neighbours += texelFetch(backbuffer, ivec2(gl_FragCoord.xy) + ivec2( 0, -1), 0);
    //neighbours += texelFetch(backbuffer, ivec2(gl_FragCoord.xy) + ivec2( 0,  0), 0);
    neighbours += texelFetch(backbuffer, ivec2(gl_FragCoord.xy) + ivec2( 0,  1), 0);
    neighbours += texelFetch(backbuffer, ivec2(gl_FragCoord.xy) + ivec2( 1, -1), 0);
    neighbours += texelFetch(backbuffer, ivec2(gl_FragCoord.xy) + ivec2( 1,  0), 0);
    neighbours += texelFetch(backbuffer, ivec2(gl_FragCoord.xy) + ivec2( 1,  1), 0);

    
    vec4 new = old;
    
    if (old.r == 1.) {
        if (neighbours.b >= 3.)
            new = vec4(0, 0, 1, 0);
    } else if (old.g == 1.) {
        if (neighbours.r >= 3.)
            new = vec4(1, 0, 0, 0);
    } else if (old.b == 1.) {
        if (neighbours.g >= 3.)
            new = vec4(0, 1, 0, 0);
    }

    glFragColor = vec4(new.rgb, 1.);
}

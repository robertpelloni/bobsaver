#version 420

// original https://www.shadertoy.com/view/XlVcW1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define RAD .1
#define e ( 3. / resolution.y )
#define tt .0666666667

float makeCircle(in vec2 uv, in vec2 c, in float r){
    return smoothstep(e, 0., abs( distance(uv, c) - r ) );
}

float row(in vec2 uv){
    float color = 0.,
    s = sign(mod(floor((uv.y * .5 + .5)/RAD), 2.) - .5),
    rad = RAD/2. + RAD/2. * sin(uv.x * 4. - time * 1.5) * .75 * s;
    for(float i=-1.; i<5.; i++)
        color += makeCircle(mod(uv, RAD * 2.), vec2(i * tt, RAD), rad);
    return color;
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy * 2. - resolution.xy)/resolution.y + vec2(time * .05, 0.);
    glFragColor = vec4(row(uv) * step(abs(uv.y), .6));
}

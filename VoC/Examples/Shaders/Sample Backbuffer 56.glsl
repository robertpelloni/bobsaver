#version 420

//original https://www.reddit.com/r/generative/comments/c8ls0d/experiments_with_feedback_loops/

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

const float PI = 3.14;

void main(void) {
    vec2 I = gl_FragCoord.xy;
    vec4 O = vec4(0.0);//glFragColor;
    
    vec2 pixel = vec2(I.xy - 0.5 * resolution.xy) / resolution.y;
    vec2 uv = I / resolution.xy;
    vec3 mixedColor = texture(backbuffer, I / resolution.xy - pixel * (0.03 + sin(time))
                             * resolution.y / resolution.xy
                             ).rgb;
    vec2 offset = uv + vec2((mixedColor.g - .2) * 0.01, (mixedColor.r - .2) * 0.01);

    mixedColor = texture(backbuffer, offset).rgb;
    mixedColor *= .995;

    vec4 spectrum = abs( abs( .95*atan(uv.x, uv.y) -vec4(0,2,4,0) ) -3. )-1.;   
    float angle = atan(pixel.x, pixel.y);
    float dist = length(pixel) * 2. + sin(time) * .2;
    float edge = (dist + sin(angle * 3. + time * 10.) * sin(time * 3.) * 0.1) * 2.;
    vec4 rainbow = abs( abs( .95*mod(time * 2., 2. * PI) -vec4(0,2,4,0) ) -3. )-1.;
    float factor = smoothstep(1., .9, edge) * pow(edge, 30.);
    vec3 color = rainbow.rgb * factor;
    O = vec4(clamp(mixedColor + color, 0., 1.), 1.0);
    glFragColor = O;
}

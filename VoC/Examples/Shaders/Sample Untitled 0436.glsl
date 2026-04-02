#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float rphase(float phase, int i) {
    return .05 + 5.0 * fract(float(i) * phase * 325.5234 + .1235);
}
    

void main( void ) {

    vec2 position = (gl_FragCoord.xy / resolution.y);
    
    float x = position.x;
    float y = position.y;
    float f = 0.0;
    float freq = 1.0;
    float phase = 1.2;
    for (int i = 0; i < 9; i++) {
        f += sin(x * y * freq + phase);
        phase = rphase(phase, i);
        freq *= 1.05 + fract(phase) * .1;
        f += sin(x * freq + time * .1 + phase);
        phase = rphase(phase, i);
        freq *= 1.05 + fract(phase) * .1;
        f += sin((x + y + time * .1) * freq + phase);
        phase = rphase(phase, i);
        freq *= 1.05 + fract(phase) * .1;
        f += sin(y * freq + phase - time * .1);
        phase = rphase(phase, i);
        freq *= 1.05 + fract(phase) * .1;
    }

    glFragColor = vec4(sin(f + time * 1.1 + .3), sin(f + time + 1.5), sin(f + time * 1.2), 1.0);

}

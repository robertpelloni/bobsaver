#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main( void ) {

    vec2 position = ( gl_FragCoord.xy / resolution.xy ) - vec2(0.5, 0.5);
    glFragColor = vec4(position, 1, 2);
    float t = 3e1 + sin(time)*10.; // reminds me of Starry Night
    for( int i = 0; i < 7; i++) {
        glFragColor += vec4(sin(glFragColor.y*t/ 50.0), sin(glFragColor.x*11.3+cos(time)), 0., 1.0);
    }
    glFragColor = length(glFragColor)*0.01+0.1*glFragColor;
}

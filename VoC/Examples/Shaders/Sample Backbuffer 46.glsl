#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

float rand(vec2 co){ // Thanks StackOverflow!
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float reRand(float t){
    return rand(vec2(sin(floor(t)), sin(floor(t) * 7.38905609)));
}

void main( void ) {

    vec2 position = ( gl_FragCoord.xy / resolution.xy );
    
    float angle = 7. * mix(reRand(time), reRand(time + 1.), fract(time));
    position += normalize(vec2(cos(angle), sin(angle))) * 0.01;
    position = fract(position);
    
    glFragColor = vec4(fract(texture2D(backbuffer, position).rgb + vec3(.01501, .025009, .035013)), 1.);
    
    if (length(position - .5) < pow(.1, 1.5 + .1 * sin(5. * time)) * (.75 + .25 * sin(30. * time + 3. * atan(position.y - .5, position.x - .5))))
        glFragColor = vec4(1.);
}

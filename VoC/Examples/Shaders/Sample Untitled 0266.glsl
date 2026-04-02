#version 420

// tweaked by psyreco

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main( void ) {

    vec2 position = ( gl_FragCoord.xy / resolution.xy );
    position.x = (position.x - 0.5) * (resolution.x / resolution.y) + 0.5;

    vec3 color = vec3(0, 0.2, 0.4);
    
    vec2 center = vec2(0.5);
    float dist = -inversesqrt(length(position - center) * log2(01.8));
    float angle = (atan(sin(position - center).y, cos(position - center).x));
    
    float xd = sin(angle * 2.50 + time) * 0.52 * dist;
    
    color += vec3(1.1, 0.5, -2.0) * 0.5 * max(0.0, sin((dist - time * 0.1) * 50.0)) * max(1.0, cos((angle + time * 0.5) * 10.0) * 1.5 * sin(angle * 80.0));

    color -= vec3(0.0, 1.0, 1.0) * max(0.0, cos((dist + xd - time * 0.1) * 100.0) * (1.0 - xd * (15.0 + 5.0 * cos(time))) * 0.5);
    color += smoothstep(vec3(1.0, 0.0, 0.0), vec3(0.0, 1.0, -1.0), vec3(dist * 2.0)) * max(0.0, cos((dist + xd - time * 0.1) * 100.0) * (1.0 - xd * (15.0 + 5.0 * cos(time))));
    color += vec3(0.0, 1.1, 0.0) * max(0.0, cos((dist * 0.2 + xd - time * 0.1) * 100.0) * (1.0 - xd * (15.0 + 5.0 * cos(-time)))) * 0.1;

    glFragColor = vec4( color, 1.0 );

}

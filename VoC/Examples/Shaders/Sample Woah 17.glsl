#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main( void ) {
    

    vec2 m = vec2(mouse.x * 2.0 - 1.0,  mouse.y * 2.0 - 1.0);
        vec2 p = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);
    
    vec2 c = m - p;
    
    // flower
    float u = sin((atan(c.y, c.x) + time * 1.0) * 50.0) *  1.0 * sin(time * 1.0);

    //float u = abs(sin((atan(c.y, c.x) + time * 0.5) * 20.0)) * 0.01;
    float t = 0.1 / abs(0.25 + u - length(c) * sin(time * 0.01));

    
    //float t = dot(p, v) / (length(p) * length(v));
        //float t = 0.2 / abs(0.5 - length(p) + sin(time * 0.5));
        glFragColor = vec4(vec3(t), 1.0);

}

#version 420

// The circle is entirely black, the colors are an illusion.

#extension GL_OES_standard_derivatives : enable

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 drawForTime(float rot) {
    
    vec2 position = ( gl_FragCoord.xy / resolution.yy );
    vec3 color = vec3(1.0);
    
    vec2 d = vec2(0.5) - position.xy;
    vec2 diff = vec2(d.x * cos(rot) - d.y * sin(rot), d.x * sin(rot) + d.y * cos(rot));
    float dist = length(diff);
    float ang = atan(diff.y, diff.x);
    
    float a2 = ang * 0.5;
    
    dist += 0.1;
    
    if(abs(ang + 0.7) < 3.14 * 0.5 && dist < 0.345)
        color = vec3(0.0);
    
    if(ang < -2.0) {
        if(abs(dist - 0.3) < 0.005)
            color = vec3(0.0);
        if(abs(dist - 0.32) < 0.005)
            color = vec3(0.0);
        if(abs(dist - 0.34) < 0.005)
            color = vec3(0.0);
    }
    
    dist -= 0.05;
    
    if(ang > 2.0) {
        if(abs(dist - 0.2) < 0.005)
            color = vec3(0.0);
        if(abs(dist - 0.22) < 0.005)
            color = vec3(0.0);
        if(abs(dist - 0.24) < 0.005)
            color = vec3(0.0);
    }
    
    dist -= 0.03;
    
    if(ang < 2.0 && ang > 0.5) {
        if(abs(dist - 0.1) < 0.005)
            color = vec3(0.0);
        if(abs(dist - 0.12) < 0.005)
            color = vec3(0.0);
        if(abs(dist - 0.14) < 0.005)
            color = vec3(0.0);
        if(abs(dist - 0.16) < 0.005)
            color = vec3(0.0);
    }
    
    return color;
}

void main( void ) {

    

    vec3 color = vec3(0.0);
    
    float rot = time*50;
    
    for(int i = 0; i < 20; i++) {
        color += drawForTime(rot + float(i) * 0.01);
    }
    
    color /= 20.0;
    
    glFragColor = vec4( color, 1.0 );

}

#version 420

//moving your mouse to the right of the screen clears the diagram
#define mr 0.28
#define mt 5.

#define DRAW_CIRCLES
#define WITHIN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

uniform sampler2D backbuffer;

vec3 color = vec3(1);
mat3 transform = mat3(1.);

vec2 doTransform (vec2 position){
    vec3 p = transform * vec3(position, 1.);
    
    return p.xy / p.z;
}

void translate (vec2 vec){
    transform *= mat3(
        1, 0, 0,
        0, 1, 0,
        vec.x, vec.y, 1
    );
}

void scale (float scale){
    transform *= mat3(
        scale, 0, 0,
        0, scale, 0,
        0, 0, 1
    );
}

void rotate (float angle){
    float c = cos(angle);
    float s = sin(angle);
    
    transform *= mat3(
        c, -s, 0,
        s, c, 0,
        0, 0, 1
    );
}

void point (vec2 position){
    float a = length(doTransform(position) - gl_FragCoord.xy) / 2.;
    
    glFragColor = mix(vec4(color, 1), glFragColor, clamp(a, 0., 1.));
}

void circle (vec2 position, float radius){
    float a = abs(length(doTransform(position) - gl_FragCoord.xy) - radius);
    
    glFragColor = mix(vec4(color, 1), glFragColor, clamp(a, 0., 1.));
}

void main (void){
    translate(resolution / 2.);
    float radius = min(resolution.x, resolution.y) / 3.;
    float t = time * 0.25;
    
    color = vec3(0, 1, 0);
    
    for (int i = 0; i < 50; i++){
        #ifdef DRAW_CIRCLES
        circle(vec2(0, 0), radius);
        #endif
        
        rotate(t);
        
        #ifdef WITHIN
        translate(vec2(0, radius - radius * mr));
        #else
        translate(vec2(0, radius + radius * mr));
        #endif
        
        radius *= mr;
        t *= mt;
    }
    
    color = vec3(1, 0, 0);
    
    point(vec2(0, 0));
    
    if (mouse.x < 0.5){
        glFragColor = vec4(texture2D(backbuffer, gl_FragCoord.xy / resolution).r + glFragColor.r, glFragColor.gb, 1);
    }
}

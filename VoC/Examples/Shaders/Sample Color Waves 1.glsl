#version 420

// original https://www.shadertoy.com/view/4d2cRK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    float zoom = 0.15;
    vec2 uv = zoom * (gl_FragCoord.xy - resolution.xy / 2.0);
        
    float t = time * 3.1415;
    
    float x = uv.x;
    float y = uv.y;
    
    
    float pi = acos(-1.);
        
   
    float m = 1.;
    float n = 8.;
    float p = 1.;
    
    float r = sqrt(x*x+y*y);
    float th = atan(y, x);
   
        
    const int points = 7;
    
    float angle;
    float w;
    float value;
    
    vec3 color = vec3(0.5, 0.5, 0.5);

    angle = pi / float(points) * float(0);
    w = x * sin(angle) + y * cos(angle);
    value = (sin(w + t) + 1.) / 4.;
    color += vec3(value, 0, 0);
    
    angle = pi / float(points) * float(1);
    w = x * sin(angle) + y * cos(angle);
    value = (sin(w + t) + 1.) / 4.;
    color += vec3(value, value, 0);

    angle = pi / float(points) * float(2);
    w = x * sin(angle) + y * cos(angle);
    value = (sin(w + t) + 1.) / 4.;
    color += vec3(0, value, 0);
    
    angle = pi / float(points) * float(3);
    w = x * sin(angle) + y * cos(angle);
    value = (sin(w + t) + 1.) / 4.;
    color += vec3(0, value, value);

    angle = pi / float(points) * float(4);
    w = x * sin(angle) + y * cos(angle);
    value = (sin(w + t) + 1.) / 4.;
    color += vec3(0, 0, value);

    angle = pi / float(points) * float(5);
    w = x * sin(angle) + y * cos(angle);
    value = (sin(w + t) + 1.) / 4.;
    color += vec3(value, 0, value);
    
    angle = pi / float(points) * float(6);
    w = x * sin(angle) + y * cos(angle);
    value = (sin(w + t) + 1.) / 4.;
    color += vec3(value, value, value);

    
    glFragColor = vec4(sin(color * 5.), 1); 
}

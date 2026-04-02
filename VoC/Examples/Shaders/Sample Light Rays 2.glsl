#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main( void ) {

    vec3 col = vec3(0.0);
    for (int i=0; i<1; i++)
    {
        vec2 p = gl_FragCoord.xy / resolution.x - vec2(0.5, 0.5 * resolution.y / resolution.x) + vec2(sin(float(i*i) + 0.5*time), sin(float(i*i*i) + 0.8*time)) * 0.25;
        float l = length(p);
        float a = atan(p.y, p.x);
    
        col.x += pow(1.0 - l, 2.0) + sin(a * 15.0 + 2.0 * time + sin(a * 7.0 + 13.0 * time) * 0.1) * 0.2 + sin(a * 3.0 +7.0 * time) * 0.4;
    
        col.y += col.x*sin(col.x);
        if (col.x < 0.0) col.y = -col.x;
        col.z += 0.25;
        

//        col.x = pow (col.x, sin(0.5 * time)* 0.5 + 1.0);
//        col.y = pow (col.y, sin(0.3 * time) * 0.5 + 1.0);
//        col.z = pow (col.z, sin(0.2 * time) * 0.5 + 1.0);
        
//        clamp(col.x, 0.0, 1.0);
    }

    glFragColor = vec4(col, 1.0);

}

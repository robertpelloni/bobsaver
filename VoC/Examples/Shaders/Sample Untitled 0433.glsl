#version 420

uniform float time;
uniform vec2 resolution;
uniform sampler2D bb;

out vec4 glFragColor;

vec3 palette( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

void main() {
    vec2 p = gl_FragCoord.xy / resolution.x * .9;
    vec3 col;
    float tt = time * 0.1;

        for(float i = 1.0; i < 20.0; i++){
        p.x += 0.1 / (i) * sin(i * 7.0 * p.y + tt + cos(tt / (20. * i) * i));
             p.y += 0.1 / (i)* cos(i * 10.0 * p.x + tt + sin((tt / (15. * i)) * i));
         }
         col.r = abs(p.x + p.y);
        //glFragColor = vec4(palette(col.r, vec3(0.8, 0.5, 0.4), vec3(0.2, 0.4, 0.2), vec3(2.0, 1.0, 1.0), vec3(0.00, 0.25, 0.25)), 1.0);
    glFragColor = vec4(palette(col.r, vec3(0.5, 0.5, 0.5), vec3(0.5, 0.5, 0.5), vec3(1.0, 1.0, 1.0), vec3(0.00, 0.10, 0.20)), 1.0);
}

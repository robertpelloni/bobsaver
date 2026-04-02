#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_ITER 2.0
void main( void ) {

    vec2  surfacePos = (gl_FragCoord.xy - resolution.xy*.5) / resolution.y;
    vec2 p = surfacePos*8.0;
    vec2 i = p;
    float c = 0.0;
    float inten = 0.15;
    float r = length(p+vec2(sin(time),sin(time*0.433+2.))*3.);
    
    for (float n = 0.0; n < MAX_ITER; n++) {
        float t = r-time * (1.0 - (1.9 / (n+1.)));
              t = r-time/(n+0.6);//r-time * (1.0 + (0.5 / float(n+1.)));
        i -= p + vec2(
            cos(t - i.x-r) + sin(t + i.y), 
            sin(t - i.y) + cos(t + i.x)+r
        );
        c += 1.0/length(vec2(
            (sin(i.x+t)/inten),
            (cos(i.y+t)/inten)
            )
        );
    
    }
    //c=sqrt(c);
    c /= float(MAX_ITER);
    r = 1.5-0.25*r;
    //glFragColor = vec4(r*(sin(time*3.)+1.4)*2.*c*vec3(0.5, 0.5, 1), 1.0);
    //glFragColor = vec4(c*vec3(0.5, 0.5, 1), 1.0);
    //glFragColor = vec4(vec3(c,c,c*c)*vec3(2.3, 2., 2.5)-0.15, 1.0);
    glFragColor = vec4(vec3(c,c,c)*vec3(2.4, 2.0, 2.5)-0.15, 1.0);
}

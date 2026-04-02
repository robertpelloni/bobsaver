#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float tri_a = tan(3.14/3.);
bool tri(vec2 p, float k){
    return p.y < p.x * tri_a + k && p.y < p.x * -tri_a + k && p.y > -k;
}

void main( void ) {
vec2  surfacePos = (gl_FragCoord.xy - resolution.xy*.5) / resolution.y;
    vec2 p = surfacePos;
    float z = 1.0;
    vec3 color = vec3(.4+.2*float(mod(floor(p.x*32.), 2.)==mod(floor(p.y*32.), 2.)));
    
    #define R2(T) mat2(cos(T), -sin(T), sin(T), cos(T))
    
    p = surfacePos+vec2(0,.5);
    for(int i = 0; i <= 15; i += 1){
        if(tri(p, 0.04)){
            color = vec3(0.4,0.3,0.0);
            z += 0.125;
        }
        p.y -= 0.03;
        p *= R2((mouse.x-.5)*0.1*cos(time+float(i))*cos(time+float(i)));
    }
    p.y += 0.1;
    for(int i = 0; i <= 4; i += 1){
        p *= R2(-.93*2.*3.14159*sign(p.x));
        p.y += -0.09;
        if(tri(p*vec2(1.5,1), 0.06)){
            color = vec3(0.4,0.3,0.0);
            z += 0.25;
        }
        p *= 1.1*R2((mouse.x-.5)*0.4*cos(time+float(i))*cos(time+float(i)));
    }
    //p *= R2(atan(p.x, p.y)*12.);
    for(int i = 0; i <= 7; i += 1){
        if(tri(p, 0.125*abs(length(p*5.)-.5))){
            color = vec3(0.1+z*0.1,0.3,0.1);
            z += 0.1;
            z *= 1.2;
        }
        p.y -= 0.033;
        p *= 0.9*R2(-.95*2.*3.14159*sign(p.x));
        p *= R2((mouse.x-.5)*0.3*cos(time+float(i))*cos(time+float(i)));
    }
    
    glFragColor = vec4( color*z, 1.0 );
}

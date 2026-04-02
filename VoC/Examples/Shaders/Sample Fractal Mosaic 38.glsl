#version 420

// original https://www.shadertoy.com/view/DsySRm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define fmod(x,y) mod(floor(x),y)
vec2 triangle_wave(vec2 a){
    //a -= .5;
    vec2 a2 = //change this constant to get other interesting patterns
        vec2(1.,.5)
    ,
    
    a1 = a+a2;
    return abs(fract((a1)*(a2.x+a2.y))-.5);
}

void main(void)
{
    glFragColor = vec4(0.0);
    vec3 col = vec3(0.);
    float t1 = 2.;
    vec2 uv = (gl_FragCoord.xy)/resolution.y/t1/2.0;
    uv.x += time/t1/12.0;
    //if(mouse*resolution.xy.z>.5)
    //uv = uv.xy + mouse*resolution.xy.xy / resolution.xy/t1;
    float scale = 1.5;
    vec2 t2 = vec2(0.);
    for(int k = 0; k < 9; k++){
        uv = (uv+t2)/scale;
        t2 = triangle_wave(uv-.5);
        uv = t2-triangle_wave(uv.yx);
        
        col.x =
            max(abs(uv.y-uv.x*sign(t2.x-t2.y))/2.,col.x)
            //max(max(fract(t2.y-t2.x+.5),fract(uv.y-uv.x+.5))/3.,col.x)
            //max(max(abs(t2.y-t2.x),abs(uv.y*sign(uv.x)-uv.x))/3.,col.x)
        ;
        col.x =
            //abs(col-(1.-col.x));
            max(abs(col.x-(1.-col.x)),col.x/4.);
    }
    glFragColor = vec4(vec3(col.x),1.0);
}
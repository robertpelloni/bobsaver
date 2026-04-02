#version 420

// original https://www.shadertoy.com/view/cljSRw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define fmod(x,y) mod(floor(x),y)
vec2 triangle_wave(vec2 a){
    vec2 a2 =
        vec2(1.,.5)
    ,
    a1 = a+a2;
    return abs(fract((a1)*(a2.x+a2.y))-.5);
}

void main(void)
{
    glFragColor = vec4(0.0);
    vec3 col = vec3(0.);
    vec2 uv = (gl_FragCoord.xy)/resolution.y/2.0;
    uv.x += time/12.0;
    //if(mouse*resolution.xy.z>.5)
    //uv = uv.xy + mouse*resolution.xy.xy / resolution.xy;
    
    vec2 t2 = vec2(0.);
    for(int k = 0; k < 9; k++){
        uv = (uv+t2)/1.5;
        t2 = triangle_wave(uv+.5);
        uv = t2-triangle_wave(uv.yx+1.)/1.5;
        
        //log-polar stuff
        //uv=vec2(log(length(uv/3.)), atan(uv.y/3., uv.x/3.))/3.;
        
        col.x =
            max(max((t2.y+t2.x),abs(uv.y-uv.x))/3.,col.x)
        ;
        col =
            abs(col-1.+col.x);
    }
    glFragColor = vec4(col,1.0);
}

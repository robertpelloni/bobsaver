#version 420

// original https://www.shadertoy.com/view/ldtXRM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
Original work:
https://media.giphy.com/media/3o7WTN8FmMgK9hrZyU/giphy.gif
*/

#define PI 3.14159265359
#define TWO_PI 6.28318530718

float circle(in vec2 uv, in float _radius){
    return 1.-smoothstep(_radius-(_radius*0.01),
                         _radius+(_radius*0.01),
                         dot(uv,uv)*4.0);
}

float line(vec2 uv, vec2 origin, vec2 destiny, float radius){
    destiny -= origin;
    float color = length( clamp( dot(uv-origin,destiny)/dot(destiny,destiny), 0.,1.) *destiny - uv+origin );
    return smoothstep(color-0.01,color+0.01, radius);    
}

mat2 rotate2d(float _angle){
    return mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle));
}

//  Function from Iñigo Quiles 
//  https://www.shadertoy.com/view/MsS3Wc
vec3 hsb2rgb( in vec3 c ){
    vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),
                             6.0)-3.0)-1.0, 
                     0.0, 
                     1.0 );
    rgb = rgb*rgb*(3.0-2.0*rgb);
    return c.z * mix( vec3(1.0), rgb, c.y);
}

void main(void)
{
    //zero centered uv from -1 to 1 vertically
    vec2 uv = gl_FragCoord.xy / resolution.xy*2.;
    uv-=1.0;
    uv.x *= resolution.x/resolution.y;
    
    //bg circle
    vec3 color = 1.0-vec3(circle(uv,4.0));
    
    const float maxQtd = 16.;
    float curMax = floor(fract(time/30.0)*maxQtd);
    mat2 rot = rotate2d(-PI/curMax);
    for(float i=0.; i<maxQtd; i++){
        if(curMax<i) continue;
        float index = i/curMax;
        float angle = index*PI;
        if(i>0.) uv *= rot;
        
        //reverse rotation direction
        //angle*=-1.;
        
        //line
        color = mix(color, vec3(1.0), line(uv, vec2(0, -1.0), vec2(0, 1.0), 0.003));
        
        //dot
        color = mix(color, hsb2rgb(vec3(index,1.0,1.0)), circle(uv+vec2(0., cos(angle+time*3.0)), 0.008));
    }
    
    glFragColor = vec4(color, 1.0);
}

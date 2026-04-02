#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define feed 0.089
#define kill 0.097
#define da 0.84
#define db 0.4

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void main( void ) {

    vec2 uv = ( gl_FragCoord.xy / resolution.xy );
    vec2 pixel=3.0/(resolution)+0.005*(rand(uv+time)-0.5);
    vec2 ab;
    if(mouse.x==0.0){
        ab.x=1.0;
        ab.y=0.0;
    }else{
        ab=texture2D(backbuffer,uv).yz;
            
        vec2 laplace=
            0.05*(texture2D(backbuffer,uv+vec2(pixel.x,pixel.y)).yz+
            texture2D(backbuffer,uv-vec2(pixel.x,pixel.y)).yz+
            texture2D(backbuffer,uv+vec2(pixel.x,-pixel.y)).yz+
            texture2D(backbuffer,uv-vec2(pixel.x,-pixel.y)).yz)+
            0.2*(texture2D(backbuffer,uv+vec2(0.0,pixel.y)).yz+
            texture2D(backbuffer,uv-vec2(0.0,pixel.y)).yz+
            texture2D(backbuffer,uv+vec2(pixel.x,0.0)).yz+
            texture2D(backbuffer,uv-vec2(pixel.x,0.0)).yz)-ab;
        
        vec2 d=vec2(da*laplace.x-ab.x*ab.y*ab.y+feed*(1.0-ab.x),
            db*laplace.y+ab.x*ab.y*ab.y-(kill+feed)*ab.y);
        ab+=0.8*d;
    }
    float d=dot(mouse-uv,mouse-uv);
    if(d<0.0005){
        ab+=(1.0-d/0.0005);    
    }
    glFragColor = vec4(0.0,ab,0.0);

}

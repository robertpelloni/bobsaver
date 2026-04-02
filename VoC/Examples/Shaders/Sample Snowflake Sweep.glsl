#version 420

// original https://www.shadertoy.com/view/ssXBRX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 2.0*acos(0.0);
const float SQRT3 = sqrt(3.0);
const mat2 ROT1 = mat2(cos(PI/1.5),sin(PI/1.5),-sin(PI/1.5),cos(PI/1.5));
const mat2 ROT2 = mat2(cos(PI/6.0),sin(PI/6.0),-sin(PI/6.0),cos(PI/6.0));

float fractal(vec2 x, float param);

void main(void) {
    vec2 uv = (gl_FragCoord.xy-resolution.xy/2.0)/length(resolution);
    vec3 col = 0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4));
    
    float a = mod((time/3.0),1.0);
    mat2 rot = pow(SQRT3,-a)*mat2(cos(a*PI/6.0),-sin(a*PI/6.0),sin(a*PI/6.0),cos(a*PI/6.0));
    
    float temp = fractal((0.7+0.2*sin(time/2.0))*rot*uv+vec2(0,0.5/SQRT3),(a-0.25*a*a)/0.75);
    temp = mod((time/3.0),2.0)<1.0?temp:1.0-temp;

    glFragColor = vec4(temp<0.0?col:vec3(0.15+0.2*temp),1.0);
}

float fractal(vec2 x, float param){
    if (x.y<-0.0||x.y/(0.25*SQRT3)+abs(x.x)*4.0/3.0>2.0){
        return -1.0;
    }
    float t = 1.0;
    for (int i=0;i<6;i++){
        if (x.y/(0.25*SQRT3)+abs(x.x)*4.0<2.0){
            if (x.y>1.0/SQRT3){
                x = x*3.0-vec2(0.0,SQRT3);
            }else if(x.x+x.y/SQRT3<-1.0/6.0){
                x = x*3.0+vec2(1.0,0.0);
            }else if(-x.x+x.y/SQRT3<-1.0/6.0){
                x = ROT1*ROT1*(x*3.0-vec2(1.0,0.0))+vec2(-0.25,0.25*SQRT3);
                t = 1.0-t;
            }else if(x.x<1.0/6.0&&x.x+min(x.y,1.0/SQRT3-x.y)*SQRT3>1.0/6.0){
                x = mat2(1.5,0.5*SQRT3,-0.5*SQRT3,1.5)*(x-vec2(0.0,0.5/SQRT3))+vec2(0.0,0.5/SQRT3);
                t = 1.0-t;
            }else{
                if (x.x<1.0/6.0){
                    if (x.y>0.5/SQRT3){
                        x = ROT1*ROT1*(x-vec2(0.0,0.5/SQRT3))+vec2(0.0,0.5/SQRT3);
                    }else{
                        x = ROT1*(x-vec2(0.0,0.5/SQRT3))+vec2(0.0,0.5/SQRT3);
                        t = 1.0-t;
                    }
                }
                x = mat2(0.0,SQRT3,-SQRT3,0.0)*(x-vec2(0.0,0.5/SQRT3))+vec2(0.0,0.5/SQRT3);
                t = 1.0-t;
            }
        }else{
            if (x.x<0.0){
                x = ROT1*ROT2*(x+vec2(0.5,0.0))*SQRT3+vec2(0.0,0.5*SQRT3);
            }else{
                x = ROT2*ROT2*ROT1*ROT2*(x-vec2(0.5,0.0))*SQRT3+vec2(0.0,0.5*SQRT3);
            }
            if (x.y/(0.25*SQRT3)+abs(x.x)*4.0>2.0){
                if (x.x<0.0){
                    x = ROT1*ROT2*(x+vec2(0.5,0.0))*SQRT3+vec2(0.0,0.5*SQRT3);
                }else{
                    x = ROT2*ROT2*ROT1*ROT2*(x-vec2(0.5,0.0))*SQRT3+vec2(0.0,0.5*SQRT3);
                }
            }
        }
    }
    x = (param*mat2(1.0,0.0,0.0,1.0)+(1.0-param)*mat2(0.5,-0.5*SQRT3,0.5/SQRT3,1.5))*(x-vec2(0.5,0.0))+vec2(0.5,0.0);
    return ((x.y>1.0/SQRT3||x.x+x.y*SQRT3<1.0/6.0||x.y/(0.25*SQRT3)+abs(x.x)*4.0>2.0)?t:1.0-t);
}

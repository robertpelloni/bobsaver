#version 420

// original https://www.shadertoy.com/view/ldK3Dc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
Original work
http://49.media.tumblr.com/0913449568032fe45a5310854426eb2e/tumblr_nmjnksPbul1tcuj64o1_400.gif
*/

#define PI 3.14159265359

float circle(in vec2 _st, in float _radius){
    vec2 dist = _st-vec2(0.5);
    float angle = atan(dist.y, dist.x);
    if(angle<-PI/2.0) return 0.0;
    else if(angle>0.0 && angle<PI/2.0) return 0.0;
    return 1.-smoothstep(_radius-(_radius*0.01),
                         _radius+(_radius*0.01),
                         dot(dist,dist)*4.0);
}

mat2 rotate2d(float _angle){
    return mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle));
}

float easeInOutExpo(float t, float b, float c, float d) {
    t /= d/2.0;
    if (t < 1.0) return c/2.0 * pow( 2.0, 10.0 * (t - 1.0) ) + b;
    t--;
    return c/2.0 * ( -pow( 2.0, -10.0 * t) + 2.0 ) + b;
}

float easeInOutQuad(float t, float b, float c, float d) {
    t /= d/2.0;
    if (t < 1.0) return c/2.0*t*t + b;
    t--;
    return -c/2.0 * (t*(t-2.0) - 1.0) + b;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.y;
    vec2 zoom = vec2(8.0, 8.0);
    vec2 index = floor(zoom * uv)/zoom;
    uv *= zoom;
    
    
    float behavior = 0.0;    
    uv.x += step(1., mod(uv.y,2.0));
    behavior = step(1., mod(uv.x,2.0));
    
    float totalColors = 8.0;
    float cIndex = floor((index.x+index.y)*totalColors);
    cIndex = mod(cIndex, totalColors);
    vec3 color = vec3(0.0);
    if(cIndex==0.0) color = vec3(0.92, 0.35, 0.20);
    else if(cIndex==1.0) color = vec3(0.50, 0.77, 0.25);
    else if(cIndex==2.0) color = vec3(0.00, 0.63, 0.58);
    else if(cIndex==3.0) color = vec3(0.08, 0.45, 0.73);
    else if(cIndex==4.0) color = vec3(0.38, 0.18, 0.55);
    else if(cIndex==5.0) color = vec3(0.76, 0.13, 0.52);
    else if(cIndex==6.0) color = vec3(0.91, 0.13, 0.36);
    else if(cIndex==7.0) color = vec3(0.96, 0.71, 0.17);
    
    uv = fract(uv);
    
    //crazy result
    //uv /= 2.0;
    
    float frame = time/3.0;
    //if(mouse*resolution.xy.x>0.0) frame *= 5.0 * (mouse*resolution.xy.x / resolution.x);//velocity
    
    float freq = 0.0;
        
    float angle = 0.0;
    if(behavior==0.0) {
        if(mod(frame, 1.0)<0.5)
            angle = PI/2.0*easeInOutExpo(mod(frame, 1.0)*2.0, 0.0, 1.0, 1.0);
        else
            angle = PI/2.0+PI/2.0*easeInOutExpo((mod(frame, 1.0)-0.5)*2.0, 0.0, 1.0, 1.0);
    }else{
        angle = PI/2.0*easeInOutQuad((sin(frame*PI*4.0)+1.0)/2.0, 0.0, 1.0, 1.0);
    }
    
    uv -= vec2(0.5);
    uv = rotate2d( angle ) * uv;
    uv += vec2(0.5);
    
    vec3 circ = vec3(circle(uv,1.0));
    
    color *= circ;
    
    glFragColor = vec4(color,1.0);
}

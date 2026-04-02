#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3ttyzM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define M_PI = 3.14159265

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

float smoothClamp(float x, float a, float b)
{
    float t = clamp(x, a, b);
    return t != x ? t : b + (a - b)/(1. + exp((b - a)*(2.*x - a - b)/((x - a)*(b - x))));
}

void main(void)
{
    float PI = 3.14159263;
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    float freq;
    float radius;
    float t;
    float rot;
    int numEl;
    float scale = 1.; //how bright the image is. set very high for pure B/W, set lower for grayscale

    t = time*0.007*60.; //a timing constant
    freq = 90.; //busyness of screen
    radius = 0.8*cos(t*0.012)+2.; //radius of circle of points
    rot = 0.02; //how fast the screen rotates
    numEl = 6; //number of radiators on ring
    

    
    float col = 0.;
    if(numEl%2==0){ //if the number of radiators is even, it'll be lined up well
    for(int i = 0; i<numEl; i++){
    uv = gl_FragCoord.xy/resolution.xy; //reset coordinate plane
    uv.x *= resolution.x/resolution.y; //scale coordinates
    uv.x -= 0.5*resolution.x/resolution.y; //move origin
    uv.y-=0.5; //move origin
    uv.x-=radius*cos(2.*3.14159*float(i)/float(numEl)-rot*t); //move to each point on ring
    uv.y-=radius*sin(2.*3.14159*float(i)/float(numEl)-rot*t);
    
    col+=(scale/float(numEl))*cos(freq*length(uv)-t); //sum up the field magnitude at each point due to each radiator
    //0.77 is a scaling factor. Set higher for wider color range.
    }
    }
    
    else{ //if number of radiators is odd, the ring needs to be rotated to be vertically symmetric
    
    for(int i = 0; i<numEl; i++){
    uv = gl_FragCoord.xy/resolution.xy;
    uv.x *= resolution.x/resolution.y;
    uv.x -= 0.5*resolution.x/resolution.y;
    uv.y-=0.5;
    uv.x-=radius*cos(2.*3.14159*float(i)/float(numEl)-rot*t+PI/2.);
    uv.y-=radius*sin(2.*3.14159*float(i)/float(numEl)-rot*t+PI/2.);
    
    col+=(scale/float(numEl))*cos(freq*length(uv)-t);
    }  
    }
    uv = gl_FragCoord.xy/resolution.xy;
    uv.y-=60.;
    //uv.x-=10.;
    
    col-=0.35;
    col+=1.*smoothClamp((scale*1.)*(cos(freq*0.02*length(uv.y)-t*1.)), 0.0, 0.6);//change the constants in this for different effects
    col=1.*abs(col); //icy. uncomment to defrost
   
    vec3 col2 = pal(col, vec3(0.5, 0.5, 0.5),
                            vec3(0.5, 0.5, 0.5),
                            vec3(1.0, 1.0, 1.0),
                            vec3(0.0, 0.1, 0.2));
    
    glFragColor = vec4(vec3(col2), 1);
}

#version 420

// original https://www.shadertoy.com/view/wsBSRR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int firstOctave = 3;
const int octaves = 8;
const float persistence = 0.6;

//Based on https://www.shadertoy.com/view/4lB3zz by madweedfall

//Not able to use bit operator like <<, so use alternative noise function from YoYo
//
//https://www.shadertoy.com/view/Mls3RS
//
//And it is a better realization I think
float noise(int x,int y)
{   
    float fx = float(x);
    float fy = float(y);
    
    return 2.0 * fract(sin(dot(vec2(fx, fy) ,vec2(12.9898,78.233))) * 43758.5453) - 1.0;
}

float smoothNoise(int x,int y)
{
    return noise(x,y)/4.0+(noise(x+1,y)+noise(x-1,y)+noise(x,y+1)+noise(x,y-1))/8.0+(noise(x+1,y+1)+noise(x+1,y-1)+noise(x-1,y+1)+noise(x-1,y-1))/16.0;
}

float COSInterpolation(float x,float y,float n)
{
    float r = n*3.1415926;
    float f = (1.0-cos(r))*0.5;
    return x*(1.0-f)+y*f;
    
}

float InterpolationNoise(float x, float y)
{
    int ix = int(x);
    int iy = int(y);
    float fracx = x-float(int(x));
    float fracy = y-float(int(y));
    
    float v1 = smoothNoise(ix,iy);
    float v2 = smoothNoise(ix+1,iy);
    float v3 = smoothNoise(ix,iy+1);
    float v4 = smoothNoise(ix+1,iy+1);
    
       float i1 = COSInterpolation(v1,v2,fracx);
    float i2 = COSInterpolation(v3,v4,fracx);
    
    return COSInterpolation(i1,i2,fracy);
    
}

float PerlinNoise2D(float x,float y)
{
    float sum = 0.0;
    float frequency =0.0;
    float amplitude = 0.0;
    for(int i=firstOctave;i<octaves + firstOctave;i++)
    {
        frequency = pow(2.0,float(i));
        amplitude = pow(persistence,float(i));
        sum = sum + InterpolationNoise(x*frequency,y*frequency)*amplitude;
    }
    
    return sum;
}

void main(void)
        {
            vec2 uv = gl_FragCoord.xy / resolution.xy;
            
            float t = time + 100.0;
            
            float x = uv.x;
            //float x = ((uv.x - 0.5) * (0.4 + 0.4 * uv.y));
            
            //layer1
            float x1 = x+t*0.01;
            //float y1 = uv.y+3.0+0.05*cos(t*2.0)+t*0.01;
            float noise1 = 0.5+2.0*PerlinNoise2D(x1,uv.y);
            
            //layer2
            float x2 = x+t*0.2;
            //float y2 = uv.y+3.0+0.1*cos(t);
            float noise2 = 0.5+2.0*PerlinNoise2D(x2,uv.y);
                        
            float noise = 1.2*noise1+0.6*noise2;
            
            //round noise
            float a = floor(noise*10.0)/10.0;

            float b = floor(noise*50.)/50.;
            float c = floor(noise2*50.0);
            
            float final = a;
            
            //Add shine
            if((b==0.7||b==0.9||b==0.5||b==1.1||b==0.5)
               &&noise2>0.50
            ){
                final=0.2+0.2*noise2;
            }    
            glFragColor = vec4(2.0-2.0*final,1.0-1.0*final,0.0-2.0*final,1.0);
        }


#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.14159265;

float sphere(float t, float k)
{
    float d = 1.0+t*t-t*t*k*k;
    if (d <= 0.0)
        return -1.;
    float x = (k - sqrt(d))/(1.0 + t*t);
    return asin(x*t);
}

void main( void ) 
{
    // bg texture
    vec4 texColor = vec4(0.25,0.0,0.15,1.0);
    
    vec2 uv = gl_FragCoord.xy - 0.5*resolution.xy;
    float v = resolution.x;
    if (v > resolution.y)
        v = resolution.y;
    uv /= v;
    uv *= 3.0;
    float len = length(uv);
    float k = 1.;
    float len2;

   // len2 = sphere(len*k,sqrt(2.0))/sphere(1.*k,sqrt(2.0));
    len2 = sphere(len*k,1.4142) /sphere(1.*k,1.4142);
    len2 *= 0.5/len;
    uv = uv * len2 +0.5;
    //uv = uv + 0.5;
    
    vec2 pos = uv;
    float t = time/1.0;
    float r, g, b;
    
    //val += sin((pos.x*scale1 + t*2.))*3.;
    r = cos(pos.x*160.+t*3.)+sin(pos.y*160.);
    //g = r+sin((pos.y*10. * cos(t*.3)));
    g = r*sin((pos.y*10. * cos(t*.3)));
    b = g-sin((pos.x+pos.y + cos(t*1.3)));

    float glow =  0.040 / (0.01 + 0.5*distance(len, 1.));
    glow =  0.020 / (0.01 + 0.5*abs(len-1.));
    
    //val = (cos(PI*val) + 1.0) * 0.5;
    vec4 col2 = vec4(r, g, b, 1.0);
    float us = (len < 1.0) ? 1.0 : 0.0;
    glFragColor = us * 0.5 * col2 + glow * col2;
    glFragColor += texColor;
    
}

#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;
#define PI 3.141592

vec3 pal(float x)
{
    return max(min(sin(vec3(x,x+PI*2.0/3.0,x+PI*4.0/3.0))+0.5,1.0),0.0);
}

void main( void ) {
    
    float t = time*0.1;
    float t2 = time*4.0;

    
    vec2 position = ( gl_FragCoord.xy / resolution.xy ) - 0.5;
    position *= 2.25;
    position.y *= dot(position,position);
    
    position.y *= 1.0+sin(position.x*3.0+t2)*0.2;
    
    float foff = 0.3;
    float den = 0.05;
    float amp = 0.9;
    float freq = 25.;
    float offset = 0.1-sin(position.x*0.5)*5.05;

        float modifer = 0.;
    
    for(float i = 0.0; i < 3.0; i+=1.0)
        modifer += 1.0/abs((position.y + (amp*sin(((position.x*4.0 + t) + offset) *freq+i*foff))))*den;;
    
    vec3 colour = pal(-t2*0.9+position.x*2.)*0.25* modifer;    //vec3 (0.13, 0.18, 0.4) * 
    //     ((1.0 / abs((position.y + (amp * sin(((position.x*4.0 + t) + offset) *freq)))) * den)
    //    + (1.0 / abs((position.y + (amp * sin(((position.x*4.0 + t) + offset) *freq+foff)))) * den)
    //    + (1.0 / abs((position.y + (amp * sin(((position.x*4.0 + t) + offset) *freq-foff)))) * den));
    
    glFragColor = vec4( colour, 1.0 );

}

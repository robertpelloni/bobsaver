#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float rect(vec2 uv, vec2 pos, vec2 size,float sharpness) {
return  clamp(1. - length(max(abs(uv - pos)-size, 0.0))*sharpness, 0.0, 1.0);
}
float hash(float v)
{
    return fract(fract(v/1e4)*v-1e6);
}
void main( void ) 
{
    vec2 position = ( gl_FragCoord.xy / resolution.xy );
    float ym = 1.0-abs(1.0-(position.y*2.0));
    ym *= 1.9;
    
    position -= 0.5;
    position.y = dot(position,position)*2.0;
    
    position.y += sin(time*0.53-position.x*12.4)*0.15;
    position *= 1.0+sin(position.y*42.4+position.x*12.98+time*1.1)*0.1;
    float color = 0.0;
    
    float t =0.5+(sin(time*0.35)*0.01);
    
    float i_f = 1.5+sin(sin(time*3.3+position.y*22.0)+cos(time*2.2-position.x*42.0)+time*0.4)*0.17;
    for(int i = 0;i < 60;i++)
    {
        i_f += 1.;
        float sharpness = 200.+sin(time+ym+abs(position.x*4.4))*140.0;
        float r = hash(i_f) * 60.;
        color += (rect(position, vec2( mod(t * (i_f * r * .2), 3.) - 1. , mod(r,1.)   ), vec2(0.3,0.13) * (i_f * 0.025) , sharpness) * (0.02 * (i_f * 0.15) ));        
        color += (rect(position, vec2( mod(t * (i_f * r * .2), 3.) - 1. , mod(r,1.)   ), vec2(0.3,0.13) * (i_f * 0.025) , sharpness * 0.02) * (0.02 * (i_f * 0.15) ));        
    }
    
    vec3 col1 = vec3(ym*color*0.5,color*0.4,color*0.6);
    
    
    vec3 col2 = vec3(ym*.8,ym*0.5,ym*.5);
    col1 = mix(col2,col1,color);
    
    
    glFragColor = vec4(col1*.5, 1.0 );
    
    
}

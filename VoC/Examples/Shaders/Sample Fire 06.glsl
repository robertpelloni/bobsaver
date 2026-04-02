#version 420

// original https://www.shadertoy.com/view/4sKyzw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define backgroundColor vec4(0.)

vec3 random3(vec3 st)
{
    st = vec3( dot(st,vec3(127.1,311.7,211.2)/20.),
                dot(st,vec3(269.5,183.3, 157.1)), dot(st,vec3(269.5,183.3, 17.1))  );
       return -1.0 + 2.0*fract(sin(st)*43758.5453123);
}

vec2 random2(vec2 st){
    st = vec2( dot(st,vec2(127.1,311.7)),
              dot(st,vec2(269.5,183.3)) );
    return -1.0 + 2.000*fract(sin(st)*43758.5453123);
}

float noise3D(vec3 st) 
{
    vec3 i = floor(st) ;
      vec3 f = fract(st);
        
    vec3 u = smoothstep(0.,1.,f);
    
    float valueNowxy01 =mix( mix( dot( random3(i + vec3(0.0,0.0,0.0) ), f - vec3(0.0,0.0,0.0) ),
                                  dot( random3(i + vec3(1.0,0.0,0.0) ), f - vec3(1.0,0.0,0.0) ), u.x),
                        mix( dot( random3(i + vec3(0.0,1.0,0.0) ), f - vec3(0.0,1.0,0.0) ),
                                   dot( random3(i + vec3(1.0,1.0,0.0) ), f - vec3(1.0,1.0,0.0) ), u.x), u.y);
    float valueNowxy02 =mix( mix( dot( random3(i + vec3(0.0,0.0,1.0) ), f - vec3(0.0,0.0,1.0) ),
                                  dot( random3(i + vec3(1.0,0.0,1.0) ), f - vec3(1.0,0.0,1.0) ), u.x),
                        mix( dot( random3(i + vec3(0.0,1.0,1.0) ), f - vec3(0.0,1.0,1.0) ),
                                   dot( random3(i + vec3(1.0,1.0,1.0) ), f - vec3(1.0,1.0,1.0) ), u.x), u.y);

    return abs(mix(valueNowxy01, valueNowxy02, u.z));

}

// Value Noise by Inigo Quilez - iq/2013
// https://www.shadertoy.com/view/lsf3WH
float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    vec2 u = f*f*(3.0-2.0*f);

    return mix( mix( dot( random2(i + vec2(0.0,0.0) ), f - vec2(0.0,0.0) ),
                     dot( random2(i + vec2(1.0,0.0) ), f - vec2(1.0,0.0) ), u.x),
                mix( dot( random2(i + vec2(0.0,1.0) ), f - vec2(0.0,1.0) ),
                     dot( random2(i + vec2(1.0,1.0) ), f - vec2(1.0,1.0) ), u.x), u.y);
}

void DrawCircle (inout vec4 buffer, in vec4 circlesColor, in float radius, in vec2 coord, in vec2 pos){
      
   buffer =  mix(circlesColor, buffer, smoothstep(radius, radius + 0.001, distance(vec2(coord.x, coord.y*0.2), pos)));
    
}

void applyTexture(inout vec4 buffer, in vec2 uv){
    
    vec4 temp = buffer;
    float Noise = (noise3D(vec3(vec2(uv.x*1. + noise(vec2(uv.y*10., time/2.+uv.y+uv.x*8.))*pow(uv.y,0.8)*1.5
                                     *noise3D(vec3(uv.y*10.,2.+uv.y+uv.x*15., time))
                                     , uv.y-time*0.3)*15., time*1.6))+0.5)/2.;
    buffer.rg *= pow(pow(1.6,Noise),2.);
    
    buffer.g *= Noise;
    
    buffer = mix( temp, buffer,clamp(uv.y*6.-0.2, 0. , 1.));
    buffer.rg *= pow(pow(1.2,Noise),2.);
    
    buffer = mix( backgroundColor,buffer, smoothstep(noise(vec2(time,uv.x*10.))*0.15 + pow(uv.y,0.7)/1.,
                                                     noise(vec2(time,uv.x*10.))*0.15 
                                                     +pow(uv.y,0.7)/1.+0.15, Noise));
    
    
    
    
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.y;
    
    vec4 color = backgroundColor;
    
    vec4 circleColor =vec4(0.9, 0.6, 0.0, 1.0);
    applyTexture(circleColor,uv);
    
    DrawCircle(color, circleColor, 1.5, uv, vec2(resolution.x/(resolution.y*2.), 0.5));
    //color = vec4(0.9, 0.6, 0.0, 1.0);
    
    
    // Output to screen
    glFragColor =color;
}

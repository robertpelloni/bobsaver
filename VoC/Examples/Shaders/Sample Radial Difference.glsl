#version 420

// original https://www.shadertoy.com/view/4lyGzh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// hash and noise from iqs 'Noise - gradient - 2D': https://www.shadertoy.com/view/XdXGW8

vec2 hash( vec2 p )
{
    p = vec2( dot(p,vec2(127.1,311.7)),
              dot(p,vec2(269.5,183.3)) );

    return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

float noise( in vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );
    
    vec2 u = f*f*(3.0-2.0*f);

    return mix( mix( dot( hash( i + vec2(0.0,0.0) ), f - vec2(0.0,0.0) ), 
                     dot( hash( i + vec2(1.0,0.0) ), f - vec2(1.0,0.0) ), u.x),
                mix( dot( hash( i + vec2(0.0,1.0) ), f - vec2(0.0,1.0) ), 
                     dot( hash( i + vec2(1.0,1.0) ), f - vec2(1.0,1.0) ), u.x), u.y);
}

// main code moving radial gradients around through noise using difference

void main(void)
{
    float r = 0.0;
    float g = 0.0;
    float b = 0.0;
    float dist = 0.0;
    vec3 color = vec3(0.0);
    float time = 0.05*time;
    for(float f=0.0;f<69.0;f++){
        float size = .005+.01*noise(vec2(0.83+0.231*f+time));
        vec2 point = resolution.xy/2.0 + 0.5*resolution.xy*vec2(
             noise(vec2(3.97+0.123*f+time))
            ,noise(vec2(2.01+0.421*f+time))
        );
        float dist = length(gl_FragCoord.xy-point);
        dist *= size;
        if (mod(f,3.0)!=0.0) color.r = dist - abs(color.r);
        if (mod(f,4.0)!=0.0) color.g = dist - abs(color.g);
        if (mod(f,5.0)!=0.0) color.b = dist - abs(color.b);
        //dist = length(gl_FragCoord.xy-point) - abs(dist);
    }
    //vec2 uv = gl_FragCoord.xy / resolution.xy;
    //glFragColor = vec4(vec3(dist/resolution.y),1.0);
    glFragColor = vec4(1.0-color,1.0);
    
}

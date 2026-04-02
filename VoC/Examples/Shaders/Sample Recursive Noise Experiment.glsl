#version 420

// original https://www.shadertoy.com/view/wllGzr

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hash( float n )
            {
                return fract(sin(n)*43758.5453);
            }

            float noise( vec3 x )
            {
                // The noise function returns a value in the range -1.0f -> 1.0f

                vec3 p = floor(x);
                vec3 f = fract(x);

                f       = f*f*(3.0-2.0*f);
                float n = p.x + p.y*57.0 + 113.0*p.z;

                return mix(mix(mix( hash(n+0.0), hash(n+1.0),f.x),
                               mix( hash(n+57.0), hash(n+58.0),f.x),f.y),
                           mix(mix( hash(n+113.0), hash(n+114.0),f.x),
                               mix( hash(n+170.0), hash(n+171.0),f.x),f.y),f.z)-.5;
            }

void main(void)
{
    
    
    vec3 t = (float(frames)*vec3(1.0,2.0,3.0)/1.0)/1000.0;//+mouse*resolution.xy.xyz/1000.0;

    
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv=uv/4.0+.5;
    uv-=mouse*resolution.xy.xy/resolution.xy/4.0;

    vec3 col = vec3(0.0);
    
    
    
    for(int i = 0; i < 16; i++){
        float i2 = float(i)*1.0;
                    col.r+=noise(uv.xyy*(12.0+i2)+col.rgb+t*sign(sin(i2/3.0)));
                    col.g+=noise(uv.xyx*(12.0+i2)+col.rgb+t*sign(sin(i2/3.0)));
                    col.b+=noise(uv.yyx*(12.0+i2)+col.rgb+t*sign(sin(i2/3.0)));
                }
                

                for(int i = 0; i < 16; i++){
                    float i2 = float(i)*1.0;
                    col.r+=noise(uv.xyy*(32.0)+col.rgb+t*sign(sin(i2/3.0)));
                    col.g+=noise(uv.xyx*(32.0)+col.rgb+t*sign(sin(i2/3.0)));
                    col.b+=noise(uv.yyx*(32.0)+col.rgb+t*sign(sin(i2/3.0)));
                }
                col.rgb/=32.0;
                col.rgb=mix(col.rgb,normalize(col.rgb)*2.0,1.0);
                col.rgb+=.3;
    
    

    // Output to screen
    glFragColor = vec4(col,1.0);
}

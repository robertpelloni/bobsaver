#version 420

// original https://www.shadertoy.com/view/wdsSDj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Stephane Cuillerdier - Aiekick/2019 (twitter:@aiekick)
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Tuned via NoodlesPlate

//@NOTE_START
//Test to integrate the uniforms widget in NoodlesPlate after import
//the uniforms widgets are inserted between tags @UNIFORMS_START and @UNIFORMS_ELSE
//the replaces vars are between tags @UNIFORMS_ELSE and @UNIFORMS_END
//see demo in this video : https://twitter.com/aiekick/status/1104900482236104705
//@NOTE_END
                          
//@UNIFORMS_START
//uniform vec2(0.0:1.0:0.924,0.)     _c; fractal params
//uniform int(0:200:100)             _niter; fractal iterations
//uniform float(0.0:1.0:0.25912)     _k; zmul coef
//uniform float(0.0:5.0:2.2)         _scale; scale
//uniform float(0.0:.5:0.03)         _limit; moving limit
//uniform float(0.0:100.0:8.)         _dist; fractal distance
//uniform vec3(color:1,0,1)         _color; color
//uniform vec2(0:5:1,1.5)             _colorVar; color mix variation
//@UNIFORMS_ELSE
#define _c vec2(0.9240,0)
#define _niter 100
#define _k 0.25912
#define _scale 2.2
#define _limit 0.03
#define _dist 8.
#define _color vec3(1,0,1)
#define _colorVar vec2(1,1.5)
//@UNIFORMS_END

vec2 zmul(vec2 a, vec2 b){return mat2(a,-a.y,a.x)*b;} // z * z 
vec2 zinv(vec2 a){return vec2(a.x, -a.y) / dot(a,a);} // 1 / z

const float AA = 2.;
    
float shape(vec2 z)
{
    //return max(abs(z.x), abs(z.y)) * 0.8 + dot(z,z) * 0.2;
    //return max(abs(z.x)-z.y,z.y);
    return dot(z,z);
}

void main(void)
{
    vec2 g = gl_FragCoord.xy;
    vec4 f = vec4(0);
    
    vec2 si = resolution.xy;
        
    for( float m=0.; m<AA; m++ )
    for( float n=0.; n<AA; n++ )
    {
        vec2 o = vec2(m,n) / AA - .5;
        vec2 uv = ((g+o)*2.-si)/min(si.x,si.y) * _scale;
        vec2 z = uv, zz;
        vec2 c = _c;
        c.y += sin(time) * _limit;
        float it = 0.;
        for (int i=0;i<_niter;i++)
        {
            zz = z;
            z = zinv( _k * zmul(z, z) - c);
            if( shape(z) > _dist ) break;
            it++;
        }

        vec4 sec = _colorVar.x + it * _colorVar.y + vec4(_color,1);
        
        f += .5 + .5 * sin(sec - shape(zz) / shape(z));
    }
    
    f /= AA * AA;

    glFragColor = f;
}

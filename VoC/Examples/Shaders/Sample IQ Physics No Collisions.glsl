#version 420

// original https://www.shadertoy.com/view/MdB3Rc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by inigo quilez - iq/2013
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

float hash1( float p ) { return fract(sin(p)*43758.5453); }
vec2  hash2( float p ) { vec2 q = vec2( p, p+123.123 ); return fract(sin(q)*43758.5453); }

// draw a disk with motion blur
vec3 diskWithMotionBlur( vec3 col, in vec2 uv, in vec3 sph, in vec2 cd, in vec3 sphcol, in float alpha )
{
    vec2 xc = uv - sph.xy;
    float a = dot(cd,cd);
    float b = dot(cd,xc);
    float c = dot(xc,xc) - sph.z*sph.z;
    float h = b*b - a*c;
    if( h>0.0 )
    {
        h = sqrt( h );
        
        float ta = max( 0.0, (-b - h)/a );
        float tb = min( 1.0, (-b + h)/a );
        
        if( ta < tb ) // we can comment this conditional, in fact
            col = mix( col, sphcol, alpha*clamp(2.0*(tb-ta),0.0,1.0) );
    }

    return col;
}

vec2 GetPos( in vec2 p, in vec2 v, in vec2 a, float t )
{
    return p + v*t + 0.5*a*t*t;
}
vec2 GetVel( in vec2 p, in vec2 v, in vec2 a, float t )
{
    return v + a*t;
}

// intersect a dis moving in a parabolic trayecgory with a line. 
// sphere is |x(t)|-R²=0, with x(t) = p + v·t + ½·a·t²
// plane is <x,n> + k = 0
float iPlane( in vec2 p, in vec2 v, in vec2 a, float rad, vec3 pla )
{
    float A = dot(a,pla.xy);
    float B = dot(v,pla.xy);
    float C = dot(p,pla.xy) + pla.z - rad;
    float h = B*B - 2.0*A*C;
    if( h>0.0 )
        h = (-B-sqrt(h))/A;
    return h;
}

const vec2 acc = vec2(0.01,-9.0);

void main(void)
{
    vec2 p = -1.0 + 2.0*gl_FragCoord.xy / resolution.xy;
    p.x *= resolution.x/resolution.y;
    float w = resolution.x/resolution.y;

    vec3 pla0 = vec3( 0.0,1.0,1.0);
    vec3 pla1 = vec3(-1.0,0.0,  w);    
    vec3 pla2 = vec3( 1.0,0.0,  w);
        
    vec3 col = vec3(0.0) + (0.15 + 0.05*p.y);
    
    for( int i=0; i<8; i++ )
    {
        // start position        
        float id = float(i);

        float time = mod( time + id*0.5, 4.8 );
        float sequ = floor( (time+id*0.5)/4.8 );
        float life = time/4.8;

        float rad = 0.05 + 0.1*hash1(id*13.0 + sequ);
        vec2 pos = vec2(-w,0.8) + vec2(2.0*w,0.2)*hash2( id + sequ );
        vec2 vel = (-1.0 + 2.0*hash2( id+13.76 + sequ ))*vec2(8.0,1.0);

        // integrate
        float h = 0.0;
        // 10 bounces
        for( int j=0; j<10; j++ )
        {
            float ih = 100000.0;
            vec2 nor = vec2(0.0,1.0);

            // intersect planes
            float s;
            s = iPlane( pos, vel, acc, rad, pla0 ); if( s>0.0 && s<ih ) { ih=s; nor=pla0.xy; }
            s = iPlane( pos, vel, acc, rad, pla1 ); if( s>0.0 && s<ih ) { ih=s; nor=pla1.xy; }
            s = iPlane( pos, vel, acc, rad, pla2 ); if( s>0.0 && s<ih ) { ih=s; nor=pla2.xy; }
            
            if( ih<1000.0 && (h+ih)<time )        
            {
                vec2 npos = GetPos( pos, vel, acc, ih );
                vec2 nvel = GetVel( pos, vel, acc, ih );
                pos = npos;
                vel = nvel;
                vel = 0.75*reflect( vel, nor );
                pos += 0.01*vel;
                h += ih;
            }
        }
        
        // last parabolic segment
        h = time - h;
        vec2 npos = GetPos( pos, vel, acc, h );
        vec2 nvel = GetVel( pos, vel, acc, h );
        pos = npos;
        vel = nvel;

        // render
        vec3 scol = 0.5 + 0.5*sin( hash1(id)*2.0 -1.0 + vec3(0.0,2.0,4.0) );
        float alpha = smoothstep(0.0,0.1,life)-smoothstep(0.8,1.0,life);
        col = diskWithMotionBlur( col, p, vec3(pos,rad), vel/24.0, scol, alpha );
    }
    
    glFragColor = vec4(col,1.0);
}

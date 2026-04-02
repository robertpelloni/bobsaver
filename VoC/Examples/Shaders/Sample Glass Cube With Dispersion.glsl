#version 420

// original https://www.shadertoy.com/view/WdBBz3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//June 21, 2020: Added chromatic abberation

#define ABSORBTION                 vec3(0.03)
#define IOR                     1.5
#define DISPERSION                 0.03
#define CHROMATIC_ABBERATION    0.01

#define TIMESCALE 0.35
#define INTERNAL_REFLECTIONS 4
#define SAMPLES 30.0

#define rot2(a) mat2(cos(a),-sin(a),sin(a),cos(a))

vec3 rotate ( vec3 p, vec3 r ) {
    p.yz *= rot2(r.x);
    p.xz *= rot2(-r.y);
    p.xy *= rot2(r.z);
    return p;
}

float InteriorCubeReflection ( vec3 ro, vec3 rd ) {
    vec3 d = (0.5*sign(rd)-ro)/rd;
    return min( min(d.x, d.y), d.z );
}

float IntersectCube ( vec3 ro, vec3 rd ) {
    float dfront = -InteriorCubeReflection(-ro,rd);
    float dback  = InteriorCubeReflection(ro,rd);
    return dback>=dfront ? dfront : -1.0;
}

float GetReflectance ( vec3 i, vec3 t, vec3 nor, float iora, float iorb ) {
    vec2 c = nor * mat2x3(i,t);
    vec2 ior = vec2(iora,iorb);
    vec2 sp = ( mat2(c,-c.yx)*ior ) / ( mat2(c,c.yx)*ior );
    return dot(sp,sp)/2.0;
}

vec3 GetSky ( vec3 rd ) {
    float v = dot(rd, vec3(0.5,-0.15,0.85));
    v = smoothstep(-0.05, 0.05, sin(v*50.0));
    return vec3( v );
}

vec3 GetDispersedColor( float w ) {
    return max( sin( ( w - vec3(0.0,0.25,0.5) ) * 6.28318531 ), 0.0);
    /*
    vec3 s = vec3(0.9, 1.0, 0.8);
    vec3 c = w - vec3( 0.0, 0.25, s.b-0.5 );
    c = clamp(c*s, 0.0, 1.0) * 6.28318531;
    c = sin(c) * s;
    return max( c, 0.0);
    */
}

vec3 GetRenderSample ( vec3 ro, vec3 rd, float df ) {
    float rl = IntersectCube( ro, rd );
    
    if ( rl > 0.0 ) {
        
        float iord = IOR + DISPERSION*(df-0.5);
        
        vec3 xyz = ro + rd*rl;
        vec3 nor = round( xyz*1.00001 );
        vec3 power = vec3(1.0);
        vec3 refractd = refract( rd, nor, 1.0/iord );
        vec3 reflectd = reflect( rd, nor );
        float refl = GetReflectance ( rd, refractd, nor, 1.0, iord );
        vec3 c = GetSky(reflectd) * refl;
        power *= 1.0-refl;
        rd = refractd;

        for ( int i=0; i<INTERNAL_REFLECTIONS; i++ ) {
            rl = InteriorCubeReflection( xyz, rd );
            xyz += rd*rl;
            nor = round( xyz*1.00001 );
            refractd = refract( rd, -nor, 1.0/iord );
            reflectd = reflect( rd, -nor );
            refl = GetReflectance ( rd, refractd, -nor, iord, 1.0 );
            power *= exp( -ABSORBTION * rl );
            c += GetSky(refractd) * (1.0-refl) * power;
            power *= refl;
            rd = reflectd;
        }
        return c;
    } else {
        return GetSky(rd);
    }
}

void main(void) {
    vec2 uv = (2.0*gl_FragCoord.xy-resolution.xy) / resolution.x;
    
    vec3 col = vec3(0.0);
    for ( float f = 0.0; f<SAMPLES; f++ ) {
        float w = f/SAMPLES;        // wavelength sample ( 0 => 1 across visible spectrum )
        
        float b = (fract(f*134.102119) - 0.5) / 60.0;                            //temporal offset for motion blur
        vec2 aa = (fract((f+uv)*134.102119+time)-0.5)/resolution.x*3.0;        //quick and sloppy positional offset for aa
        
        vec3 cp = vec3( aa, -2.5);
        vec3 cr = normalize( vec3(uv,1.0+w*CHROMATIC_ABBERATION) );
        cp = rotate( cp, vec3( (time + b) * TIMESCALE ) );
        cr = rotate( cr, vec3( (time + b) * TIMESCALE ) );
        
        vec3 c = GetRenderSample( cp, cr, w );
        
        vec3 sp = GetDispersedColor(w);
        col += c * sp;
    }
    col /= SAMPLES/3.0;
    
    col = smoothstep(0.0, 1.0, col);
    col = pow( col, vec3(0.4545) );
    glFragColor = vec4( col, 1.0 );
}

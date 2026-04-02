#version 420

// original https://www.shadertoy.com/view/Wsc3z2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Inigo Quilez 2019

// This shader shows how to use the adjoint matrix to
// transform the normals of an object when the scale
// is not uniform. The adjoint matrix is quicker to
// compute than the traditional transpose(inverse(m)),
// is more numerically stable, and does not break
// when the matrix has negative determinant. The shader
// uses spheres which have been deformed with non uniform
// scales, to show the effect.

// Compare methods:
//
// 0: n = adjoint(m)            --> correct
// 1: n = transpose(inverse(m)) --> sometimes incorrect, and slow
// 2: n = m                     --> always incorrect
//
#define METHOD 0

//===================================================

// Computes the lower 3x3 part of the adjoint.
// Use to transform normals with arbitrary 
// matrices. More info here:
// https://github.com/graphitemaster/normals_revisited
mat3 adjoint( in mat4 m )
{
    float k0 = m[1][0]*m[3][1]-m[3][0]*m[1][1];
    float k1 = m[1][0]*m[3][2]-m[3][0]*m[1][2];
    float k2 = m[1][0]*m[3][3]-m[3][0]*m[1][3];
    float k3 = m[1][1]*m[3][2]-m[3][1]*m[1][2];
    float k4 = m[1][1]*m[3][3]-m[3][1]*m[1][3];
    float k5 = m[1][2]*m[3][3]-m[3][2]*m[1][3];
    float c0 = m[2][0]*m[3][3]-m[3][0]*m[2][3];
    float c1 = m[2][0]*m[3][1]-m[3][0]*m[2][1];
    float c2 = m[2][0]*m[3][2]-m[3][0]*m[2][2];
    float c3 = m[2][1]*m[3][2]-m[3][1]*m[2][2];
    float c4 = m[2][1]*m[3][3]-m[3][1]*m[2][3];
    float c5 = m[2][2]*m[3][3]-m[3][2]*m[2][3];
               
    return mat3( 
     (m[1][1]*c5-m[1][2]*c4+m[1][3]*c3),
    -(m[1][0]*c5-m[1][2]*c0+m[1][3]*c2),
     (m[1][0]*c4-m[1][1]*c0+m[1][3]*c1),
    -(m[0][1]*c5-m[0][2]*c4+m[0][3]*c3),
     (m[0][0]*c5-m[0][2]*c0+m[0][3]*c2),
    -(m[0][0]*c4-m[0][1]*c0+m[0][3]*c1),
     (m[0][1]*k5-m[0][2]*k4+m[0][3]*k3),
    -(m[0][0]*k5-m[0][2]*k2+m[0][3]*k1),
     (m[0][0]*k4-m[0][1]*k2+m[0][3]*k0)
     );
}

// sphere intersection
float iSphere( in vec3 ro, in vec3 rd, in mat4 worldToObject )
{
    vec3 roo = (worldToObject*vec4(ro,1.0)).xyz;
    vec3 rdd = (worldToObject*vec4(rd,0.0)).xyz;
    
    float a = dot( rdd, rdd );
    float b = dot( roo, rdd );
    float c = dot( roo, roo ) - 1.0;
    float h = b*b - a*c;
    if( h<0.0 ) return -1.0;
    return (-b-sqrt(h))/a;
}

// sphere shadow
float sSphere( in vec3 ro, in vec3 rd, in mat4 worldToObject )
{
    vec3 roo = (worldToObject*vec4(ro,1.0)).xyz;
    vec3 rdd = (worldToObject*vec4(rd,0.0)).xyz;
    
    float a = dot( rdd, rdd );
    float b = dot( roo, rdd );
    float c = dot( roo, roo ) - 1.0;
    float h = b*b - a*c;
    if( h<0.0 ) return -1.0;

    return sign( h - b*b*sign(b) );
}

//-----------------------------------------------------------------------------------------

mat4 rotateAxisAngle( vec3 v, float angle )
{
    float s = sin( angle );
    float c = cos( angle );
    float ic = 1.0 - c;

    return mat4( v.x*v.x*ic + c,     v.y*v.x*ic - s*v.z, v.z*v.x*ic + s*v.y, 0.0,
                 v.x*v.y*ic + s*v.z, v.y*v.y*ic + c,     v.z*v.y*ic - s*v.x, 0.0,
                 v.x*v.z*ic - s*v.y, v.y*v.z*ic + s*v.x, v.z*v.z*ic + c,     0.0,
                 0.0,                0.0,                0.0,                1.0 );
}

mat4 translate( in vec3 v )
{
    return mat4( 1.0, 0.0, 0.0, 0.0,
                 0.0, 1.0, 0.0, 0.0,
                 0.0, 0.0, 1.0, 0.0,
                 v.x, v.y, v.z, 1.0 );
}

mat4 scale( in vec3 v )
{
    return mat4( v.x, 0.0, 0.0, 0.0,
                 0.0, v.y, 0.0, 0.0,
                 0.0, 0.0, v.z, 0.0,
                 0.0, 0.0, 0.0, 1.0 );
}

//-----------------------------------------------------------------------------------------

mat4 getSphereToWorld( in int i, out bool isFlipped )
{
    float t = time*0.5;
    vec3 fli = sign(sin(float(i)+vec3(1.0,2.0,3.0)));
    mat4 rot = rotateAxisAngle( normalize(sin(float(11*i)+vec3(0.0,2.0,1.0))), 0.0+t*1.3 );
    mat4 ros = rotateAxisAngle( normalize(sin(float( 7*i)+vec3(4.0,3.0,5.0))), 2.0+t*1.1 );
    mat4 sca = scale( (0.3+0.25*sin(float(13*i)+vec3(0.0,1.0,4.0)+t*1.7))*fli );
    mat4 tra = translate( vec3(0.0,0.5,0.0) + 0.5*sin(float(17*i)+vec3(2.0,5.0,3.0)+t*1.2) );
    
    isFlipped = (fli.x*fli.y*fli.z) < 0.0;
    return ros * tra * sca * rot;
}

const int kNumSpheres = 12;

float shadow( in vec3 ro, in vec3 rd )
{
    for( int i=0; i<kNumSpheres; i++ )
    {
        bool tmp;
        mat4 objectToWorld = getSphereToWorld( i, tmp );
        mat4 worldToObject = inverse( objectToWorld );
        if( sSphere( ro, rd, worldToObject ) > 0.0 )
            return 0.0;
    }
    return 1.0;
}

vec3 shade( in vec3 ro, in vec3 rd, in float t, 
            in float oid, in vec3 wnor )
{
    vec3 lig = normalize(vec3(-0.8,0.4,0.1));
    vec3 wpos = ro + t*rd;

    // material
    vec3  mate = vec3(0.18);
    if( oid>1.5 ) mate = 0.18*(0.55+0.45*cos(7.0*oid+vec3(0.0,2.0,4.0)));

    // lighting
    vec3 hal = normalize( lig-rd );
    float dif = clamp( dot(wnor,lig), 0.0, 1.0 );
    float sha = shadow( wpos+0.01*wnor, lig );
    float fre = clamp(1.0+dot(rd,wnor),0.0,1.0);
    float spe = clamp(dot(wnor,hal),0.0,1.0);

    // material * lighting        
    vec3 col = vec3(0.0);
    col += 8.0*vec3(1.00,0.90,0.80)*dif*sha;
    col += 2.0*vec3(0.10,0.20,0.30)*(0.6+0.4*wnor.y);
    col += 1.0*vec3(0.10,0.10,0.10)*(0.5-0.5*wnor.y);
    col += fre*(0.6+0.4*wnor.y);
    col *= mate;
    col += pow(spe,16.0)*dif*sha*(0.1+0.9*fre);

    // fog
    col = mix( col, vec3(0.7,0.8,1.0), 1.0-exp( -0.003*t*t ) );

    return col;
}
        
#if HW_PERFORMANCE==0
#define AA 1
#else
#define AA 2  // Set AA to 1 if your machine is too slow
#endif

void main(void)
{
    // camera movement    
    float an = 0.4*time;
    vec3 ro = vec3( 2.5*cos(an), 0.7, 2.5*sin(an) );
    vec3 ta = vec3( 0.0, 0.2, 0.0 );
    // camera matrix
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(0.0,1.0,0.0) ) );
    vec3 vv = normalize( cross(uu,ww));

    vec3 tot = vec3(0.0);
#if AA>1
    for( int m=0; m<AA; m++ )
    for( int n=0; n<AA; n++ )
    {
        // pixel coordinates
        vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5;
        vec2 p = (-resolution.xy + 2.0*(gl_FragCoord+o))/resolution.y;
#else    
        vec2 p = (-resolution.xy + 2.0*gl_FragCoord.xy)/resolution.y;
#endif

        // create view ray
        vec3 rd = normalize( p.x*uu + p.y*vv + 2.0*ww );

        // raytrace
        float tmin = 1e10;
        vec3  wnor = vec3(0.0);
        float oid = 0.0;

        // raytrace plane
        float h = (-0.5-ro.y)/rd.y;
        if( h>0.0 ) 
        { 
            tmin = h; 
            wnor = vec3(0.0,1.0,0.0); 
            vec3 wpos = ro+tmin*rd;
            oid = 1.0;
        }

        // raytrace spheres
        for( int i=0; i<kNumSpheres; i++ )
        {
            // location of sphere i
            bool isFlipped = false;
            mat4 objectToWorld = getSphereToWorld( i, isFlipped );
            mat4 worldToObject = inverse( objectToWorld );

            float res = iSphere( ro, rd, worldToObject );
            if( res>0.0 && res<tmin )
            {
                tmin = res; 
                vec3 wpos = ro+tmin*rd;
                vec3 opos = (worldToObject*vec4(wpos,1.0)).xyz;
                vec3 onor = normalize(opos) *(isFlipped?-1.0:1.0);

                #if METHOD==0 // CORRECT
                wnor = normalize(adjoint(objectToWorld)*onor);
                #endif
                #if METHOD==1 // WRONG OFTEN
                wnor = normalize((transpose(inverse(objectToWorld))*vec4(onor,0.0)).xyz);
                #endif
                #if METHOD==2 // WRONG ALWAYS
                wnor = normalize((objectToWorld*vec4(onor,0.0)).xyz);
                #endif

                oid = 2.0 + float(i);
            }
        }

        // shading/lighting    
        vec3 col = vec3(0.7,0.8,1.0);
        if( oid>0.5 )
        {
            col = shade( ro, rd, tmin, oid, wnor );
        }

        col = pow( col, vec3(0.4545) );
        tot += col;
#if AA>1
    }
    tot /= float(AA*AA);
#endif

    glFragColor = vec4( tot, 1.0 );
}

#version 420

// original https://www.shadertoy.com/view/3dX3zj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sdSphere( in vec3 p, in float r )
{
    return length(p)-r;
}

// exponential smooth min (k = 32);
float smin( float a, float b, float c, float d, float e,float k )
{
    float res = exp2( -k*a ) + exp2( -k*b ) + exp2( -k*c ) + exp2( -k*c ) + exp2( -e*c );
    return -log2( res )/k;
}

float map(in vec3 pos)
{
    float r = 0.5;
    vec3  d = vec3(0.2,0.7,0.2);
    float h = -cos(time/8.)*5.;
    float s0 =  sdSphere( pos - d*vec3(sin(time/2.0+0.2),sin(time/2.1+0.4) + h,sin(time/2.3+0.7)), r ) ;
    float s1 =  sdSphere( pos - d*vec3(sin(time/2.4+1.3),sin(time/1.9+0.5) + h,sin(time/2.5+0.2)), r ) ;
    float s2 =  sdSphere( pos - d*vec3(sin(time/2.9+2.3),sin(time/3.0+0.3) + h,sin(time/2.6+0.8)), r ) ;
    float s3 =  sdSphere( pos - d*vec3(sin(time/2.2+2.9),sin(time/2.8+0.8) + h,sin(time/1.8+0.9)), r ) ;
    float pl =  2. - abs(pos.y) ;

    return smin(s0,s1,s2,s3,pl,8.);
}

vec3 calcNormal( in vec3 pos )
{
    const float ep = 0.0001;
    vec2 e = vec2(1.0,-1.0)*0.5773;
    return normalize( e.xyy*map( pos + e.xyy*ep ) + 
                      e.yyx*map( pos + e.yyx*ep ) + 
                      e.yxy*map( pos + e.yxy*ep ) + 
                      e.xxx*map( pos + e.xxx*ep ) );
}

vec3 applyFog( in vec3  rgb,       // original color of the pixel
               in float distance ) // camera to point distance
{
    float fogAmount = 1.0 - exp( -distance*0.3 );
    vec3  fogColor  = vec3(0);
    return mix( rgb, fogColor, fogAmount );
}

mat3 setCamera( in vec3 ro, in vec3 ta )
{
    vec3 cw = normalize(ta-ro);
    vec3 up = vec3(0, 1, 0);
    vec3 cu = normalize( cross(cw,up) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

vec3 lavaLamp(in vec2 gl_FragCoord, in vec3 ro, in vec3 rd, in vec3 cd, float dist)
{
    float t = 1.0;
    float d;
    for( int i=0; i<64; i++ )
    {
        vec3 p = ro + t*rd;
        float h = map(p);
        t += h;
        d = dot(t*rd,cd);
        if( abs(h)<0.001 || d>dist ) break;
    }

    vec3 col = vec3(0.0);

    if( d<dist )
    {
        vec3 pos = ro + t*rd;
        vec3 nor = calcNormal(pos);

        pos *= 3.;
        pos.z += time*0.4;

        vec3 proj = abs(fract(pos)-0.5);
        proj = smoothstep(0.1,0.,proj);       
        col = vec3(dot(proj,smoothstep(0.1,0.9,vec3(1)-abs(nor))));
        col*= vec3(.5,1.,0.3);
        col = applyFog(col,d);
    }
    return col;
}

void mainVR( out vec4 glFragColor, in vec2 gl_FragCoord, in vec3 ro, in vec3 rd )
{
    glFragColor = vec4(lavaLamp(gl_FragCoord.xy ,ro/3. + vec3(0.0,.0,4.0),rd ,rd,14.) ,0);
}

#define AA 2

void main(void)
{
   vec3 tot = vec3(0.0);
    
    #if AA>1
    for( int m=0; m<AA; m++ )
    for( int n=0; n<AA; n++ )
    {
        // pixel coordinates
        vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5;
        vec2 p = (-resolution.xy + 2.0*(gl_FragCoord.xy+o))/resolution.y;
        #else    
        vec2 p = (-resolution.xy + 2.0*gl_FragCoord.xy)/resolution.y;
        #endif
 
        //vec3 cd = vec3(0.0,.0,-1.0);
        //vec3 ro = vec3(0.0,.0,4.0);
        
        // camera    
        vec3 ro = 4.*vec3( sin(0.00*time), 0.2 , cos(0.00*time) );
        //vec3 ro = vec3(0.0,.0,4.0);
        vec3 ta = vec3( 0 );
        // camera-to-world transformation
        mat3 ca = setCamera( ro, ta );
        //vec3 cd = ca[2];    
        
        vec3 rd =  ca*normalize(vec3(p,1.0));        
        
        vec3 col = lavaLamp(gl_FragCoord.xy ,ro ,rd ,ca[2],7.);

        tot += col;
    #if AA>1
    }
    tot /= float(AA*AA);
    #endif

    glFragColor = vec4( tot, 1.0 );
}

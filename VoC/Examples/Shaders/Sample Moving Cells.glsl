#version 420

// original https://www.shadertoy.com/view/NsSyWd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 N22(vec2 p){
    vec3 a = fract(p.xyx*vec3(123.123, 324.34, 542.12));
    a += dot (a, a+34.43);
    return fract(vec2(a.x*a.y, a.y*a.z));
}

float t= 10.;
void main(void) {
     vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
     
     float m = 0.;
     t += smoothstep(0.4, .0, abs(pow(sin(time/2.), 2.))-.4 );
    
     
     vec2 cellIndex = vec2(0);
     
     vec3 col;
             //vec2 p = sin(vec2(n.x*t+time/10., n.y*t*1.3+time/10.));

     uv *= 3.;
     vec2 gv = fract(uv)-.5;
     vec2 id = floor(uv);
     vec2 mg, mr;

     // iq's voronoi
     // https://www.shadertoy.com/view/ldl3W8
     float minDist = 100.0;
    for( int j=-1; j<=1; j++ )
    for( int i=-1; i<=1; i++ )
    {
        vec2 g = vec2(float(i),float(j));
        vec2 o = N22( id + g );
        o = 0.25*sin( (time/5.)+3.*t + 10.2831*o );
        vec2 r = g + o - gv;
        float d = dot(r,r);

        if( d<minDist )
        {
            minDist = d;
            mr = r;
            mg = g;
        }
    }
     
    for( int j=-1; j<=1; j++ )
    for( int i=-1; i<=1; i++ )
    {
        vec2 g = mg + vec2(float(i),float(j));
        vec2 o = N22( id + g );
        o = 0.25*sin( (time/5.)+3.*t + 10.2831*o );
        vec2 r = g + o - gv;

        if( dot(mr-r,mr-r)>0.00001 )
        minDist = min( minDist, dot( 0.5*(mr+r), r-mr ) );
    }
     col = (smoothstep(-.3, .7, minDist))*vec3(2., 1.3 , 1.);
     col = pow(col, vec3(.4545));
     glFragColor = vec4(col, 1.0);
}

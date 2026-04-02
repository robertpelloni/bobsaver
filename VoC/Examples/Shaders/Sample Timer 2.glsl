#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D back;

out vec4 glFragColor;

// "vacuum fluorescent mod" alternate ending below
// with some combination of these it will blow up like the old water simulation, just ease it back
// will use (2*blurx+1) * (2*blury+1) samples so increase these and decrease brightness
const int blurx = 2;
const int blury = blurx;
float radius = float(blurx)*2.;    // in pixels, increase for graininess/emptiness/pixeliness
float brightness = .023;        //increase for more increasenessecity as you wish

const float twopi = 6.283185307179586476925286766559;
const float pi   = 3.1415926535897932384626433832795;

float box( vec2 p, vec4 rect)
{
    float trim = min(rect.z, rect.w) * 0.5;
    float minX = min(p.x - rect.x, rect.x + rect.z - p.x);
    float minY = min(p.y - rect.y, rect.y + rect.w - p.y);
    return step(0.0, minX) * step(0.0, minY) * step(trim, minX + minY);
}

float digit( vec2 p, vec4 dim, float d)
{
    d = (d - mod(d,1.0)) / 10.0;
    d = mod( d, 1.0 );

    p.xy -= dim.xy;
    p.xy /= dim.zw;
    

    float c = 0.0;
    
    // I'm sure all of these can be improved... in fact, this way may actually be slower than just if else if else if else for
    // all ten numbers.  Oh well, it was worth a shot :)
    
    // ed: removed all conditional expressions, should work everywhere

    // top - 0, 2, 3, 5, 7, 8, 9
    c += box(p, vec4(0.05, 0.9, 0.9, 0.1)) * step(cos((0.85*d+0.1)*30.0) - sin(pow(d,1.0)), 0.0);

    // middle - 2, 3, 4, 5, 6, 8, 9
    c += box(p, vec4(0.05, 0.45, 0.9, 0.1)) * step(1.0, min(pow(6.0*d,2.0), pow(20.0*(d-0.7),2.0)));

    // bottom - 0, 2, 3, 5, 6, 8
    c += box(p, vec4(0.05, 0.0, 0.9, 0.1)) * step(0.0, max(cos(18.6*pow(d,0.75)), 1.0-pow(40.0*(d-0.8),2.0)));

    // bottom left - 0, 2, 6, 8
    c += box(p, vec4(0.0, 0.08, 0.1, 0.39)) * step(0.1, cos(d*30.0) * abs(d-0.4));
    
    // bottom right - 0, 1, 3, 4, 5, 6, 7, 8, 9
    c += box(p, vec4(0.9, 0.08, 0.1, 0.39)) * step(0.1, pow(4.0*d-0.8, 2.0));

    // top left - 0, 4, 5, 6, 8, 9
    c += box(p, vec4(0.0, 0.52, 0.1, 0.39)) * step(sin((d-0.05)*10.5) - 12.0*sin(pow(d,10.0)), 0.0);
    
    // top right - 0, 1, 2, 3, 4, 7, 8, 9
    c += box(p, vec4(0.9, 0.52, 0.1, 0.39)) * step(0.02, pow(d-0.55, 2.0));

    return c;
}

// NB: if you normalize the hue/sat result, cyan/magenta/yellow won't blow up the brightness
vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * normalize(mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y));
}

void main( void )
{
    vec2 p = ( gl_FragCoord.xy / resolution.xy );
    float c= 0.0;
    c += ( time < 100.0 ) ? 0.0 : digit( p, vec4( 0.05, 0.4, 0.2, 0.35 ), time/100.0 );
    c += ( time < 10.0) ? 0.0 : digit( p, vec4( 0.27, 0.4, 0.2, 0.35 ), time/10.0 );
    c += digit( p, vec4( 0.5, 0.4, 0.2, 0.35 ), time );
    c += box( p, vec4( 0.71, 0.4, 0.03, 0.035 ) );
    c += digit( p, vec4( 0.75, 0.4, 0.2, 0.35 ), time*10.0 );

#if 0
    c += digit( p, vec4( 0.0, 0.1, 0.09, 0.1 ), 0.0 );
    c += digit( p, vec4( 0.1, 0.1, 0.09, 0.1 ), 1.0 );
    c += digit( p, vec4( 0.2, 0.1, 0.09, 0.1 ), 2.0 );
    c += digit( p, vec4( 0.3, 0.1, 0.09, 0.1 ), 3.0 );
    c += digit( p, vec4( 0.4, 0.1, 0.09, 0.1 ), 4.0 );
    c += digit( p, vec4( 0.5, 0.1, 0.09, 0.1 ), 5.0 );
    c += digit( p, vec4( 0.6, 0.1, 0.09, 0.1 ), 6.0 );
    c += digit( p, vec4( 0.7, 0.1, 0.09, 0.1 ), 7.0 );
    c += digit( p, vec4( 0.8, 0.1, 0.09, 0.1 ), 8.0 );
    c += digit( p, vec4( 0.9, 0.1, 0.09, 0.1 ), 9.0 );
#endif
    
    // this is not gaussian blur or even efficient but it is pretty smooth
    vec3 d = vec3(0.0);
    for (int j = -blury; j <= blury; ++j)
    {
        for (int i = -blurx; i <= blurx; ++i)
        {
            vec2 sp = vec2(i,j) / vec2(blurx,blury);
            d += smoothstep(vec3(0.0), vec3(1.0), vec3(length(sp))) * brightness *
                texture2D(back, sp / resolution * radius + p).rgb;
        }
    }
    glFragColor = vec4( hsv2rgb(vec3(mouse.x, 1.0 - (mouse.y * 0.75), length(d))) + c + d, 1.0);
}

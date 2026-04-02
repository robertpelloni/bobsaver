#version 420

// original https://www.shadertoy.com/view/MllXz4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//noise function taken from https://www.shadertoy.com/view/XslGRr

float hash( float n ){
    return fract(sin(n)*43758.5453);
}

//this noise function was originally 3D noise, 
//but I am just setting z to 0 for the sake of simplicity here
//also cause most effects only care about 2D noise
float noise( vec2 uv ){
    vec3 x = vec3(uv, 0);

    vec3 p = floor(x);
    vec3 f = fract(x);
    
    f       = f*f*(3.0-2.0*f);
    float n = p.x + p.y*57.0 + 113.0*p.z;
    
    return mix(mix(mix( hash(n+0.0), hash(n+1.0),f.x),
                   mix( hash(n+57.0), hash(n+58.0),f.x),f.y),
               mix(mix( hash(n+113.0), hash(n+114.0),f.x),
                   mix( hash(n+170.0), hash(n+171.0),f.x),f.y),f.z);
}

float ring( float angle, float dist, float ANG, float THICKNESS, float POS, float SIZE ) {
    //angles between 4 and 15 are good
    //negative thickness makes it black, values around 0.02 are good
    
    float ZIGZAG = abs( mod( angle, ANG ) - ANG * 0.5 ) * SIZE;
    return ceil( dist - POS + ZIGZAG) - ceil( dist - (POS+THICKNESS) + ZIGZAG);   
}
float burst( float angle, float dist, float ANG ) {
    float B = abs( mod( angle, ANG ) - ANG * 0.5 );
    return B;
}
float lim( float IN, float amount ) {
    return IN * amount + (1.0 - amount);   
}
float inv( float IN ) {
     return 1.0 - IN;   
}
float ppp( float IN ) {
     return IN * IN * IN;   
}
float dots( float angle, float dist, float ANG, float POS ) {
    return ppp(7.5*burst( angle, dist, ANG )/ANG) * ppp(inv(ANG*1.5*distance( dist, POS )));
}

float normpdf(in float x, in float sigma)
{
    return 0.39894*exp(-0.5*x*x/(sigma*sigma))/sigma;
}

vec4 myoutput( vec2 Coord )
{
    
    float shortside = min( resolution.x, resolution.y );
    float longside = max( resolution.x, resolution.y );
    
    vec2 uv = Coord.xy / vec2( shortside, shortside );
    
    uv.x = uv.x - (longside/shortside - 1.0) * 0.5;
    
       float dist = distance( vec2( 0.5, 0.5 ), uv );
    
    uv = vec2( uv.x - 0.5, uv.y - 0.5 );
    
    float angle = degrees( atan( uv.y / uv.x ) );
    
    float TIMESCALE = 0.3;
    float T = time * TIMESCALE * 2.0;
    
    
    float n = noise( vec2( dist, T ) );
    float slow_n = noise( vec2( dist, T * 0.2) );
    float fast_n = noise( vec2( dist, T * 2.0) );
    float vslow_n = noise( vec2( dist, T * 0.01) );
    float vfast_n = noise( vec2( dist, T * 50.0) );
    float t = noise( vec2( time, T ) );
    
    float rand_r = noise( vec2( -T, T ) );
    float slow_r = noise( vec2( -T * 0.5, 1.0 ) );
    float vslow_r = noise( vec2( -T * 0.2, 1.0 ) );
    float vvslow_r = noise( vec2( -T* 0.05, 1.0 ) );
    
    float div = 7.0;
    float m = sin ( mod( angle, div )/(div*0.5) * 3.14 * 0.5 );
    float a = mod( angle, 10.0 ) * noise( vec2( T, angle ) );
        
    float TIME_MOD_SCALE = 1.0;
    float TIME_MOD = floor(0.5+sin( noise( vec2(-time + 1000.0, 1.0 )) ))*0.5*TIMESCALE*TIME_MOD_SCALE;

    TIMESCALE = TIMESCALE * TIME_MOD;
    
    float GRANULARITY = 1.75;
    float GRAN_DIST_FALLOFF = 0.5;
    float GRAN_DIST_FALLOFF_MOD = tan(noise (vec2( 500.0, -T ) ));
    GRAN_DIST_FALLOFF = GRAN_DIST_FALLOFF + GRAN_DIST_FALLOFF_MOD * 0.5;
    
    float Gr = (GRANULARITY-(dist * GRANULARITY * GRAN_DIST_FALLOFF)) * 50.0;
    float Gg = (GRANULARITY-(dist * GRANULARITY * GRAN_DIST_FALLOFF)) * 80.0;
    float Gb = (GRANULARITY-(dist * GRANULARITY * GRAN_DIST_FALLOFF)) * 100.0;
    
    float Gsign = clamp( sign( noise (vec2( T * 0.22, -T * 1.5 )) -0.5 ), -1.0, 0.0 );
    
    float rn = 360.0 / (ceil( noise(vec2( sin(T*0.1), 0.5 ) ) * 50.0) * 2.0 );    //randomly some divisor of 360
    float rd1 = ceil( noise(vec2( tan(T/10.0), 1.0 ) ) * 2.0 );    //randomly either 1 or 2
    float rd2 = ceil( noise(vec2( sin(T/10.0), 1.0 ) ) * 2.0 );    //randomly either 1 or 2
    float rd3 = ceil( noise(vec2( cos(T/10.0), 1.0 ) ) * 2.0 );    //randomly either 1 or 2
    float rd4 = ceil( noise(vec2( tan(T*0.0075+99.0), 1.0 ) ) * 1.2 );    //randomly either 1 or 2
    float rd5 = ceil( noise(vec2( tan(T*0.008+124.0), 1.0 ) ) * 1.5 );    //randomly either 1 or 2
    float rd6 = ceil( noise(vec2( tan(T*0.007+24.0), 1.0 ) ) * 1.7 );    //randomly either 1 or 2
    float rd7 = ceil( noise(vec2( tan(T*0.005), 1.0 ) ) * 1.4 );    //randomly either 1 or 2
    float exp4 = ceil( noise(vec2( tan(T*0.5), 1.0 ) ) * 2.0 ) * rd1;
    float coarse3 = ceil( noise(vec2( cos(T), 1.0 ) ) * 3.0 );
    float coarse10 = ceil( noise(vec2( cos(T), 1.0 ) ) * 10.0 );
    
    vec3 RING1 = rd2 * 0.5 * ring( angle, dist,6.0, 0.02, n, 0.01) * vec3( 1.0, 1.0, 1.0 ) * floor( n + 0.5 );
    vec3 RING2 = ring( angle, dist,10.0, 0.01, n/2.0, 0.01) * vec3( 1.0, 1.0, 1.0 ) * ceil( n - 0.3 );
    vec3 RING3 = ring( angle+(vslow_n*200.0*coarse3)*(2.0+n), dist,90.0*rd1/rd4, (0.02 + rand_r*0.01 + ppp(slow_r)*0.011)*ppp(rd4), n, 0.01) * vec3( 1.0, 1.0, 1.0 ) * 0.5;
    vec3 RING4 = ring( angle-time*(5.0*n), dist,10.0, 0.05, n, 0.01) * vec3( sin(T), cos(T), 0.1 ) * 0.5;
    vec3 RING5 = ring( angle, dist,30.0, n*20.0, n+0.3, 0.01) * vec3( 1.0, 1.0, 1.0 ) * 0.05 + (dist)*0.05;
    vec3 BURST1 = burst( angle, dist, rn * rd1 ) * vec3( 1.0, 1.0, 1.0 ) * 0.03 * (1.0 - dist);
    vec3 RING6 = max(ring( angle-(vslow_n*200.0*coarse3)*(2.0+vslow_n), dist,45.0*rd1, 0.3, n, 0.01),0.0) * vec3( sin(T), tan(T) * 0.5, rand_r ) * (rd7 - 1.0) * inv(dist) * 0.5;
    vec3 DOTS1 = max(ceil(dots( angle + T*30.0, dist, 10.0, 0.25 + rand_r*0.1 )-24.5 * (1.0+rand_r)),0.0) * vec3( rand_r, inv(rand_r), n ) * 0.15;
    vec3 DOTS2 = max(ceil(dots( angle - T*35.0, dist, 10.0, 0.3 + rand_r*0.2 )-16.4 * (2.0-rand_r)),0.0) * vec3( n, rand_r, inv(rand_r) ) * 0.15;
    vec3 DOTS3 = clamp( 1.0 * dots( angle + T * 45.0, dist, 15.0, 0.9 ), 0.0, 1.0) * vec3( 1.0, 1.0, 1.0 ) * 0.05;
    vec3 DOTS4 = clamp( 1.0 * dots( angle - T * 45.0, dist, 15.0, 0.82 ), 0.0, 1.0) * vec3( 1.0, 1.0, 1.0 ) * 0.025;
    vec3 RING = RING1 + RING2 + RING3 + RING4 + RING5 + BURST1 + DOTS1 + DOTS2 + RING6 + DOTS3 + DOTS4;
    
    float r = RING.r + max((1.0 - dist * 2.0),-0.5) + noise( vec2( dist * Gr * sin( noise(vec2( time * 8.0 * TIMESCALE, -time )) ), dist ) );;//floor(n*2.0) * a;
    float g = RING.g + max((1.0 - dist * 3.5),-1.5) + noise( vec2( dist * Gg * TIMESCALE * cos( noise(vec2( time * 12.0 * TIMESCALE, -time )) ), dist ) );;//ceil(n/3.0 - 0.1) - a;
    float b = RING.b + max((1.0 - dist * 2.5),-1.0) + noise( vec2( dist * Gb * tan( noise(vec2( time * 1.0 * TIMESCALE, -time )) ), dist ) );;//ceil(n/3.0 - 0.2) - a;
    
    vec3 boost = vec3( 1.3, 1.3 - slow_r * 0.3, 0.4 + slow_n * 0.3);    
       
    return vec4(r*boost.r,g*boost.g,b*boost.b,1.0) * mix(dist,1.0,0.7);
    
    float over = DOTS3.x + DOTS4.x;
    //glFragColor = vec4( DOTS3 + DOTS4, 1.0);//vec4(over,over,over,1.0);
    //glFragColor = blur( 
}
vec4 myoverlay( vec2 Coord )
{ 
    float shortside = min( resolution.x, resolution.y );
    float longside = max( resolution.x, resolution.y );
    
    vec2 uv = Coord.xy / vec2( shortside, shortside );
    
    uv.x = uv.x - (longside/shortside - 1.0) * 0.5;
    
       float dist = distance( vec2( 0.5, 0.5 ), uv );
    
    uv = vec2( uv.x - 0.5, uv.y - 0.5 );
    
    float angle = degrees( atan( uv.y / uv.x ) );
    
    float TIMESCALE = 0.3;
    float T = time * TIMESCALE * 2.0;
    
    float ar = noise( vec2( angle / 5.0, 1.0 ) );
    float ar2 = noise ( vec2( mod ( angle, 30.0 ) / 5.0, 1.0 ) );
    
    vec3 DOTS1 = max(ceil(dots( angle, dist + ar * ar2 * sin( T ) * 0.35, 10.0, 0.5) - 40.0 ), 0.0) * vec3(1.0,1.0,1.0);
    vec3 DOTS2 = max(ceil(dots( angle + 5.0, dist + ar * ar2 * sin( (T+uv.x) * 0.5 ) * 1.5 + 0.2, 10.0, 0.5) - 40.0 ), 0.0) * vec3(1.0,1.0,1.0);
    vec3 DOTS3 = max(ceil(dots( angle + 5.0, dist + ar * ar2 * cos( (T+uv.y) * 0.5 ) * 1.0 + 0.1, 5.0, 0.5) - 45.0 ), 0.0) * vec3(1.0,1.0,1.0);
   
    return vec4( DOTS1 + DOTS2 + DOTS3, 1.0 );
}

void main(void)
{
    float shortside = min( resolution.x, resolution.y );
    float longside = max( resolution.x, resolution.y );
    
    vec2 uv = gl_FragCoord.xy / vec2( shortside, shortside );
    
    uv.x = uv.x - (longside/shortside - 1.0) * 0.5;
    
       float dist = distance( vec2( 0.5, 0.5 ), uv );
    vec3 c = myoutput(gl_FragCoord.xy).rgb;
    if (gl_FragCoord.x < mouse.x)
    {
        glFragColor = vec4(c, 1.0);    
    } else {
        
        //declare stuff
        const int mSize = 11;
        const int kSize = (mSize-1)/2;
        float kernel[mSize];
        vec3 final_colour = vec3(0.0);
        
        //create the 1-D kernel
        float sigma = 0.75 + dist * 5.0;
        float Z = 0.0;
        for (int j = 0; j <= kSize; ++j)
        {
            kernel[kSize+j] = kernel[kSize-j] = normpdf(float(j), sigma);
        }
        
        //get the normalization factor (as the gaussian has been clamped)
        for (int j = 0; j < mSize; ++j)
        {
            Z += kernel[j];
        }
        
        //read out the texels
        for (int i=-kSize; i <= kSize; ++i)
        {
            for (int j=-kSize; j <= kSize; ++j)
            {
                final_colour += kernel[kSize+j]*kernel[kSize+i]*myoutput((gl_FragCoord.xy+vec2(float(i),float(j)))).rgb;
    
            }
        }
        
        
        glFragColor = vec4(final_colour/(Z*Z), 1.0);
        glFragColor.rgb += myoverlay( gl_FragCoord.xy ).rgb;
    }
}

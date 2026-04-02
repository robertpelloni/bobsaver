#version 420

// original https://www.shadertoy.com/view/4lt3R7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
A tentative of implementation of the old school effect rubber glenz.

The code is *NOT* optimized at all
It was coded as a proof of concept and a personal challenge (don't laugh).

I borrowed some code (thats the concept of shadertoy isnt'it ?) from:
Lighting stuff: https://www.shadertoy.com/view/MdGXWG by Shane
Original tentative of glenz: https://www.shadertoy.com/view/ldlSW2 by rix
rgb bars: I was unable to find the shader where i copied the code :(

Hold LMB to disable transparency

*/

vec3 cubevec;

// Sinus bars function
vec3 calcSine(vec2 uv, float frequency, float amplitude, float shift, float offset, vec3 color, float width, float exponent)
{
    float y = sin(time * frequency + shift + uv.x) * amplitude + offset;
    float d = distance(y, uv.y);
    float scale = smoothstep(width, 0.0, distance(y, uv.y));
    return color * scale;
}

// Render the bars calling 3 CalcSines() and adding rgb componants
vec3 Bars(vec2 f)
{
    vec2 uv = f / resolution.xy;
    vec3 color = vec3(0.0);
    color += calcSine(uv, 2.0, 0.25, 0.0, 0.5, vec3(0.0, 0.0, 1.0), 0.1, 3.0);
    color += calcSine(uv, 2.6, 0.15, 0.2, 0.5, vec3(0.0, 1.0, 0.0), 0.1, 1.0);
    color += calcSine(uv, 0.9, 0.35, 0.4, 0.5, vec3(1.0, 0.0, 0.0), 0.1, 1.0);
    return color;
}

// Classic iq twist function
vec3 Twist(vec3 p)
{
    float f = sin(time/3.)*1.45;
    float c = cos(f*p.y);
    float s = sin(f/2.*p.y);
    mat2  m = mat2(c,-s,s,c);
    return vec3(m*p.xz,p.y);
}

// The distance function which generate a rotating twisted rounded cube 
// and we save its pos into cubevec
float Cube( vec3 p )
{
    p=Twist(p);
    cubevec.x = sin(time);
    cubevec.y = cos(time);
    mat2 m = mat2( cubevec.y, -cubevec.x, cubevec.x, cubevec.y );
    p.xy *= m;p.xy *= m;p.yz *= m;p.zx *= m;p.zx *= m;p.zx *= m;
    cubevec = p;
    return length(max(abs(p)-vec3(0.4),0.0))-0.08;
}

float Face( vec2 uv )
{
        uv.y = mod( uv.y, 1.0 );
        return ( ( uv.y < uv.x ) != ( 1.0 - uv.y < uv.x ) ) ? 1.0 : 0.0;
}

//Classic iq normal
vec3 getNormal( in vec3 p )
{
    vec2 e = vec2(0.005, -0.005);
    return normalize(
        e.xyy * Cube(p + e.xyy) +
        e.yyx * Cube(p + e.yyx) +
        e.yxy * Cube(p + e.yxy) +
        e.xxx * Cube(p + e.xxx));
}

void main(void)
{
    float x = gl_FragCoord.x;
    float pat = time*5.0;
    float rep = 120.0;
    float Step = 1.0;
    float Distance = 0.0;
    float Near = -1.0;
    float Far = -1.0;
    vec3 lightPos = vec3(1.5, 0, 0);
    vec2 kp = gl_FragCoord.xy / resolution.xy;
    vec2 p = -1.0 + 2.0*kp;
    p.x *= resolution.x / resolution.y;
    vec4 m = vec4(0.0); //mouse*resolution.xy / resolution.xxxx;
    float od=0.0;

    // rainbow formula taken from a starfield shader i dont remember
    vec3 col2 = vec3(0.5 + 0.5 * sin(x/rep + 3.14 + pat), 0.5 + 0.5 * cos (x/rep + pat), 0.5 + 0.5 * sin (x/rep + pat));
    
    // ay is for opening the screen at the start of the shader
    float ay=max(0.1,0.5-time/6.);
    
    // Raymarching
    vec3 ro = vec3( 0.0, 0.0, 2.1 );
    vec3 rd = normalize( vec3( p, -2. ) );
    for( int i = 0; i < 256; i++ )
        {
            Step = Cube( ro + rd*Distance );
            Distance += Step*.5;

            if( Distance > 4.0 ) break;
            if( Step < 0.001 )
                {
                     Far = Face( cubevec.yx ) + Face( -cubevec.yx ) + Face( cubevec.xz ) + Face( -cubevec.xz ) + Face( cubevec.zy ) + Face( -cubevec.zy );
                    od=Distance;
                    if(m.z<=0.0) Distance += 0.05;
                    if( Near < 0.0 ) Near = Far;
                }
        }

    vec3 Color=Bars(gl_FragCoord.xy);
    if( Near > 0.0 )
        {
              // lighting stuff (by Shane)
            vec3 sp = ro + rd*od;
            vec3 ld = lightPos - sp;
            float lDist = max(length(ld), 0.001);
            ld /= lDist;
            float atten = 1./(1. + lDist*.2 + lDist*.1); 
            float ambience = 0.7;
            vec3 sn = getNormal( sp);
            float diff = min(0.3,max( dot(sn, ld), 0.0));
            float spec = pow(max( dot( reflect(-ld, sn), -rd ), 0.0 ), 32.);
            
            // Applying the lighting to color
            if(m.z<=0.) Color = Color/5. + mix( vec3( 0.2, 0.0, 1.0 ), vec3( 1.0, 1.0, 1.0 ), vec3( ( Near*0.45 + Far*Far*0.04 ) ) );
            else Color = mix( vec3( 0.2, 0.0, 1.0 ), vec3( 1.0, 1.0, 1.0 ), vec3( ( Near*0.45 + Far*Far*0.04 ) ) );
            Color = Color*(diff+ambience)+vec3(0.78,0.5,1.)*spec/1.5;
        }

    // The bottom and top purple zones
    if (kp.y > ay && kp.y < ay+0.006 || kp.y > (1.-ay) && kp.y < 1.-ay+0.006 ) Color = col2;
    if(kp.y<ay || kp.y>1.-ay+0.006) Color=vec3(0.20,0.17,0.35);

    // Presenting color to the screen
    glFragColor = vec4( Color, 1.0 );
}

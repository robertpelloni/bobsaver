#version 420

// original https://www.shadertoy.com/view/4tt3D2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int A1max = 512;
const int A2max = 16;
const float A12m = float(A1max-A2max);

const int B1max = 216;
const float fB1max = float(B1max);
const float MinMax = 4.0;

const float pi = 3.14159265358979323846;
const float two_pi = 6.28318530717958647693;

#define complexMultiply(a, b) vec2( a.x * b.x - a.y * b.y, (a.x+a.y)*(b.x+b.y) - a.x*b.x - a.y*b.y )
#define complexSquare( c ) vec2( c.x * c.x - c.y * c.y, c.x * c.y * 2.0 )
#define complexLength2( c ) (c.x*c.x+c.y*c.y)

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

bool trivialMandelbrot ( vec2 c ) {
    vec2 cr = c + vec2(-0.25, 0.0);

    float radius = length(cr);
    float angle = atan(cr.y, cr.x);

    if ( ((radius * 2.0) > (1.0-cos(angle))) || (length ( c + vec2(1.0,0.0) ) > 0.25) ) {
        return false;
    } else {
        return true;
    }
}

vec4 colorPoint ( vec2 xy, float t ) {
    vec4 ret;
    float tpt = two_pi * t;

    float Angle = tpt; // RECURSIVE 1 -1 -1 1 // * fmap [ flip % 4 ];
    float Acos = cos(Angle);
    float Asin = sin(Angle);
    vec2 Rotation = vec2( Acos, Asin );

    vec2 Ac = complexMultiply( xy, Rotation )
            // RECURSIVE * (exp((1.0-t) * log(4096.0)) / 4096.0)
            * (2.0 + cos(tpt * 3.0))
            ;

    vec2 Az = vec2(0.0,0.0);
    int Abailed = -1;

    if (!trivialMandelbrot(Ac)) {
        for (int Acount = 0; Acount < A1max ; Acount++) {
            Az = complexSquare(Az) + Ac;
            if ( length(Az) > 2.0 ) {
                Abailed = Acount;
                break;
            }
        }
    }

    if (Abailed == -1) {
        ret = vec4(0.0, 0.0, 0.0, 1.0);
        // RECURSIVE float darken = sqrt(0.5);
        // RECURSIVE ret = vec4(darken, darken, darken, 1.0)
        // RECURISVE     * colorPoint2( 8.0 * complexMultiply( xy, Rotation ), t );
    } else {
        // RECURSIVE brighten = if (flip == 0) then exp(ts * log(4)) else 1 end;
        Az = complexSquare(Az) + Ac;
        Abailed = Abailed + 1;

        if (Abailed >= A2max) {
            float stripe = 1.0 - (mod(float(Abailed),2.0) * 2.0);
            float hue = mod( ( 13.0 * tpt * stripe + atan(Az.y, Az.x)), two_pi) / two_pi;
             
            float value = log( float(Abailed-A2max) - (log(log(sqrt(complexLength2(Az)))) / log(2.0))) / log(A12m);
            float saturation = 1.0 - clamp(value + float(Abailed-A2max) / A12m, 0.0, 1.0);

            vec3 color = hsv2rgb( vec3( hue, saturation, value ) );
            ret = vec4( color.x, color.y, color.z, 1.0 );
            
        } else {
            float Adist = log( float(Abailed+2) - (log(log(sqrt(complexLength2(Az)))) / log(2.0))) / log(float(A2max));

            float Rfact = (sin(two_pi * mod(t*5.0,1.0)) + 1.0 ) / 2.0;
            float Rangle = -7.0 * tpt;
            
            vec2 Rzoom = vec2(cos(Rangle), sin (Rangle)) / mix(4.0,8.0,sqrt(1.0-Rfact));
            vec2 Rshift = vec2(mix(-1.0,-0.25,sqrt(Rfact)),0.0);

            Az = vec2(0,0);
            vec2 Bz, Bc;
            int Bbailed = -1;
            int Bmax = -1;

            for (int Acount = 0; Acount < A2max; Acount++) {
                Az = complexSquare(Az) + Ac;
                Bc = complexMultiply(Az, Rzoom) + Rshift;
                
                if (!trivialMandelbrot(Bc)) {
                    // float Wang = atan(Az.y, Az.x) + tpt;
                    //vec2 Bwarp = vec2( cos(Wang), sin(Wang) ) / 4.0;
                    // Bz = Bwarp;
                    Bz = vec2(0.0, 0.0);
                    Bmax = int(ceil( mix( fB1max, MinMax, sqrt( float(Acount)/float(A2max-1)) ) ));
            
                    for (int Bcount = 0; Bcount < B1max ; Bcount++) {
                        Bz = complexSquare(Bz) + Bc;
                        if ( length(Bz) > 2.0 ) {
                            Bbailed = Bcount;
                            break;
                        } else if (Bcount >= Bmax) {
                            break;
                        }
                    }
                }

                if (Bbailed != -1) {
                    Abailed = Acount;
                    break;
                }
            }
            
            float stripe = 1.0 - (mod(float(Bbailed), 3.0));// * 2.0);
            float hue = mod(11.0 * tpt + stripe * atan(Bz.y, Bz.x), two_pi) / two_pi;

            Bz = complexSquare(Bz) + Bc;
            float Bdist = log( float(Bbailed+2) - (log(log(sqrt(complexLength2(Bz)))) / log(2.0))) / log(float(Bmax));

            float saturation = 1.0 - sqrt(clamp(Bdist + Adist/2.0,0.0,1.0));
            float value = sqrt(clamp(sqrt(Bdist) - Adist/1.5,0.0,1.0));

            vec3 color = hsv2rgb( vec3( hue, saturation, value ) );
            ret = vec4( color.x, color.y, color.z, 1.0 );
        }
    }

    return ret;
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy - (resolution.xy * 0.5))
            / min( resolution.x, resolution.y );
    uv = uv * 4.0;
    glFragColor = colorPoint( vec2(-uv.y, uv.x), mod(time/60.0, 1.0) );
}

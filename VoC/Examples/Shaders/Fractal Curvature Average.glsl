#version 420

// original https://www.shadertoy.com/view/ldyfDD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define iteration_holder 300
#define escape_holder 100.0
float zoom = 7000.463345567321 ;
vec2 focusPoint = vec2(-0.3160639610412624, -0.6428171368132422);

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;

    float izoom = pow(1.001, zoom + 3000.0 * sin(time/3.0) );

    vec2 z = vec2(0.0);

    vec2 c = focusPoint + (uv * 4.0 - 2.0)  * 1.0 / izoom ;

    c.x *= resolution.x / resolution.y;

    vec2 p = z;

    float l;
    float sum = 0.0;
    float sum2 = 0.0;

    float sum3 = 0.0;
    float sum4 = 0.0;

    int skip = 0;

    float min_dist = 10000.0;
    for( int i=0; i<iteration_holder; i++ )
    {
        l++; 
        if( length(z)>escape_holder) break;
        p = z;
        vec2 t = vec2( z.x*z.x - z.y*z.y, 2.0*z.x*z.y );
        z = t + c;

        min_dist = min(min_dist, length(z-vec2(-0.8181290, -0.198848)));
        sum2 = sum;
        sum4 = sum3;
        if ((i>skip)&&(i!=00-1)) {

            float mp=length(t);
            float m = abs(mp  - length(c)  );
            float M = mp + length(c);

            float curve1 = 0.5 + 0.5 * sin(4.0 * atan(z.x, z.y));
            float curve2 = 0.5 + 0.5 * sin(5.0 * atan(z.x, z.y));
            sum += 1.0 * curve1;
            sum3 +=  1.0 * curve2;
        }

    }

    sum = sum / (l );
    sum2 = sum2 / (l - 1.0);

    
    
    
    l = l + 1.0 + 1.0/log(2.0) * log(log(100.0)/ log(sqrt(dot(z,z))));
    float d = l - floor(l);

    float r = sum * d + sum2 * (1.0 - d);

    float r2 =  sum3 * d + sum4 * (1.0 - d);

    r2 /= l ;
    r2 *= 10.0;

    float red = 0.5 + 0.5 * sin(r2 * 5.0);
    float green = 0.5 + 0.5 * sin(r2 * 1.0);
    float blue =  0.5 + 0.5 * sin(r * 3.0 * sqrt(l));
    
    red = smoothstep(0.3, 1.0, 1.0 -red);
    green = smoothstep(0.2, 1.0, green);

    if(l > (float(iteration_holder) - 1.0)){
         glFragColor = vec4(vec3(0.0), 1.0);
    }
    else{
         glFragColor = vec4(vec3(red,green,blue), 1.0);
    }

}

#version 420

// original https://www.shadertoy.com/view/XcSSDw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Fork of "volumetric DDA 2" by Elsio. https://shadertoy.com/view/MfBXDW
// 2024-01-27 18:06:20

#define Q(z) P((z), .2, 3., .3, 2., 0.)
#define P(z, a, b, c, d, e) vec3(sin(z * a) * b, cos(z * c) * d - e, z)
#define border(q, mask)                                          \
            vec3(.4 + smoothstep(.0, .1 / R.y,                  \
                          R.y / (.48 - dot(max(q.yzx, q.zxy), mask))))

bool glass;
float map(vec3 p){
    float 
        t1 = length(p - P(p.z, .2, 1., .3, 4., 1.)),   
        t2 = length(p - P(p.z, .3, 3., .2, 1., 1.)),
        ret = 
            1.5 - min(                                              
                      length(p - Q(p.z)),                           
                      min(t1, t2)
                  );
                  
    glass = t1 < t2;
    return ret;
}

#define r33(p) fract(sin(p * vec3(124,245.32,1234.343))*2234.3)
#define r31(p) fract(sin(dot(p, vec3(124,245.32,1234.343)))*2234.3)
//#define volCol(p) r33(p+1.) * cos(t + 6.3 * r31(p*.1)) * 3.
#define volCol(p) vec3(1.75, 0, 0) * cos(t + 6.3 * r31(p*.06)) * 1. + .6

vec3 hsb2rgb( in vec3 c )
{
    vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),
                             6.0)-3.0)-1.0,
                     0.0,
                     1.0 );
    rgb = rgb*rgb*(3.0-2.0*rgb);
    return (c.z * mix( vec3(1.0), rgb, c.y));
}

void main(void) {
    vec2 u = gl_FragCoord.xy;
    float t = 2. * time, res = .125, z;
    vec3 R = vec3(resolution.xy,1.0),
         norm, mask, side, p, q, border, volum = vec3(5,5,7) / 7., 
         ro = Q(t),
         fw = normalize(Q(t + 1.) - ro),
         rt = vec3(fw.z, 0, -fw.x),
         D = fw + mat2x3(rt, cross(fw, rt)) 
                    * (u - .5 * R.xy) / R.y / 1.2; // (!)
    
     vec2 mouse = vec2(1.0);
    
    
    ro /= res;
    p = floor(ro);
    side = (p - ro + .5) / D + .5 / abs(D);
    
    int i, far = 220;
    while (q = p * res, i++ < far){
        if(map(q) < mouse.x-mouse.y) {
            //if(r31(p*.3) < .1) {
            // altering x,y and z factors 
                volum *= hsb2rgb(vec3(q.x+(2.7*(p.x+p.y+p.z)/(p.z+p.y+0.1)*34.+p.z*34.0),0.9,1.)); //volCol(p);
            //}
            //else 
            break;
        }
        
        side += mask / abs(D);
        mask = step(side, side.yzx) * step(side, side.zxy);
        p += norm = mask * sign(D);
    }

    z = dot(side, mask);
    q = abs(fract(ro + z * D) - .5);
    
    const float blackEdgeWidthFactor = 1.085;
    glFragColor.rgb = ((volum)+   //0.35 brighten (and give color to black edges) //(glass?.5:-.5)
             0.35*( 12./ z))    // depth brightness
             *( 32./ z) // depth shadow
            *border(q, blackEdgeWidthFactor*mask) // black cube edges /face shadow
            ;
}

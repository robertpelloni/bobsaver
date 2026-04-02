#version 420

// original https://www.shadertoy.com/view/3lcSz7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int MAGIC_BOX_ITERS = 9;
const float MAGIC_BOX_MAGIC = 1.;

float magicBox(vec3 p) {
    // The fractal lives in a 1x1x1 box with mirrors on all sides.
    // Take p anywhere in space and calculate the corresponding position
    // inside the box, 0<(x,y,z)<1
    p = 1.0 - abs(1.0 - mod(p, 2.0));
    
    float lastLength = length(p);
    float tot = 0.0;
    // This is the fractal.  More iterations gives a more detailed
    // fractal at the expense of more computation.
    for (int i=0; i < MAGIC_BOX_ITERS; i++) {
      // The number subtracted here is a "magic" paremeter that
      // produces rather different fractals for different values.
      p = abs(p)/(lastLength*lastLength) - MAGIC_BOX_MAGIC;
      float newLength = length(p);
      tot += abs(newLength-lastLength);
      lastLength = newLength;
    }

    return tot;
}

// A random 3x3 unitary matrix, used to avoid artifacts from slicing the
// volume along the same axes as the fractal's bounding box.
const mat3 M = mat3(0.28862355854826727, 0.6997227302779844, 0.6535170557707412,
                    0.06997493955670424, 0.6653237235314099, -0.7432683571499161,
                    -0.9548821651308448, 0.26025457467376617, 0.14306504491456504);

vec3 rotateY(vec3 v, float t){
    float cost = cos(t); float sint = sin(t);
    return vec3(v.x * cost + v.z * sint, v.y, -v.x * sint + v.z * cost);
}

float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float noise(vec3 p){
    
    float t = time/3.;
    vec3 np = normalize(p);
    
    // kind of bi-planar mapping
    float a = 0.0; //texture(iChannel0,t/20.+np.xy).x;      
    float b = 0.0; //texture(iChannel0,t/20.+.77+np.yz).x;
    
    a = mix(a,.5,abs(np.x));
    b = mix(b,.5,abs(np.z));
    
    float noise = a+b-.4;    
    noise = mix(noise,.9,abs(np.y)/2.);
        
    return noise;
}

float map(vec3 p){
    
    // spheres
    float d = (-1.*length(p)+3.)+1.5*noise(p) + magicBox(p/2.1)/8. * 2.;    
    d = min(d, (length(p)-2.1) + noise(p) + magicBox(p)/9.)*.3;
    
    // links
    float m = 1.; float s = .0;    
//    d = smin(d, max( abs(p.x)-s, abs(p.y+p.z*.2)-.07 ) , m);          
//    d = smin(d, max( abs(p.z)-s, abs(p.x+p.y/2.)-.07 ), m );    
//    d = smin(d, max( abs(p.z-p.y*.4)-s, abs(p.x-p.y*.2)-.07 ), m );    
//    d = smin(d, max( abs(p.z*.2-p.y)-s, abs(p.x+p.z)-.07 ), m );    
//    d = smin(d, max( abs(p.z*-.2+p.y)-s, abs(-p.x+p.z)-.07 ), m );
    
    return d;
}

float color( vec3 p){
   return 0.; 
}

void main(void)
{    
    // Ray from UV
    vec2 uv = gl_FragCoord.xy * 2.0 / resolution.xy - 1.0;
    uv.x *= resolution.x / resolution.y;
    vec3 ray = normalize(vec3(1.*uv.x,1.*uv.y,1.));
    
    // Color    
    vec3 color = vec3(0);    
    const int rayCount = 1024;
    
    // Raymarching
    float t = 0.;
    for (int r = 1; r <= rayCount; r++)
    {
        // Ray Position
        vec3 p = vec3(0,0,-3.) + ray * t;        
        
        // Rotation 
        //p = rotateY(p, mouse*resolution.xy.x/resolution.x * 2.* 3.14);  
        p = rotateY(p,time/15.);
        
        // Deformation 
        float mask = max(0.,(1.-length(p/3.)));
        p = rotateY(p, mask*sin(time/10.)*.2);        
        p.y += sin(time+p.z*3.)*mask*.2;
        p *= 1.+(sin(time/2.)*mask*.1);

        // distance
        float d =  map(p);   
        
        //color
        if(d<0.01 || r == rayCount )
        {                 
            
            float iter = float(r) / float(rayCount);
            float ao = (1.-iter);
            ao*=ao;
            ao = 1.-ao;
                        
            float mask = max(0.,(1.-length(p/2.)));            
            mask *= abs(sin(time*-1.5+length(p)+p.x)-.2);            
            color += 2.*vec3(.1,1.,.8) * max(0.,(noise(p)*4.-2.6)) * mask;            
            color += vec3(.1,.5,.6) * ao * 6.;            
            color += vec3(.5,.1,.4)*(t/8.);
                       
            color *= 2.2 + (sin(time/3.)*.3 + .55);
            color -= 1.;
                        
            break;          
        }
        
        // march along ray
        t +=  d *.5;        
    }
    
    // vignetting effect by Ippokratis
    // https://www.shadertoy.com/view/lsKSWR
    uv = gl_FragCoord.xy / resolution.xy;
    uv *=  1.0 - uv.yx; 
    float vig = uv.x*uv.y * 20.0;    
    vig = pow(vig, 0.25);        
    color *= vig;
    
    //color adjustement
    color.y *= 1.1;
    color.x *= 2.4;
    
    glFragColor = vec4(color, 1);
}

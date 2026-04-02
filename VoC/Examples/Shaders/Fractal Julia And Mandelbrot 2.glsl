#version 420

// original https://www.shadertoy.com/view/3dVSRz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// https://www.mi.sanu.ac.rs/vismath/javier/b3.htm (COLORING ALGORITHMS)

const vec3 colorf = vec3(.3, .3, .7);
const vec3 colorf2 = vec3(.0, .0, .0);

vec3 hsv2rgb( float c )
{
    vec3 rgb = clamp( abs(mod(c*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );

    return rgb;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - resolution.xy * 0.5) / resolution.y; 
    vec2 mouse = mouse;
    mouse = (mouse == vec2(0.0) ? vec2(0.0) : (mouse*resolution.xy.xy - resolution.xy*0.5)/resolution.y);    //for initialization
    
    vec2 zoompoint = vec2(0.0);
    float zoom = .4;
    //zoom = 1.*(sin(time/1.) + 1.5);
    uv /= zoom;
    mouse /= zoom;
    uv += zoompoint;
    mouse += zoompoint;
    
//julia set 
    vec2 juliac = mouse;    
    vec2 z = uv;
    vec2 c = juliac;
    vec2 dz = vec2(0.0);
    float rz = 0.0;
    float rdz = 0.0;
    int nri = 0;
    
    for (int i = 0; i < 500; i++)
    {
        if(rz > 1024.0)
            break;
        
        // Z' -> 2*Z*Z' + 1
        dz = 2.0 * vec2(z.x * dz.x - z.y * dz.y, z.x * dz.y + z.y * dz.x) + vec2(1.0, 0.0);
        // Z -> Z^2 + c            
        z = vec2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;  
        nri = i;
        rz = dot(z, z);
    }
    
    //https://iquilezles.org/www/articles/distancefractals/distancefractals.htm
    rdz = dot(dz, dz);
    float d = 0.5*sqrt(rz / rdz) * log(rz);
    d = clamp(pow(6.0 * d / zoom, 0.2), 0.0, 1.0);
    
    //Change coloring method here
    vec3 color;
    if (rz < 4.0)
        color = vec3(0.0);
    else {
        float nic = float(nri) + 1. - log2(log2(rz));                    //normalized iteration count: https://iquilezles.org/www/articles/mset_smooth/mset_smooth.htm
        //color = hsv2rgb((nic * .015));                                //multicolored
        color = .5 + .5 * cos(3.0 + nic * .2 + vec3(0.0,0.6,1.0));    //like on wiki?
        //color = mix(colorf, colorf2, fract(float(nri) * .02));        //(discrete) escape time coloring: Base the color on the number of iterations
        //color = vec3(d);
    }

//mandelbrot set 
    vec3 color2;
    //if(mouse*resolution.xy.z > 0.0) {
        z = vec2(0.0);
        rz = 0.0;
        c = uv;

        for (int i = 0; i < 100; i++)
        {
            if(rz > 4.0)
                break;

            // Z -> Z^2 + c            
            z = vec2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
            rz = dot(z, z);
        }

        
        if (rz < 4.0)
            color2 = vec3(1.0);
        else
            color2 = vec3(0.0);

        color = mix(color, color2, 0.2);
    //}
    
    //red dot which is the julia parameter c
    color = mix(color, vec3(1.0,0.0,0.0), smoothstep(5.0 / zoom / resolution.y, 0.0, length(uv-juliac)));

    glFragColor = vec4(color, 1.0);
}

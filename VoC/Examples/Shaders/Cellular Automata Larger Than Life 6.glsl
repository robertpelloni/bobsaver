#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

//Fix for nexus 4/nexus 7 offset bug.
//#define texture2D(a,b) texture2D(a, b + 0.5/resolution)

//Smooth game of life like thing

//#define VIEW_KERNEL
//#define VIEW_LIFEFUNC

#define KERNEL_RADIUS 12
#define KERNEL_IN_SCALE 0.5

const float timestep = 0.2; //lower = more accurate/stable, higher = faster.

//Life function parameters.
float gw = 0.08 + 0.05*sin(time * 0.235432);
float gsl = 0.26 + 0.03*sin(time * 1.595784873);
float gel = 0.40 + 0.05*sin(time * 0.198542834);
float gsh = 0.70 + 0.1*sin(time * 0.74534345);
float geh = 0.95 + 0.04*sin(time * 0.205423454);
float mxs = 0.12 + 0.04*sin(time * 0.193734736);
float mxe = 0.60 + 0.06*sin(time * 0.4847373733);

//Get the cell value at the specifed position.
float getValue(vec2 uv)
{
    return texture2D(backbuffer, mod(uv / resolution, 1.0)).a;    
}

//Get the kernel shell to fill at the specified offset.
vec2 getKernel(vec2 off)
{
    float l = length(off);
    float ks = float(KERNEL_RADIUS);
    vec2 k = vec2(0);
    
    k.x = 1.0 - step(ks * KERNEL_IN_SCALE, l);
    k.y = (1.0 - step(ks, l)) - k.x;
    
    return k;
}

//Sums up the filling of each kernel shell and returns the fraction percentage of each.
vec2 sumKernel(vec2 uv)
{
    vec2 tf = vec2(0); //Total fill counted for each shell.
    vec2 mf = vec2(0); //Maximum possible filling.
    
    for(int i = -KERNEL_RADIUS;i <= KERNEL_RADIUS;i++)
    {
        for(int j = -KERNEL_RADIUS;j <= KERNEL_RADIUS;j++)
        {
            vec2 off = vec2(i,j);
            vec2 k = getKernel(off);
            
            if(i*i+j*j < KERNEL_RADIUS*KERNEL_RADIUS)
            {
                mf += k;
                tf += k * getValue(uv + off);    
            }
        }
    }
    
    return tf / mf;
}

//Determines how "alive" a pixel is based on the filling of the inner(x)/outer(y) shells.
float lifeFunction(vec2 nm)
{
    float gmix = smoothstep(mxs, mxe, nm.y);
    
    float gs = mix(gsl, gsh, gmix);
    float ge = mix(gel, geh, gmix);
    
    return smoothstep(gs - gw, gs + gw, nm.x) - smoothstep(ge - gw, ge + gw, nm.x);
}

void main( void ) 
{
    vec2 uv = gl_FragCoord.xy;

    float lastVal = getValue(uv);
    
    vec2 cell = sumKernel(uv);
    
    float value = timestep * (lifeFunction(cell) - lastVal) + lastVal;
    
    value += 1.0 - step(7.0, distance(uv, mouse * resolution));
    
    value *= step(0.1, length(mouse));
    
    glFragColor = vec4( vec3( value + cell.x, value + cell.y, value * 0.5), value );
    
}


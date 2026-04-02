#version 420

// original https://www.shadertoy.com/view/3sSyDG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float zoom = 4.;
const vec2 pan = vec2(0);

//ford circles fractal
float fordCircles(vec2 z){
    float s = 1.;
    
    for(int i=0;i<20;i++){

        z.x = mod(z.x, 2.);
        z.x -= 1.;
        z.x = -abs(z.x);
        z.x += 1.;

        float f= 0.5 * dot(z,z);
        z /= f;
        s /= f;
        
        z.xy = z.yx;
    }
    
    //draws the circumference of a circle and a line.
    //this piece is then warped using circle inversions and copied using modulo
    //to get the fractal.
    float d1 = abs(z.y-1.0);
    float d2 = abs(length(vec2(z.x-1.,z.y))-1.0);
    
    return min(d1,d2)/s;
}

vec2 scale(vec2 pixel){
    return zoom * (pixel - resolution.xy * 0.5)/resolution.y + pan;   
}

void main(void)
{
    vec2 z = scale(gl_FragCoord.xy);
    
    float e = 0.5*zoom/resolution.y;
    vec3 col = vec3(0);
    
    //draw ford cirles
    col += .1 * smoothstep(e*2., e, fordCircles(z));
    
    //midpoint and radius of final circle inversion
    
    vec2  m = vec2(cos(time*.3),sin(time*.3));
    float r = 1.;
    
    //if(mouse*resolution.xy.z>0.){
    //    m = scale(mouse*resolution.xy.zw);
    //    r = distance(scale(mouse*resolution.xy.xy),scale(mouse*resolution.xy.zw));
    //}

    //perform inversion
    float l = distance(m, z);
    float f = r*r / (l*l);
    z = m + (z-m) * f;
    
    //draw inversion circle
    col.g += .1*smoothstep(e*2., e, abs(l-r));

       //draw fractal
    col += smoothstep(e*2., e, fordCircles(z) / f);
    
    glFragColor = vec4(1. - col,1.0);
}

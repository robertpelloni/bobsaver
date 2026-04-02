#version 420

// original https://www.shadertoy.com/view/3s33W4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* 
    The Julia set is the subset of the complex plane given by the points 
    whose nth iteration of the function f_c (z) = z * z + c has a modulus 
    of at most two for all natural n.
*/

vec2 multiply(vec2 x,vec2 y){
    return vec2(x.x*y.x-x.y*y.y,x.x*y.y+x.y*y.x);
}
void main(void)
{
    vec2 z0 = 5.*(gl_FragCoord.xy/resolution.x-vec2(.5,.27));
    vec2 col;
    vec2 c = cos(time)*vec2(cos(time/2.),sin(time/2.)); 
    for(int i = 0; i < 500;i++){
        vec2 z = multiply(z0,z0)+c;
        float mq = dot(z,z);
        if( mq > 4.){
            col = vec2(float(i)/20.,0.);
            break;
        } else {
            z0 = z;
        }
        col =  vec2(mq/2.,mq/2.);
    }
    glFragColor = vec4(col,0.,1.);
}


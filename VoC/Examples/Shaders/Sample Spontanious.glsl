#version 420

// original https://www.shadertoy.com/view/cdVXDd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define n_tau 6.2831
void main(void)
{
    float n_its = 20.;

    float n_dmax = 0.;
    vec2 o_fc = (gl_FragCoord.xy - resolution.xy*.5) / resolution.y;
    for(float n_it = 0.; n_it < n_its; n_it+=1.){
        float n_it_nor = n_it / n_its;
        float n_radians = n_it_nor * n_tau;
        float n_speed = 4.;
        float n_corners = floor(mod(time*(1./(n_tau/n_speed)),9.));//3.;//floor(fract(time*0.1)*9.);
        float n_radius = 0.2+(sin(time*n_speed+n_it_nor*n_tau*n_corners+(n_tau/2.))*.5+.5)*0.2; 
        vec2 o_p = vec2(
            sin(n_radians)*n_radius, 
            cos(n_radians)*n_radius
        );

        vec2 o_diff = o_fc - o_p;
        float n_d_1 = length(
            o_diff*3.
        );

        float n_d_2 = (max(
            abs(o_diff.x), abs(o_diff.y)
        ))*0.5;
        float n_fact = sin(time*n_speed+n_it_nor*n_tau)*.5+.5;
        float n_d = 
        (1.-n_fact)* n_d_1 + 
        n_fact * n_d_2;
        
        // n_d = abs(n_d-(sin(time+n_it_nor)*0.5+.5)*0.2);
        n_d = abs(n_d-(1./n_its/2.));
        n_d = pow(n_d, 1./3.);
        n_d = n_d *2.;
        n_d = 1.- n_d;
        // n_d = n_d*2.;
        // n_d = abs(n_d-(sin(time)*.5+.5));
        // n_d = fract(n_d-sin(time)*0.5);

        if(n_d > n_dmax){
            n_dmax = n_d;
        }

    }
    glFragColor = vec4(n_dmax);

}
